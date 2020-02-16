
#
# Implementation of simple second order IIR biquad filters: low pass, high
# pass, band pass and band stop.
#

import math
import tabs
import types

type

  BiquadKind* = enum
    BiquadLowPass,
    BiquadHighPass,
    BiquadBandPass,
    BiquadBandStop,
    BiquadLowShelf,
    BiquadHighShelf,

  Biquad* = object
    kind: BiquadKind
    freq: Frequency
    Q: QFactor

    inv_srate: Frequency
    x1, x2: Sample
    y0, y1, y2: Sample
    b0_a0, b1_a0, b2_a0: Sample
    a1_a0, a2_a0: Sample
    initialized: bool
    first: bool



proc config*(bq: var Biquad, kind: BiquadKind, freq: Frequency, Q: QFactor) =

  bq.kind = kind
  bq.freq = freq
  bq.Q = Q

  let
    f = freq * bq.inv_srate
    alpha = tabSin(f) / (2.0 * Q)
    cos_w0 = tabCos(f)

  var
    a0, a1, a2, b0, b1, b2: Sample

  case kind

    of BiquadLowPass:
      b0 = (1.0 - cos_w0) / 2.0
      b1 = 1.0 - cos_w0
      b2 = (1.0 - cos_w0) / 2.0
      a0 = 1.0 + alpha
      a1 = -2.0 * cos_w0
      a2 = 1.0 - alpha

    of BiquadHighPass:
      b0 = (1.0 + cos_w0) / 2.0
      b1 = -(1.0 + cos_w0)
      b2 = (1.0 + cos_w0) / 2.0
      a0 = 1.0 + alpha
      a1 = -2.0 * cos_w0
      a2 = 1.0 - alpha

    of BiquadBandPass:
      b0 = Q * alpha
      b1 = 0.0
      b2 = -Q * alpha
      a0 = 1.0 + alpha
      a1 = -2.0 * cos_w0
      a2 = 1.0 - alpha

    of BiquadBandStop:
      b0 = 1.0
      b1 = -2.0 * cos_w0
      b2 = 1.0
      a0 = 1.0 + alpha
      a1 = -2.0 * cos_w0
      a2 = 1.0 - alpha

    of BiquadLowShelf:    
      discard
      # b0 =    A*[ (A+1) - (A-1)*cos + beta*sin ]
      # b1 =  2*A*[ (A-1) - (A+1)*cos            ]
      # b2 =    A*[ (A+1) - (A-1)*cos - beta*sin ]
      # a0 =        (A+1) + (A-1)*cos + beta*sin
      # a1 =   -2*[ (A-1) + (A+1)*cos            ]
      # a2 =        (A+1) + (A-1)*cos - beta*sin

    of BiquadHighShelf: 
      discard
      # b0 =    A*[ (A+1) + (A-1)*cos + beta*sin ]
      # b1 = -2*A*[ (A-1) + (A+1)*cos            ]
      # b2 =    A*[ (A+1) + (A-1)*cos - beta*sin ]
      # a0 =        (A+1) - (A-1)*cos + beta*sin
      # a1 =    2*[ (A-1) - (A+1)*cos            ]
      # a2 =        (A+1) - (A-1)*cos - beta*sin

  let a0r = 1.0 / a0
  bq.b0_a0 = b0 * a0r
  bq.b1_a0 = b1 * a0r
  bq.b2_a0 = b2 * a0r
  bq.a1_a0 = a1 * a0r
  bq.a2_a0 = a2 * a0r
  bq.initialized = true


proc setFreq*(bq: var Biquad, freq: Frequency) =
  bq.config(bq.kind, freq, bq.Q)


proc initBiquad*(srate: Frequency, kind=BiquadLowpass, freq=1000.0, Q=0.707): Biquad =
  var bq: Biquad
  bq.first = true
  bq.inv_srate = 1.0 / srate
  bq.config(kind, freq, Q)
  result = bq


proc run*(bq: var Biquad, v_in: Sample): Sample =
  let x0 = v_in

  if bq.first:
    bq.y1 = x0
    bq.y2 = x0
    bq.x1 = x0
    bq.x2 = x0;
    bq.first = false;

  let y0 =
    bq.b0_a0 * x0 +
    bq.b1_a0 * bq.x1 +
    bq.b2_a0 * bq.x2 -
    bq.a1_a0 * bq.y1 -
    bq.a2_a0 * bq.y2

  bq.x2 = bq.x1
  bq.x1 = x0
  bq.y2 = bq.y1
  bq.y1 = y0

  result = y0

