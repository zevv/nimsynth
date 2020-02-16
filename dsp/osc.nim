
import tabs
import math
import types


type
  OscKind* = enum
    OscSin,
    OscSaw,
    OscSawNaive
    OscTriangle,
    OscTriangleNaive
    OscPulse,
    OscPulseNaive

  Osc* = ref object
    kind: OscKind
    phase: Sample
    srate_inv: Sample
    dphase: Sample
    dutycycle: Sample
    prev: Sample


proc polyBlep(t, dt: Sample): Sample =
  # polyblep: http://www.kvraudio.com/forum/viewtopic.php?t=375517
  if t < dt:
    let t0 = t / dt
    result = t0 + t0 - t0 * t0 - 1.0
  elif t > 1.0 - dt:
    let t0 = (t - 1.0) / dt
    result = t0 * t0 + t0 + t0 + 1.0
  else:
    result = 0.0


proc setFreq*(osc: var Osc, freq: Sample) =
  osc.dphase = freq * osc.srate_inv


proc setKind*(osc: var Osc, kind: OscKind) =
  osc.kind = kind


proc setDutyCycle*(osc: var Osc, dt: Sample) =
  osc.dutycycle = dt


proc initOsc*(srate: Sample, kind=OscSin, freq=1000.0, dutyCycle=0.5): Osc =
  var osc = Osc()
  osc.srate_inv = 1.0 / srate
  osc.setKind kind
  osc.setFreq freq
  osc.setDutyCycle dutyCycle
  result = osc


proc run*(osc: var Osc): Sample =

  var val: Sample

  case osc.kind

    of OscSin:
      val = tabSin(osc.phase)

    of OscPulseNaive:
      val = if osc.phase > 1.0 - osc.dutycycle: +1.0 else: -1.0

    of OscPulse:
      val = if osc.phase > 1.0 - osc.dutycycle: +1.0 else: -1.0
      val += polyBlep(fmod(osc.phase + osc.dutycycle, 1.0), osc.dphase)
      val -= polyBlep(osc.phase, osc.dphase)

    of OscTriangle:
      # Integrated pulse, leaky integrator
      val = if osc.phase > 0.5: +1.0 else: -1.0
      val += polyBlep(fmod(osc.phase + 0.5, 1.0), osc.dphase)
      val -= polyBlep(osc.phase, osc.dphase)
      val = osc.dphase * val + (1 - osc.dphase) * osc.prev
      osc.prev = val * 0.99
      val *= 4

    of OscTriangleNaive:
      val = -1.0 + 2.0 * osc.phase
      val = 2.0 * abs(val) - 1

    of OscSawNaive:
      val = osc.phase * 2.0 - 1.0

    of OscSaw:
      val = osc.phase * 2.0 - 1.0
      val -= poly_blep(osc.phase, osc.dphase)

  osc.phase += osc.dphase

  while osc.phase < 0.0:
    osc.phase += 1.0

  while osc.phase >= 1.0:
    osc.phase -= 1.0

  return val


proc run*(osc: var Osc, sink: Sink) =
  for i in 0..<sink.len:
    sink.buf[i] = osc.run()
  sink.push()


