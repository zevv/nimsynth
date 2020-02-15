
import sdl2/sdl
import system/ansi_c

import types


type

  Audio* = ref object
    samples*: int
    channels*: int
    buffers: int
    adev: AudioDeviceID
    playPool: AudioPool

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
  copyMem(stream, au.playPool.buffers[au.playPool.tail].data[0].addr, len)
  au.playPool.tail = (au.playPool.tail + 1) mod au.buffers
  var e = sdl.Event(kind: UserEvent)
  discard pushEvent(addr e)

{.pop}


proc start*(audio: Audio) =
  pauseAudioDevice(audio.adev, 0)


proc stop*(audio: Audio) =
  pauseAudioDevice(audio.adev, 1)


proc send*(au: Audio, buf: openArray[Sample]) =
  var p = au.playPool.buffers[au.playPool.head]
  for i in 0..<buf.len:
    p.data[i] = buf[i]
  au.playPool.head = (au.playPool.head + 1) mod au.buffers


proc initAudio*(srate: SampleRate=48000.0, channels=2, samples=256, buffers=3): Audio =

  discard sdl.init(sdl.InitAudio)
  
  var au = Audio()

  let n = sdl.getNumAudioDevices(1)

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
  au.samples = got.samples.int
  au.channels = got.channels.int
  au.samples = got.samples.int
  au.buffers = buffers

  for i in 0..<buffers:
    let buf = AudioBuf()
    buf.data.setLen got.channels.int * got.samples.int
    au.playPool.buffers.add buf

  au.start()

  return au

