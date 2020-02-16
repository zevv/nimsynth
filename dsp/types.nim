
type

  Sample* = float32
  Frequency* = float32
  SampleRate* = float32
  QFactor* = float32
  Interval* = float32

  Sink* = object
    buf*: ptr UncheckedArray[Sample]
    len*: int
    push*: proc()
  
  Source* = object
    buf*: ptr UncheckedArray[Sample]
    len*: int
    pull*: proc()
