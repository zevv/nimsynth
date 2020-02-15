
import types
import tabs

type
  Delay = object
    srate: Samplerate
    buf: seq[Sample]
    int: float32
    size: int
    head: int


proc initDelay*(srate: Samplerate, dt: Interval): Delay =
  var delay = Delay(
    srate: srate,
    size: (srate * dt).int
  )
  delay.buf.setLen delay.size
  return delay


proc read(delay: var Delay, where: float): Sample =
  result = delay.buf.read1(delay.head.float/delay.size.float + where)


proc run*(delay: var Delay, v: Sample): Sample =
  
  result = delay.read(0.15) * 0.40 +
           delay.read(0.30) * 0.10 +
           delay.read(0.50) * 0.05 +
           delay.read(0.70) * 0.05 

  delay.buf[delay.head] = v
  delay.head = (delay.head + 1) mod delay.size
