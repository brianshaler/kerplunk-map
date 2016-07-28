_ = require 'lodash'

defaults =
  content: 'dot'
  value: ''
  width: 20
  height: 30
  anchor:
    x: 10
    y: 30
  scale: window?.devicePixelRatio ? 1
  strokeColor: '#644'
  fillColor: '#c66'
  textColor: '#fff'

class Icon
  constructor: (options) ->
    options = _.extend {}, defaults, options
    for k, v of options
      @[k] = v
    @width *= @scale
    @height *= @scale
    @size = @width * 0.9
    @cx = @width / 2
    @cy = @width / 2

    @element = document.createElement 'canvas'
    @element.width = @width
    @element.height = @height
    @ctx = @element.getContext '2d'

  addTo: (domElement) ->
    @draw()
    domElement.appendChild @element

  remove: ->
    @element?.parentNode?.removeChild?(@element)

  draw: ->
    ctx = @ctx
    ctx.strokeStyle = @strokeColor
    ctx.fillStyle = @fillColor
    ctx.lineWidth = @scale * 1.5

    ctx.save()
    ctx.translate @cx, @cy
    ctx.beginPath()
    ctx.arc 0,
      0,
      @cx - @scale * 1,
      Math.PI * 0.25,
      Math.PI * 0.75,
      true
    ctx.lineTo 0, @height - @cy - @scale * 2
    ctx.closePath()
    ctx.fill()
    ctx.stroke()
    ctx.restore()

    if @content is 'dot'
      ctx.save()
      ctx.fillStyle = @strokeColor
      ctx.translate @cx, @cy
      ctx.beginPath()
      ctx.arc 0,
        0,
        @size * 0.15, # size of the dot
        0,
        Math.PI * 2,
        true
      ctx.closePath()
      ctx.fill()
      ctx.restore()
    else if @content is 'number'
      ctx.fillStyle = @textColor
      ctx.font = '32px arial'
      textSize = ctx.measureText String @value
      ctx.fillText @value,
        @cx - textSize.width / 2,
        @cy + 12
    else if @content is 'image'
      img = new Image()
      img.onload = ->
        aspectRatio = img.width / img.height
        imgw = @size
        imgh = @size
        imgw *= aspectRatio if aspectRatio > 1
        imgh /= aspectRatio if aspectRatio < 1
        ctx.save()
        ctx.translate @cx, @cy
        ctx.beginPath()
        ctx.arc 0,
          0,
          @cx - @scale * 2,
          0,
          Math.PI * 2,
          true
        ctx.closePath()
        ctx.clip()
        ctx.drawImage img,
          0,
          0,
          img.width,
          img.height,
          -imgw / 2,
          -imgh / 2,
          imgw,
          imgh
        ctx.restore()

      img.src = @value
      @

module.exports = Icon
