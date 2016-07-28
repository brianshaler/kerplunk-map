_ = require 'lodash'
React = require 'react'

if requirejs?
  requirejs [
    'mapbox'
    'mapbox-gl'
  ], (Mapbox, MapboxGL) ->
    'nothing'

{DOM} = React

module.exports = React.createFactory React.createClass
  render: ->
    ContentComponent = @props.getComponent @props.contentComponent

    DOM.div
      className: 'fixed'
      style:
        width: '100%'
        height: '100%'
    ,
      DOM.link
        rel: 'stylesheet'
        href: '/plugins/kerplunk-map/css/map.css'
        media: 'all'
      ContentComponent _.extend {}, @props,
        key: @props.currentUrl
        buildUrl: @buildUrl
