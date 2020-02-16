import math
import types

const sintabSize = 256

proc mkSintab(): array[sintabSize, Sample] =
  for i in 0..<sintabSize:
    let w = TAU * i.Sample / sintabSize.Sample
    result[i] = sin(w)

const sinTab = mkSintab()


proc read1*(tab: openArray[Sample], indexIn: Sample): Sample =
  ## Table read nearest neighbour
  var i = (tab.len.Sample * indexIn + 0.5).int
  i = i %% tab.len
  result = tab[i]


proc read2*(tab: openArray[Sample], indexIn: Sample): Sample =
  ## Table read using linear interpolation
  let
    i = indexIn - indexIn.floor
    p = i * tab.len.Sample
    i0 = (p.int + 0) %% tab.len
    i1 = (p.int + 1) %% tab.len
    a0 = p - i0.Sample
    a1 = 1.0 - a0
  result = tab[i0] * a1 + tab[i1] * a0;


proc read4*(tab: openArray[Sample], indexIn: Sample): Sample =
  ## Table read sinc interpolation
  let
    i = indexIn * tab.len.Sample
    i0 = i.int
    f = i - i.floor
    a = tab[(i0 + -1) %% tab.len]
    b = tab[(i0 +  0) %% tab.len]
    c = tab[(i0 +  1) %% tab.len]
    d = tab[(i0 +  2) %% tab.len]
    c_b = c - b;
  result = b + f * ( c_b - 0.16667 * (1.0-f) * ( (d - a - 3*c_b) * f + (d + 2*a - 3*b)))


proc tabSin*(idx: Sample): Sample =
  read2(sinTab, idx)


proc tabCos*(idx: Sample): Sample =
  read2(sinTab, idx + 0.25)

