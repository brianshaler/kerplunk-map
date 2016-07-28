_ = require 'lodash'
React = require 'react'

Marker = require '../scripts/marker'

{DOM} = React

module.exports = React.createFactory React.createClass
  getInitialState: ->
    theme: @props.theme ? 'purple'
    zoom: @props.zoom ? 5
    latitude: @props.latitude ? 1
    longitude: @props.longitude ? 1
    markers: @props.markers ? []

  componentWillReceiveProps: (props) ->
    # console.log 'received new props', props
    compare = (a, b) ->
      if typeof a is 'number' or typeof a is 'string'
        return a == b
      _.isEqual a, b

    diff = {}
    changed = false
    for k, v of @state
      # console.log 'check', k, v, props[k]
      if props[k]? and !compare props[k], v
        diff[k] = props[k]
        changed = true
    if changed
      # console.log 'changes', diff
      newState = _.extend {}, @state, diff
      if diff.theme
        @destroyMap()
        @setupMap newState
      else unless diff.markers?.length > 0
        @updateMap newState
      if diff.markers
        @updateMarkers newState
      @setState diff

  destroyMap: ->
    @map.off 'dragend', @onDragEnd
    @map.off 'moveend', @onMoveEnd
    @map.off 'zoomend', @onZoomEnd
    @map.remove()

  setupMap: (state = @state) ->
    return unless @isMounted() and @mapboxgl
    mapContainer = @refs.mapContainer.getDOMNode()
    # console.log 'do stuff with the map', mapContainer
    q = (location.search ? '').substr(1).split('&')
    preference = if q.indexOf('vector') >= 0
      'vector'
    else if q.indexOf('raster') >= 0
      'raster'
    else if @mapboxgl.supported()
      'vector'
    else
      'raster'

    center = [state.longitude, state.latitude]
    # console.log 'center', center

    if preference == 'vector'
      @map = new @mapboxgl.Map
        container: mapContainer
        style: "/styles/#{state.theme}.json"
        center: center
        zoom: state.zoom
        # hash: true
      # console.log 'addControl'
      @map.addControl new @mapboxgl.Navigation()
    else
      @map = L.mapbox.map mapContainer,
        '/styles/purple/rendered.json',
        zoomControl: false
        zoom: state.zoom
        center: center
      new L.Control.Zoom
        position: 'topright'
      .addTo @map
      setTimeout ->
        new L.Hash @map
      , 0
    # console.log 'setting up map drag/move/zoom events'
    @updateMarkers state

    @map.on 'dragend', @onDragEnd
    @map.on 'moveend', @onMoveEnd
    @map.on 'zoomend', @onZoomEnd

  updateMap: (state = @state) ->
    # console.log 'updateMap', state
    center = [state.longitude, state.latitude]
    # console.log 'center', center
    # console.log 'zoom', state.zoom
    @map.flyTo
      zoom: state.zoom
      center: center

  updateMarkers: (state = @state) ->
    return unless @map
    # console.log 'updateMarkers', state.markers
    {markers} = state
    @markers = [] unless @markers?
    unless markers?.length > 0
      for marker in @markers
        marker.remove()
        @markers.splice 0, @markers.length
      return

    if @markers.length > 0
      for i in [(@markers.length - 1)..0]
        marker = @markers[i]
        continue unless marker?
        found = _.find markers, (obj) ->
          _.isEqual marker.data, obj
        if !found
          marker.remove()
          @markers.splice i, 1

    for obj in markers
      found = _.find @markers, (m) ->
        _.isEqual m.data, obj
      continue if found
      marker = new Marker obj
        # .setLngLat [obj.lng, obj.lat]
        .addTo @map
      @markers.push marker

    return unless @markers.length > 0

    lngs = _.map @markers, (m) -> m.lnglat.lng
    lats = _.map @markers, (m) -> m.lnglat.lat

    left = _.min lngs
    right = _.max lngs
    top = _.max lats
    bottom = _.min lats

    bounds = @mapboxgl.LngLatBounds.convert [[left, bottom], [right, top]]
    # console.log 'fitBounds', left, top, right, bottom
    @map.fitBounds bounds,
      padding: 50

    @updateStateFromMap()

  componentDidMount: ->
    requirejs [
      'mapbox'
      'mapbox-gl'
    ], (@Mapbox, @mapboxgl) =>
      @setupMap()

  componentWillUnmount: ->
    @destroyMap()

  updateStateFromMap: ->
    zoom = @map.getZoom()
    center = @map.getCenter()
    # console.log 'update state', zoom, center
    @setState
      zoom: zoom
      latitude: center.lat
      longitude: center.lng
    if @props.onChange
      @props.onChange
        zoom: zoom
        latitude: center.lat
        longitude: center.lng

  onDragEnd: (e) ->
    # console.log 'onDragEnd'
    @updateStateFromMap()

  onMoveEnd: (e) ->
    # console.log 'onMoveEnd'
    @updateStateFromMap()

  onZoomEnd: (e) ->
    # console.log 'onZoomEnd'
    @updateStateFromMap()

  render: ->
    DOM.div
      style:
        width: @props.width ? '100%'
        height: @props.height ? '100%'
    ,
      DOM.link
        rel: 'stylesheet'
        href: '/plugins/kerplunk-map/css/mapbox-gl.css'
        media: 'all'
      DOM.link
        rel: 'stylesheet'
        href: '/plugins/kerplunk-map/css/mapbox.css'
        media: 'all'
      DOM.div
        ref: 'mapContainer'
        style:
          width: '100%'
          height: '100%'
