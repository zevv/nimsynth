import sdl2/sdl

import dsp/osc
import dsp/types
import dsp/biquad
import audio


let au = initAudio(48000.0)
let srate = au.srate

var lfo1 = initOsc(srate, OscSin, 0.2)
var lfo2 = initOsc(srate, OscSin, 0.2)

var o1 = initOsc(srate, OscSaw, 110.0)
var o2 = initOsc(srate, OscSaw, 110.0 * 3.0 / 2.0 * 1.006)

var lp1 = initBiquad(srate, BiquadLowpass, 2000.0, 4.0)
var lp2 = initBiquad(srate, BiquadLowpass, 2000.0, 4.0)


proc genAudio() =

  while au.feed:

    var buf: seq[Sample]
    
    for i in 0..<au.samples:
      
      let v1 = o1.run()
      let v2 = o2.run()

      buf.add lp1.run(v1 * 0.1 + v2 * 0.3)
      buf.add lp2.run(v1 * 0.3 + v2 * 0.1)

      lp1.setFreq(lfo1.run() * 800 + 1000)
      lp2.setFreq(lfo2.run() * 800 + 1000)

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


