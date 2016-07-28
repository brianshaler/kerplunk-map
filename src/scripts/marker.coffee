if window? # note: window is undefined in workers
  mapbox = require 'mapbox'
  mapboxgl = require 'mapbox-gl'

Icon = require './icon'

LngLat = mapboxgl?.LngLat

module.exports = class Marker
  constructor: (options = {}) ->
    @data = _.clone options
    @element = options.element
    options.width = 20 unless options.width > 0
    options.height = 30 unless options.height > 0
    if !@element
      width = options.width
      height = options.height
      icon = new Icon
        width: width
        height: height
      el = document.createElement 'div'
      el.style.width = width
      el.style.height = height
      anchor = document.createElement 'a'
      anchor.href = '#'
      anchor.addEventListener 'click', (e) ->
        e.preventDefault()
        false
      icon.addTo anchor
      el.appendChild anchor
      options.width = width
      options.height = height
      @element = el
    @element.style.position = 'absolute'
    @element.classList.add 'mapboxgl-marker'
    @offset = options.offset ? [options.width / 2, options.height]
    if !options.lnglat and options.lng
      options.lnglat = LngLat.convert [options.lng, options.lat]
    @lnglat = LngLat.convert options.lnglat ? [0, 0]
    @setLngLat @lnglat
    @on 'click', (e) ->
      console.log 'clicked!'

  on: (eventName, handler) ->
    @element.addEventListener eventName, handler

  addTo: (map) ->
    @remove()
    @map = map
    @map.getCanvasContainer().appendChild @element
    @map.on 'move', @update
    @update()
    @

  remove: ->
    if @map
      @map.off 'move', @update
      @map = null
    @element?.parentNode?.removeChild?(@element)
    @

  setLngLat: (lnglat) ->
    @lnglat = LngLat.convert lnglat
    @update()
    @

  update: =>
    return @ unless @map
    {x, y} = @map.project(@lnglat) #._add @offset
    x -= @offset[0]
    y -= @offset[1]
    @element.style.transform = "translate(#{x}px, #{y}px)"
    @
