audioElement = document.createElement 'audio'
audioElement.setAttribute 'id', 'audio'
audioElement.setAttribute 'preload', 'auto'
audioElement.setAttribute 'type', 'audio/mpeg'
audioElement.setAttribute 'loop', ''
document.body.insertBefore audioElement, document.body.firstChild
audioElement.setAttribute 'src', 'pewpew1.mp3'



$snake = $('.snake')
$head = $('.head')
$segments = $('.segment')
snakeRads = Math.PI/2
snakeX = 100
# Assume the top-left corner of the browser is (0,0) and all Y values will be negative
snakeY = -100
baseVelocity = 3
velocity = baseVelocity


transformQueue = []
# Initial animation queue
for i in [0...$segments.length*5]
  transform = "translate(#{snakeX}px, #{-snakeY + 4*i}px)"
  transformQueue.push
    '-webkit-transform': transform, transform: transform


xMin = 20
yMin = -20
xMax = window.innerWidth - 60
yMax = -(window.innerHeight - 60)
minLength = 120 # distance at which to start turning
turnDirection = 0
getRotation = () ->
  sine = Math.sin(snakeRads)
  cosine = Math.cos(snakeRads)
  xLength = ((if cosine > 0 then xMax else xMin) - snakeX)/cosine
  yLength = ((if   sine < 0 then yMax else yMin) - snakeY)/sine

  rotation = Math.sin(Date.now()/150)/10
  if xLength < minLength || yLength < minLength
    if turnDirection == 0
      # turn the direction we were already turning
      turnDirection = if rotation > 0 then -1 else 1
    0.2 * turnDirection
  else
    turnDirection = 0
    rotation


animate = () ->
  requestAnimationFrame animate

  snakeRads += getRotation()
  snakeX = snakeX + velocity*Math.cos(snakeRads)
  snakeY = snakeY + velocity*Math.sin(snakeRads)

  # Use negative snakeY and snakeRads because the browser gets them backwards.
  transform = "translate(#{snakeX}px, #{-snakeY}px) rotate(#{-snakeRads}rad)"
  transformQueue.unshift '-webkit-transform': transform, transform: transform

  $snake.children().each (i) ->
    $(@).css transformQueue[i*5]
  transformQueue.pop()
  velocity = baseVelocity


shootLaser = () ->
  console.log 'pew pew'
  $laser1 = $('<div class="laser">')
  $laser2 = $('<div class="laser">')

  x1 = snakeX + 20 + 12*Math.cos(snakeRads) + 12*Math.sin(snakeRads)
  y1 = snakeY - 18 + 12*Math.sin(snakeRads) - 12*Math.cos(snakeRads)
  transform1 = "translate(#{x1}px, #{-y1}px) rotate(#{-snakeRads}rad)"
  $laser1.css '-webkit-transform': transform1, transform: transform1

  x2 = snakeX + 20 + 12*Math.cos(snakeRads+1.5) + 12*Math.sin(snakeRads+1.5)
  y2 = snakeY - 18 + 12*Math.sin(snakeRads+1.5) - 12*Math.cos(snakeRads+1.5)
  transform2 = "translate(#{x2}px, #{-y2}px) rotate(#{-snakeRads}rad)"
  $laser2.css '-webkit-transform': transform2, transform: transform2

  $('.snake-container').prepend $laser1, $laser2
  requestAnimationFrame ->
    $laser1.css
      '-webkit-transform': transform1 + ' scaleX(10)' + ' translateX(100px)'
      transform: transform1 + ' scaleX(10)' + ' translateX(100px)'
    $laser2.css
      '-webkit-transform': transform2 + ' scaleX(10)' + ' translateX(100px)'
      transform: transform2 + ' scaleX(10)' + ' translateX(100px)'

  setTimeout (-> $laser1.add($laser2).remove()), 1000


pewpewThrottled = false
pewpew = (array) ->
  return if pewpewThrottled || array[91] < 234
  requestAnimationFrame shootLaser
  pewpewThrottled = true
  setTimeout (-> pewpewThrottled = false), 110


whip = (array) ->
  snare = array[382]
  if snare > 170 then velocity += snare / 50



onCanPlay = ->
  this.removeEventListener 'canplay', onCanPlay
  audioContext = new (window.AudioContext || window.webkitAudioContext)

  console.log 'sample rate:', audioContext.sampleRate
  gain = audioContext.createGain()
  # Create audio processors
  audioSource = audioContext.createMediaElementSource(audioElement)
  audioScript = audioContext.createScriptProcessor(512)
  analyser = audioContext.createAnalyser()
  analyser.smoothingTimeConstant = 0.2
  analyser.fftSize = 1024

  # Connect audio to speaker output
  # audioSource.connect audioContext.destination
  gain.gain.value = 0.02
  audioSource.connect gain
  gain.connect audioContext.destination

  # Pipe audio through analyser
  audioSource.connect analyser
  analyser.connect audioScript
  audioScript.connect audioContext.destination

  # Update array with frequency data and update scene
  # Pin the listener in memory otherwise it will be GC'd in Chrome
  array = new Uint8Array analyser.frequencyBinCount
  audioScript.addEventListener 'audioprocess', window.pin = (e) ->
    analyser.getByteFrequencyData array
    pewpew(array)
    whip(array)

  setTimeout ->
    audioElement.play()
  , 20
  audioElement.play()

audioElement.addEventListener 'canplay', onCanPlay


animate()
