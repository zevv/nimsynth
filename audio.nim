
import sdl2/sdl

import dsp/types


type

  Audio* = ref object
    srate*: Samplerate
    samples*: int
    channels*: int
    buffers: int
    adev: AudioDeviceID
    play: AudioPool

  AudioBuf = ref object
    data: seq[float32]

  AudioPool = object
    buffers: seq[AudioBuf]
    head, tail: int


{.push stackTrace: off.}

# This will run from the SDL thread, make sure not do do anything here that
# involves Nim memory management

proc on_audio(userdata: pointer, stream: ptr uint8, len: cint) {.cdecl, exportc.} =
  let au = cast[Audio](userdata)
  copyMem(stream, au.play.buffers[au.play.tail].data[0].addr, len)
  au.play.tail = (au.play.tail + 1) mod au.buffers
  var e = sdl.Event(kind: UserEvent)
  discard pushEvent(addr e)

{.pop}


proc start*(au: Audio) =
  pauseAudioDevice(au.adev, 0)


proc stop*(au: Audio) =
  pauseAudioDevice(au.adev, 1)


proc feed*(au: Audio): bool =
  let nexthead = (au.play.head + 1) mod au.buffers
  return nexthead != au.play.tail


proc send*(au: Audio, buf: openArray[Sample]) =
  var p = au.play.buffers[au.play.head]
  for i in 0..<buf.len:
    p.data[i] = buf[i]
  au.play.head = (au.play.head + 1) mod au.buffers


proc initAudio*(srate: SampleRate=48000.0, channels=2, samples=256, buffers=5): Audio =

  discard sdl.init(sdl.InitAudio)
  
  var au = Audio()

  var want = AudioSpec(
    freq: srate.int,
    format: AUDIO_F32,
    channels: channels.uint8,
    samples: samples.uint16,
    callback: on_audio,
    userdata: cast[pointer](au)
  )

  var got: AudioSpec

  au.adev = openAudioDevice(nil, 0, addr want, addr got, 0)
  au.srate = got.freq.Samplerate
  au.samples = got.samples.int
  au.channels = got.channels.int
  au.samples = got.samples.int
  au.buffers = buffers
  
  echo "Opened audio device '", getAudioDeviceName(0, 0), "' at ", au.srate, " Hz"


  for i in 0..<buffers:
    let buf = AudioBuf()
    buf.data.setLen got.channels.int * got.samples.int
    au.play.buffers.add buf
    var e = sdl.Event(kind: UserEvent)
    discard pushEvent(addr e)

  au.start()

  return au

