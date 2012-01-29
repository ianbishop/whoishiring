# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ->
  GMap4Rails.callback ->
    if Gmaps4Rails.markers.length == 1
      Gmaps4Rails.map.setZoom(2)
    else
      Gmaps4Rails.map_options.auto_zoom = true
      Gmaps4Rails.adjust_map_to_bounds()
