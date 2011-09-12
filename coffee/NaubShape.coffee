Naubino.NaubShape = class NaubShape

  constructor: (naub) ->
    @naub = naub
    @pos = naub.physics.pos
    @size = 14
    @frame = @size+5
    @style = { fill: [0,0,0,1] }
    @join_style = { fill: [0,0,0,1], width: 6 }
    @life_rendering = false # if true redraw on each frame

  draw: (ctx) ->
    if @naub.game.pre_render and not @life_rendering
      ctx.save()
      x = @pos.x-@frame
      y = @pos.y-@frame

      #@draw_frame(ctx)

      ctx.drawImage(@buffer, x, y)
      ctx.restore()
    else
      @render ctx, 0

  draw_frame: (ctx) ->
    x = @pos.x-@frame
    y = @pos.y-@frame

    ctx.beginPath()
    ctx.moveTo x, y
    ctx.lineTo x, @frame*2+y
    ctx.lineTo @frame*2+x, @frame*2+y
    ctx.lineTo @frame*2+x, y
    ctx.lineTo x, y
    ctx.stroke()
    ctx.closePath()
    
  pre_render: (ctx) ->
    @buffer = document.createElement('canvas')
    @buffer.width = @buffer.height = @frame*2
    b_ctx = @buffer.getContext('2d')
    @render b_ctx

  ## actual painting routines
  draw_join: (ctx, partner) ->
    pos = @pos
    pos2 = partner.physics.pos

    ctx.save()
    ctx.strokeStyle = @color_to_css @join_style.fill

    ctx.beginPath()
    ctx.moveTo pos.x, pos.y
    ctx.lineTo pos2.x, pos2.y
    ctx.lineWidth = @join_style.width
    #ctx.shadowColor = "#333"
    #ctx.shadowBlur = 5
    #ctx.shadowOffsetX = 2
    #ctx.shadowOffsetY = 2
    ctx.stroke()
    ctx.closePath()
    ctx.restore()

  destroy: (callback) ->
    @life_rendering = true
    shrink = =>
      @size *= 0.8
      @join_style.width *= 0.8
      @join_style.fill[3] *= 0.8
      if @size <= 0.1
        clearInterval @loop
        callback.call()

    @loop = setInterval shrink, 50



  ## utils
  color_to_css: (color,shift = 0) =>
    r = Math.round((color[0] + shift/10) * 255)
    g = Math.round((color[1] + shift/10) * 255)
    b = Math.round((color[2] + shift/10) * 255)
    a = color[3]
    "rgba(#{r},#{g},#{b},#{a})"

  ## colors the shape randomly and returns color id for comparison
  random_palette_color: ->
    palette = @naub.game.colors
    id = Math.round(Math.random() * (palette.length-1))
    pick = palette[id]
    @style.fill = [pick[0]/255,pick[1]/255,pick[2]/255, 1]# TODO automatically assume 1 if alpha is unset (pick[3])
    id
    
  ## colors the shape randomly and returns color id for comparison
  random_color: ->
    r = Math.random()
    g = Math.random()
    b = Math.random()
    @style.fill = [r,g,b,1]
    return -1
