this.globs = {}
globs = window.globs

class Animation
  constructor: (options) ->
    {@pattern, @on_update, @on_done = () -> return } = options

  total_time: () ->
    total = 0
    for seq in @pattern
      total += seq[1]
    return total

  start: () ->
    @start_time = performance.now()

  tick: (time) ->
    return if not @start_time?
    value = @value_at time
    @on_update value if value?

  value_at: (time) ->
    return null if not @start_time?
    total = 0
    prev_seq = null
    rel_time = time - @start_time
    if rel_time < 0
      return null
    for seq in @pattern
      if prev_seq? and total < rel_time <= (total + seq[1])
        return @lerp prev_seq[0], seq[0], ((rel_time - total) / seq[1])
      total += seq[1]
      prev_seq = seq
    @on_done()
    @start_time = null
    return prev_seq[0]

  lerp: (a, b, percent) ->
    (b - a) * percent + a

class Lantern
  constructor: (options) ->
    {@id, @ctx, @x, @y, @client, @alpha = 0, @radius = 40} = options
    @update_gradient()
    @fade_white_anim = new Animation pattern: [[1, 0], [1, 5000], [0, 1000]], on_update: (value) => @alpha = value
    @fade_anim = new Animation pattern: patterns[0], on_update: (value) =>
        @alpha = value
      , on_done: () => @fade_white()
    @client.addListener (message) => @onMessage(message)

  draw: (time) ->
    @fade_anim.tick(time)
    @fade_white_anim.tick(time)
    @update_gradient()
    @ctx.save()
    @ctx.translate(@x - @radius, @y - @radius)
    @ctx.fillStyle = @gradient
    @ctx.fillRect(0, 0, 100, 100)
    @ctx.restore()

  onMessage: (message) ->
    parts = message.destinationName.split("/")
    if parts[0] == "lantern" and parts[1] == @id
      console.log "lantern " + @id + " got message " + message.destinationName
      if parts[2] == "color"
        @color = parts[2]

  trigger: () ->
    if not @triggered
      @triggered = true
      window.setTimeout () =>
        @triggered = false
      , 2000
      @client.motion(@id)
      this.fade_color()

  reset: () ->
    this.fade_white()

  update_gradient: () ->
    @gradient = @ctx.createRadialGradient(50, 50, @radius, 50, 50, 0)
    @gradient.addColorStop(0, 'rgba(' + Math.round((1-@alpha) * 255) + ', ' + Math.round((1-@alpha) * 255) + ', 255, 0)')
    @gradient.addColorStop(1, 'rgba(' + Math.round((1-@alpha) * 255) + ', ' + Math.round((1-@alpha) * 255) + ', 255, 0.50)')

  fade_color: () ->
    @fade_anim.start()

  fade_white: () ->
    @fade_white_anim.start()

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

patterns = [
  [
    [0, 0]
    [1, 500]
   ]
]

class MQTTClient
  constructor: (hostname, port) ->
    @hostname = hostname
    @port = port
    @listeners = []

  connect: () ->
    console.log("Connecting to " + @hostname + "...")
    @client = new Paho.MQTT.Client(@hostname, Number(@port), "clientId")
    @client.onMessageArrived = (message) => @onMessageArrived(message)
    @client.connect({
        onSuccess: () => @onConnect()
    })

  onConnect: () ->
    console.log("Connected.")
    @client.subscribe("#")

  onMessageArrived: (message) ->
    console.log("Message arrived: topic=" + message.destinationName + ", message=" + message.payloadString)
    for listener in @listeners
      listener message

  addListener: (listener) ->
    @listeners.push listener

  motion: (id) ->
    message = new Paho.MQTT.Message("")
    message.destinationName = "lantern/" + id + "/motion"
    @client.send(message)

$(document).ready () ->
  client = new MQTTClient("192.168.1.132", 1884)
  client.connect()
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
    lanterns.push(new Lantern(id: 'sim' + pos[0], ctx: globs.ctx, x: pos[0], y: pos[1], client: client))

  frame()

globs.i = 0

window.onmousemove = (event) ->
  globs.i = event.clientX

frame = (timestamp) ->
  globs.ctx.drawImage(globs.bg, 0, 0)
  globs.ctx.fillRect(globs.i, 276, 10, 10)
  lantern.draw(timestamp) for lantern in lanterns

  for lantern, i in lanterns
    if Math.abs(lantern.x - globs.i) < 10
      lantern.trigger()
  window.requestAnimationFrame(frame)
