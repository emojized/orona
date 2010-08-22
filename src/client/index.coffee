###
Orona, © 2010 Stéphan Kochen

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.
###

{round, cos, sin, PI} = Math
Simulation            = require '..'
map                   = require '../map'
{TILE_SIZE_PIXEL,
 PIXEL_SIZE_WORLD,
 TICK_LENGTH_MS}      = require '../constants'
{decodeBase64}        = require './util'
Offscreen2dRenderer   = require './renderer/offscreen_2d'


# Global variables.

# The tilemap Image object.
tilemap = null
# The jQuery object referring to the HUD.
hud = null
# The game state object.
game = null
# The renderer instance to use.
renderer = null
# The WebSocket connection.
ws = null


init = ->
  # First, make sure the tilemap is loaded.
  unless tilemap?
    tilemap = new Image()
    $(tilemap).load(init)
    # FIXME: Handle errors
    tilemap.src = 'img/tiles2x.png'
    return

  # Initialize all the basics.
  hud = $('<div/>').appendTo('body')
  $(document).keydown(handleKeydown).keyup(handleKeyup)

  # Connect and wait for the map.
  ws = new WebSocket("ws://#{location.host}/demo")
  ws.onmessage = (event) ->
    # Load the map we just received.
    gameMap = map.load decodeBase64(event.data)

    # Initialize the game state.
    game = new Simulation(gameMap)
    renderer = new Offscreen2dRenderer(tilemap, game.map)
    game.map.setView(renderer)
    game.player = game.addTank()

    # Initialize the HUD.
    initHud()

    # Start the game loop.
    start()


# Event handlers.

handleKeydown = (e) ->
  return unless game?
  switch e.which
    when 32 then game.player.shooting = yes
    when 37 then game.player.turningCounterClockwise = yes
    when 38 then game.player.accelerating = yes
    when 39 then game.player.turningClockwise = yes
    when 40 then game.player.braking = yes
    else return
  e.preventDefault()

handleKeyup = (e) ->
  return unless game?
  switch e.which
    when 32 then game.player.shooting = no
    when 37 then game.player.turningCounterClockwise = no
    when 38 then game.player.accelerating = no
    when 39 then game.player.turningClockwise = no
    when 40 then game.player.braking = no
    else return
  e.preventDefault()


# Game loop.

gameTimer = null
lastTick = null

start = ->
  return if gameTimer?

  game.tick()
  lastTick = Date.now()

  gameTimer = window.setInterval(timerCallback, TICK_LENGTH_MS)

stop = ->
  return unless gameTimer?

  window.clearInterval(gameTimer)

  gameTimer = null
  lastTick = null

timerCallback = ->
  now = Date.now()
  while now - lastTick >= TICK_LENGTH_MS
    game.tick()
    lastTick += TICK_LENGTH_MS
  draw()


# Graphics.

draw = ->
  renderer.centerOnObject game.player, (left, top, width, height) ->
    # Draw all canvas elements.
    renderer.drawMap(left, top, width, height)
    drawTank(game.player)
    drawOverlay()

  # Update all DOM HUD elements.
  updateHud()

drawTank = (tank) ->
  tile = tank.getTile()
  x = round(tank.x / PIXEL_SIZE_WORLD) - TILE_SIZE_PIXEL / 2
  y = round(tank.y / PIXEL_SIZE_WORLD) - TILE_SIZE_PIXEL / 2

  renderer.drawTile tile[0], tile[1], x, y

drawOverlay = ->
  # FIXME: variable firing distance
  # FIXME: hide when dead
  distance = 7 * TILE_SIZE_PIXEL
  rad = (256 - game.player.direction) * 2 * PI / 256
  x = round(game.player.x / PIXEL_SIZE_WORLD + cos(rad) * distance) - TILE_SIZE_PIXEL / 2
  y = round(game.player.y / PIXEL_SIZE_WORLD + sin(rad) * distance) - TILE_SIZE_PIXEL / 2

  renderer.drawTile 17, 4, x, y

initHud = ->
  # Clear all existing contents
  hud.html('')

  # Create the pillbox status indicator.
  container = $('<div/>', id: 'pillStatus').appendTo(hud)
  $('<div/>', class: 'deco').appendTo(container)
  $('<div/>', class: 'pill').appendTo(container).data('pill', pill) for pill in game.map.pills

  # Create the base status indicator.
  container = $('<div/>', id: 'baseStatus').appendTo(hud)
  $('<div/>', class: 'deco').appendTo(container)
  $('<div/>', class: 'base').appendTo(container).data('base', base) for base in game.map.bases

  # Show WIP notice. This is really a temporary hack, so FIXME someday.
  unless location.hostname in ['localhost', '127.0.0.1']
    $('<div/>').text('This is a work-in-progress; less than alpha quality!').css(
      'position': 'absolute', 'top': '8px', 'left': '0px', 'width': '100%', 'text-align': 'center',
      'font-family': 'monospace', 'font-size': '16px', 'font-weight': 'bold', 'color': 'white'
    ).appendTo(hud);
    $('<a href="http://github.com/stephank/orona"></a>')
      .css('position': 'absolute', 'top': '0px', 'right': '0px')
      .html('<img src="http://s3.amazonaws.com/github/ribbons/forkme_right_darkblue_121621.png" alt="Fork me on GitHub">')
      .appendTo(hud);

  # One-shot update to set all the real-time attributes.
  updateHud()

updateHud = ->
  # Pillboxes.
  $('#pillStatus .pill').each (i, node) =>
    # FIXME: allegiance
    $(node).attr('status', 'neutral')

  # Bases.
  $('#baseStatus .base').each (i, node) =>
    # FIXME: allegiance
    $(node).attr('status', 'neutral')


# Exports.
exports.init = init
exports.start = start
exports.stop = stop