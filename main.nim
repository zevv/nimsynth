import sdl2/sdl

import osc
import biquad
import audio
import types

const
  srate = 48000.0

let au = initAudio(srate)

var lfo = initOsc(srate, OscSin, 1.0)
var o1 = initOsc(srate, OscSaw, 110.0)
var o2 = initOsc(srate, OscSaw, 110.0 * 3.0 / 2.0 * 1.004)
var lp = initBiquad(srate, BiquadLowpass, 2000.0, 3.0)


proc genAudio() =

  var buf: seq[Sample]

  for i in 0..<au.samples:
    let v = o1.run() + o2.run()
    buf.add lp.run(v) * 0.1

    lp.setFreq(lfo.run() * 800 + 1000)

  au.send(buf)


var e: sdl.Event

while true:

  if sdl.waitEvent(addr e) != 0:

    case e.kind
      of sdl.UserEvent:
        genAudio()

      of sdl.KeyDown:
        break

      else:
        discard


