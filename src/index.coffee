Promise = require 'when'
request = require 'request'

module.exports = (System) ->

  {ip, ports} = System.getService 'tileserver'
  baseUrl = "http://#{ip}:#{ports['80/tcp']}"
  console.log 'kerplunk-map base url', baseUrl, ports

  map = (req, res, next) ->
    res.render 'map',
      longitude: parseFloat req.params.lng
      latitude: parseFloat req.params.lat
      zoom: parseFloat req.params.zoom
      theme: req.params.theme
      title: 'Map'
      layout: 'kerplunk-map:layout'

  proxy = (req, res, next) ->
    unless -1 < ['png', 'json', 'pbf'].indexOf req.params.format
      return next()

    url = baseUrl + req.originalUrl

    host = req.get 'host'
    referer = req.get 'referer'
    xForwardedFor = req.get 'X-Forwarded-For'
    protocol = req.protocol

    pattern = /(https?):\/\/([^\/]+)\//
    matchString = referer ? "#{protocol}://#{host}#{req.originalUrl}"
    matches = matchString.match pattern
    if matches?.length > 2
      protocol = matches[1] if matches?[1]
      host = matches[2] if matches?[2]
    if !referer and xForwardedFor
      protocol = 'https'

    publicBaseUrl = "#{protocol}://#{host}"

    console.log '> PROXY'
    console.log protocol, url
    console.log req.originalUrl, req.params.styleId

    headers = {}
    headers.Host = host

    opt =
      url: url
      method: 'GET'
      headers: headers

    console.log 'proxy options', opt

    if req.params.format == 'json'
      request opt, (err, httpResponse, body) ->
        if err
          console.log 'ERROR', err
          return next()
        unless body
          return next()
        if protocol == 'https'
          body = body.replace /\bhttp:\/\//g, 'https://'
        res.send body
    else
      request opt
      .pipe res

  globals:
    public:
      css:
        'kerplunk-location-calendar:history': [
          'kerplunk-bootstrap/css/bootstrap.css'
          'kerplunk-location-calendar/css/calendar.css'
        ]
        'kerplunk-location-calendar:calendar': 'kerplunk-location-calendar/css/calendar.css'
        'kerplunk-location-calendar:summary': 'kerplunk-location-calendar/css/calendar.css'
      requirejs:
        paths:
          mapbox: '/plugins/kerplunk-map/js/mapbox.js'
          'mapbox-gl': '/plugins/kerplunk-map/js/mapbox-gl.js'
      blog:
        embedComponent:
          'kerplunk-map:map':
            name: 'Map'
            description: "map"

  routes:
    admin:
      '/admin/map/test': 'map'
      '/admin/map/test/:zoom/:lng/:lat/:theme': 'map'
    public:
      '/map/test': 'map'
      '/map/:zoom/:lng/:lat/:theme': 'map'
      '/styles/:styleId': 'proxy'
      '/styles/:styleId/:image': 'proxy'
      '/data/:source': 'proxy'
      '/data/:source/:z/:x/:y': 'proxy'
      # '/data/:id/:image': 'proxy'
      '/fonts/:fontStack/:levels': 'proxy'

  handlers:
    map: map
    proxy: proxy
