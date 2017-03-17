this.globs = {}
globs = window.globs

class Lantern
  constructor: (options) ->
    {@x, @y, @alpha = 0} = options

  draw: () ->
    globs.ctx.globalAlpha = @alpha
    globs.ctx.drawImage(globs.lantern_blue, @x, @y)
    globs.ctx.globalAlpha = 1-@alpha
    globs.ctx.drawImage(globs.lantern_white, @x, @y)
    globs.ctx.globalAlpha = 1
  trigger: () ->
    if not @triggered
      @triggered = true
      window.setTimeout () =>
        @triggered = false
      , 2000
      this.fade_color()
  reset: () ->
    this.fade_white()

  fade_white: () ->
    @alpha -= 0.03
    if @alpha > 0
      window.setTimeout () =>
        this.fade_white()
      , 100
    else
      @alpha = 0

  fade_color: () ->
    @alpha += 0.1
    if @alpha < 1
      window.setTimeout () =>
        this.fade_color()
      , 100
    else
      @alpha = 1
      window.setTimeout () =>
        this.reset()
      , 5000
    

$(document).ready(() ->
  canvas = $('#canvas')[0]
  canvas.width = 1600
  canvas.height = 1200
  canvas.style.width = '800px'
  canvas.style.height = '600px'
  globs.ctx = canvas.getContext('2d')
  globs.ctx.scale(2,2)

  img = new Image()
  img.onload = () ->
    globs.ctx.drawImage(img, 0, 0)
  img.src = "background.svg"

  globs.lantern_white = new Image()
  globs.lantern_white.src = "lantern_white.svg"

  globs.lantern_blue = new Image()
  globs.lantern_blue.src = "lantern_blue.svg"
  globs.lantern_blue.onload = () ->
    frame()
    move_person()

  globs.bg = img

  globs.ctx.fillStyle = 'green'
) 

globs.i=0

#lanterns = [
#  new Lantern(x: 40, y: 400)
#  new Lantern(x: 140, y: 420)
#  new Lantern(x: 240, y: 440)
#]

lanterns = [
  new Lantern(x: 40, y: 280)
  new Lantern(x: 140, y: 250)
  new Lantern(x: 240, y: 280)
  new Lantern(x: 340, y: 250)
  new Lantern(x: 440, y: 280)
  new Lantern(x: 540, y: 250)
  new Lantern(x: 640, y: 280)
]

move_person = () ->
  globs.i += 1
  for lantern, i in lanterns
    if Math.abs(lantern.x - globs.i) < 10
      lantern.trigger()
  window.setTimeout(move_person, 50)

frame = () ->
  globs.ctx.drawImage(globs.bg, 0, 0)
  globs.ctx.fillRect(globs.i, 276, 10, 10)
  lantern.draw() for lantern in lanterns

  window.setTimeout(frame, 10)

