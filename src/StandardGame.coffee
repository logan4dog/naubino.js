# TODO LEVEL UP
#   number of colors
#   number of naubs per spam
#   speed up
#
# @extends Game
define ["Game"], (Game) -> class StandardGame extends Game
  constructor: (canvas) ->
    super(canvas)
    @version = 2 # please raise when makeing changes to this file

  calculate_points: (list) ->
    @ex_naubs += list.length
    max_grow = 3 # may be moved to settings some day
    factor = (max_grow-1) / @max_naubs
    p = Math.floor(factor * list.length * list.length)
    @points += p
    Naubino.overlay.fade_in_and_out_message ("\n\nChain Bonus "+p) if p > 0
    # Newlines prevent Level + Bonus messages overlapping


  level_details: [
    { limit:-1,    number_of_colors: 3, interval: 40, max_naubs: 20 } # initial state
    { limit:20,    number_of_colors: 3, interval: 38, max_naubs: 20, probabilities:{ pair:1, mixed_1:0, mixed_2:0, triple: 0 }  } #1
    { limit:50,    number_of_colors: 3, interval: 36, max_naubs: 25, probabilities:{ pair:9, mixed_1:0, mixed_2:0, triple: 2 }  } #2
    { limit:80,    number_of_colors: 4, interval: 30, max_naubs: 30, probabilities:{ pair:9, mixed_1:0, mixed_2:0, triple: 1 }  } #3
    { limit:120,   number_of_colors: 4, interval: 25, max_naubs: 35, probabilities:{ pair:8, mixed_1:1, mixed_2:0, triple: 1 }  } #4
    { limit:150,   number_of_colors: 5, interval: 25, max_naubs: 40, probabilities:{ pair:7, mixed_1:2, mixed_2:0, triple: 1 }  } #5
    { limit:180,   number_of_colors: 5, interval: 29, max_naubs: 43, probabilities:{ pair:6, mixed_1:3, mixed_2:0, triple: 1 }  } #6
    { limit:210,   number_of_colors: 6, interval: 30, max_naubs: 45, probabilities:{ pair:5, mixed_1:3, mixed_2:1, triple: 1 }  } #7
    { limit:240,   number_of_colors: 6, interval: 33, max_naubs: 47, probabilities:{ pair:4, mixed_1:4, mixed_2:1, triple: 1 }  } #8
    { limit:270,   number_of_colors: 7, interval: 36, max_naubs: 49, probabilities:{ pair:3, mixed_1:4, mixed_2:2, triple: 1 }  } #9
    { limit:30000, number_of_colors: 7, interval: 30, max_naubs: 50, probabilities:{ pair:3, mixed_1:3, mixed_2:3, triple: 1 } } #10
  ]

  load_level: (level) ->
    if @level_details.length >= level
      @load_level 0 if 0 < level < @level

      @level = level
      name = "Level #{@level}"
      Naubino.overlay.fade_in_and_out_message name unless level < 1
      Naubino.menu.for_each (naub)->naub.set_random_palette_color() unless level < 2

      set = @level_details[@level]

      #@basket_size      = set['basket_size']      ? @basket_size
      @max_naubs      = set['max_naubs']      ? @max_naubs
      @number_of_colors = set['number_of_colors'] ? @number_of_colors
      @spammer_interval = set['interval']         ? @spammer_interval

      #console.log "limit"            , set['limit']
      #console.log "basket size"      , @basket_size
      #console.log "number of colors" , @number_of_colors
      #console.log "spammerinterval"  , @spammer_interval

      for name, probability of set['probabilities']
        #console.log name
        @spammers[name].probability = probability

  max_color: -> Math.floor(Math.random() * (@number_of_colors))

  ### state machine ###
  oninit: ->
    super()
    @naub_replaced.add   (number) => @graph.cycle_test(number)
    @naub_destroyed.add  (id)     => @points += @get_object(id).points_on_destroy()
    @cycle_found.add     (list)   => @destroy_naubs(list)
    @cycle_found.add     (list)   => @calculate_points(list)
    @naub_focused.add    (n)      => @active_tree = @graph.tree n.number
    
    #Naubino.audio.connect_to_game this
    @number_of_colors = @default_number_of_colors = 3
    #@basket_size      = @default_basket_size      = 160

    @spammers = {
      pair:
        method: => @factory.create_naub_pair(null, @max_color(), @max_color() )
        probability: 5
      mixed_1:
        method: => @factory.create_naub_pair(null, @max_color(), @max_color(), 1 )
        probability: 0
      mixed_2:
        method: => @factory.create_naub_pair(null, @max_color(), @max_color(), 2 )
        probability: 0
      triple:
        method: => @factory.create_naub_triple(null, @max_color(), @max_color(), @max_color() )
        probability: 0
    }

    @inner_clock = 0 # to avoid resetting timer after pause
    @points = 0
    @ex_naubs = 0
    @naubs_count = 0
    @load_level 0

  onplaying: ->
    @spamming = setInterval @event, 100 unless @spamming
    @checking = setInterval @check, 300 unless @checking
    Naubino.overlay.set_osd { text:'level0', pos:{x:10,y:@height}, fontsize:8, align:'', life:true, color:'gray' } unless @OSD?

  onleaveplaying: ->
    clearInterval @spamming
    clearInterval @checking
    @spamming = @checking = null
    #Naubino.background.stop_stepper()

  onbeforestop: (e,f,t, override) ->
    if Naubino.override or override
      #console.log "killed"
      delete Naubino.override
      return true
    else
      confirm "Do you realy want to stop the game?"


  #maps spammers to their probabilities
  map_spammers: ->
    sum = 0
    for name, spammer of @spammers
      sum += spammer.probability
      {range:sum,  name, method:spammer.method}

  #picks a random spammer according to its probability
  spam: ->
    probabilities = for name, spam of @spammers
      spam.probability
    max = probabilities.reduce (f,s) -> f+s
    dart = Math.floor(Math.random() * max)
    for spammer in @map_spammers()
      if dart < spammer.range
        # console.log spammer.name
        spammer.method()
        return

  # recurring check (@checking)
  check: =>

    @duration = Date.now() - @begin_time
    Naubino.set_score()

    capacity = @capacity()
    critical_capacity = 45

    # start warning 
    if capacity < critical_capacity
      if Naubino.background.pulsating == off
        Naubino.background.pulse()
      Naubino.background.ttl = Math.floor capacity/2

      Naubino.background.pulse_speed = Util.interpolate(3,25,(critical_capacity-capacity)/critical_capacity)


    else if Naubino.background.pulsating == on
      Naubino.background.stop_pulse()
      Naubino.background.ttl = critical_capacity

    @loose() if @capacity() < 5

    @load_level(@level+1) if @level_details[@level].limit < @ex_naubs
    Naubino.overlay.set_osd "| level: #{@level} | points: #{@points} | destroyed naubs: #{@ex_naubs} | capacity:#{Math.round(@capacity())}% |"

  # recurring event (@spamming)
  event: =>
    @spam() if @inner_clock == 0
    @inner_clock = (@inner_clock + 1) % @spammer_interval
    @spammer_interval



