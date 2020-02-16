
import types
import tabs
import osc

type
  Delay = object
    srate: Samplerate
    buf: seq[Sample]
    int: float32
    size: int
    head: int
    lfo: Osc


proc initDelay*(srate: Samplerate, dt: Interval): Delay =
  var delay = Delay(
    srate: srate,
    size: (srate * dt).int,
    lfo: initOsc(srate, OscSin, 0.01)
  )
  delay.buf.setLen delay.size
  return delay


proc read(delay: var Delay, where: float): Sample =
  result = delay.buf.read2(delay.head.float/delay.size.float - where)


proc run*(delay: var Delay, v: Sample): Sample =

  let off = delay.lfo.run() * 0.001
  
  result = delay.read(0.02 + off) * 0.6 +
           delay.read(0.15 + off) * 0.2 +
           delay.read(0.30 + off) * 0.1 
    
  delay.buf[delay.head] = v * 0.5 + result * 0.5

  delay.head = (delay.head + 1) mod delay.size
