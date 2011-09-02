# controlls everything that has to do with logic and gameplay or menus
class Game

  
  ## get this started 
  constructor: (@canvas, @keybindings) ->
    # TODO Exchangeable display class
    @time_factor = 1
    @paused = true

    @world = new World this
    @graph = new Graph
    @focused_naub = null

    @context = @canvas.getContext('2d')

  create_some_naubs: (n = 3) ->
    for [0..n]
      @create_naub_pair()

  create_naub_pair: ->
      naub_a = new Naub this
      naub_b = new Naub this
      naub_c = new Naub this
      naub_a.shape.style.fill = naub_a.shape.random_color()
      naub_b.shape.style.fill = naub_b.shape.random_color()
      naub_c.shape.style.fill = naub_b.shape.random_color()

      x = Math.random() * 600
      y = Math.random() * 400

      naub_a.physics.pos.Set x, y
      naub_b.physics.pos.Set x + 30, y + 30
      naub_c.physics.pos.Set x + 60, y - 30

      naub_a.physics.vel.Set 0, 0
      naub_b.physics.vel.Set 0, 0
      naub_a.joinWith naub_b
      naub_a.joinWith naub_c




  ## temus fugit
  start_timer: ->
    if @paused
      @loop = setInterval(@mainloop, 0.05*1e3)
      @paused = false

  stop_timer: ->
    clearInterval @loop
    @paused = true

  step: (dt) ->
    @world.step dt

  mainloop: ()=>
    dt = 0.02
    @step(dt)
    @keybindings.step(dt)
    @draw(@context)





  ## can I touch this?
  click: (x, y) ->
    @mousedown = true
    naub = @getNaub x, y
    if naub
      console.log naub.number + " -> " + naub.joineds()
      naub.focused = true
      @focused_naub = naub

  unfocus: ->
    @mousedown = false
    if @focused_naub
      @focused_naub.focused = false
    @focused_naub = null

  movePointer: (x,y) ->
    if @mousedown
      [@world.pointer.x, @world.pointer.y] = [x,y]

  getNaub: (x, y) ->
    for naub in @world.objs
      if naub.isHit(x, y)
        return naub



  ## paint it naubino
  draw: (context) ->
    context.clearRect(0, 0, @canvas.width, @canvas.height)
    context.save()
    @world.draw context
    context.restore()

