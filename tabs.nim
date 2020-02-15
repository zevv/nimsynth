import math
import types

const sintabSize = 256

proc mkSintab(): array[sintabSize, Sample] =
  for i in 0..<sintabSize:
    let w = TAU * i.Sample / sintabSize.Sample
    result[i] = sin(w)

const sinTab = mkSintab()


proc read2*(tab: openArray[Sample], indexIn: Sample): Sample =
  ## Table read using linear interpolation
  let
    index = indexIn - indexIn.floor
    p = index * tab.len.Sample
    i0 = (p.int + 0) mod tab.len
    i1 = (p.int + 1) mod tab.len
    a0 = p - i0.Sample
    a1 = 1.0 - a0
  result = tab[i0] * a1 + tab[i1] * a0;


proc tabSin*(idx: Sample): Sample =
  read2(sinTab, idx)


proc tabCos*(idx: Sample): Sample =
  read2(sinTab, idx + 0.25)

