this.globs = {}
globs = window.globs

class Lantern
  constructor: (options) ->
    {@ctx, @x, @y, @alpha = 0, @radius = 40} = options
    @update_gradient()

  draw: () ->
    @ctx.save()
    @ctx.translate(@x - @radius, @y - @radius)
    @ctx.fillStyle = @gradient
    @ctx.fillRect(0, 0, 100, 100)
    @ctx.restore()
  trigger: () ->
    if not @triggered
      @triggered = true
      window.setTimeout () =>
        @triggered = false
      , 2000
      this.fade_color()

  reset: () ->
    this.fade_white()

  update_gradient: () ->
    @gradient = @ctx.createRadialGradient(50, 50, @radius, 50, 50, 0)
    @gradient.addColorStop(0, 'rgba(' + Math.round((1-@alpha) * 255) + ', ' + Math.round((1-@alpha) * 255) + ', 255, 0)')
    @gradient.addColorStop(1, 'rgba(' + Math.round((1-@alpha) * 255) + ', ' + Math.round((1-@alpha) * 255) + ', 255, 0.50)')

  fade_white: () ->
    @alpha -= 0.003
    this.update_gradient()
    if @alpha > 0
      window.setTimeout () =>
        this.fade_white()
      , 10
    else
      @alpha = 0

  fade_color: () ->
    @alpha += 0.01
    this.update_gradient()
    if @alpha < 1
      window.setTimeout () =>
        this.fade_color()
      , 10
    else
      @alpha = 1
      window.setTimeout () =>
        this.reset()
      , 5000

lantern_pos = [
  [40, 280]
  [140, 250]
  [240, 280]
  [340, 250]
  [440, 280]
  [540, 250]
  [640, 280]
]

lanterns = []

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

  globs.bg = img

  for pos in lantern_pos
    lanterns.push(new Lantern(ctx: globs.ctx, x: pos[0], y: pos[1]))

  frame()
)

globs.i=0

window.onmousemove = (event) ->
  globs.i = event.clientX

move_person = () ->
  globs.i += 1
  window.setTimeout(move_person, 50)

frame = () ->
  globs.ctx.drawImage(globs.bg, 0, 0)
  globs.ctx.fillRect(globs.i, 276, 10, 10)
  lantern.draw() for lantern in lanterns

  for lantern, i in lanterns
    if Math.abs(lantern.x - globs.i) < 10
      lantern.trigger()
  window.setTimeout(frame, 10)

