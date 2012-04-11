define Shapes -> {
Shape: class Shape
  constructor: ->
    @style = { fill: [0,0,0,1] }

  setup: (@naub) ->
    @pos = @naub.pos
    @ctx = @naub.ctx
    @set_color_from_id @naub.color_id


  # utils
  color_to_rgba: (color, shift = 0) =>
    r = Math.round((color[0] + shift))
    g = Math.round((color[1] + shift))
    b = Math.round((color[2] + shift))
    a = color[3]
    "rgba(#{r},#{g},#{b},#{a})"

  # change color
  set_color_from_id:(id)->
    palette = Naubino.colors
    pick = palette[id]
    @style.fill = [pick[0],pick[1],pick[2], 1]
    # TODO automatically assume 1 if alpha is unset (pick[3])
    id

    
  # colors the shape randomly and returns color id for comparison
  random_color: ->
    r = Math.random()
    g = Math.random()
    b = Math.random()
    @style.fill = [r,g,b,1]
    return -1

Square: class Square extends Shape
  constructor: ->
    super()
    @rot = 0
  area: ->
    @width/2 * @width/2


  # actual painting routines
  render: (ctx,x,y) ->
    ctx.save()
    @width= @naub.size * 2

    @rot = @rot + 0.1
    ctx.translate( x, y)
    ctx.rotate @rot
     
    ctx.beginPath()
    ctx.rect(-@width/2,-@width/2,@width,@width)

    # shadow
    ctx.shadowColor = "#333"
    ctx.shadowBlur = 3
    ctx.shadowOffsetX = 1
    ctx.shadowOffsetY = 1

    ctx.fillStyle = @color_to_rgba(@style.fill)
    ctx.fill()
    ctx.closePath()

    ctx.restore()

  isHit:(x,y) ->
    @layer.ctx.beginPath()
    @layer.ctx.rect(@pos.x-@width/2,@pos.y-@width/2,@width,@width)
    @layer.ctx.closePath()
    @layer.ctx.isPointInPath(x,y)

Ball: class Ball extends Shape
  area: ->
    # TODO consolder the margin of each naub
    Math.PI * (@naub.size/2)*(@naub.size/2)

  # actual painting routines
  # !IMPORTANT: needs to recieve ctx, x and y directly because those could also point into a buffer
  render: (ctx, x = 42, y = x) ->
    ctx.save()
    size= @naub.size

    offset = 0
    ctx.translate( x, y)
     
    ctx.beginPath()
    ctx.arc(offset, offset, size, 0, Math.PI * 2, false)
    ctx.closePath()

    ## border
    #ctx.lineWidth = 2
    #ctx.stroke()

    if @focused
      # gradient
      gradient = ctx.createRadialGradient(offset, offset, size/3, offset, offset, size)
      gradient.addColorStop 0, @color_to_rgba(@style.fill, 80)
      gradient.addColorStop 1, @color_to_rgba(@style.fill, 50)
      ctx.fillStyle = gradient
    else
      ctx.fillStyle = @color_to_rgba(@style.fill)

    # shadow
    ctx.shadowColor = "#333"
    ctx.shadowBlur = 3
    ctx.shadowOffsetX = 1
    ctx.shadowOffsetY = 1

    ctx.fill()
    ctx.closePath()

    ctx.restore()

Clock: class Clock extends Shape
  constructor: ->
    super()
    @start = 0
  setup: (@naub) ->
    super(@naub)
    @naub.clock_progress = 0

  # actual painting routines
  # !IMPORTANT: needs to recieve ctx, x and y directly because those could also point into a buffer
  render: (ctx, x = 42, y = x) ->
    ctx.save()
    size= @naub.size - 5

    end = @naub.clock_progress * Math.PI/100

    offset = 0
    ctx.translate( x, y)
     
    ctx.beginPath()
    ctx.arc(offset, offset, size, @start, end, false)
    #ctx.closePath()

    ctx.fillStyle = @color_to_rgba ([255,255,255,0.5])
    #ctx.fill()

    ctx.strokeStyle = ctx.fillStyle
    ctx.lineWidth = size+3
    ctx.stroke()

    ctx.closePath()

    ctx.restore()

Frame: class Frame extends Shape
  # draws a frame around the buffered image for analysis
  # @param ctx [canvas.context] context of the target layer
  constructor: (@margin = 5) ->
    super()
  setup: (@naub) ->
    super(@naub)
    @frame = @margin + @naub.size*2

  render: (ctx, x = 42, y = x) ->
    x = x-@frame/2
    y = y-@frame/2

    ctx.save()
    ctx.beginPath()
    ctx.moveTo x, y
    ctx.lineTo x, @frame+y
    ctx.lineTo @frame+x, @frame+y
    ctx.lineTo @frame+x, y
    ctx.lineTo x, y
    ctx.stroke()
    ctx.closePath()
    ctx.restore()

FrameCircle: class FrameCircle extends Frame
  render: (ctx, x = 42, y = x) ->
    ctx.save()
    ctx.beginPath()
    ctx.arc(x, y, @frame/2, 0, Math.PI * 2, false)
    ctx.closePath()
    ctx.strokeStyle = ctx.fillStyle
    ctx.stroke()
    ctx.closePath()
    ctx.restore()


StringShape: class StringShape extends Shape
  constructor: (@string, @color = "black") ->
    super()

  render: (ctx, x,y) ->
    ctx.save()
    ctx.translate x,y
    ctx.fillStyle = @color
    ctx.textAlign = 'center'
    ctx.font= "#{@naub.size+4}px Helvetica"
    ctx.fillText(@string, 0, 6)
    ctx.restore()

NumberShape: class NumberShape extends StringShape
  constructor: ()->
    super("", "white")

  setup: (@naub)->
    super(@naub)
    @string = @naub.number

}