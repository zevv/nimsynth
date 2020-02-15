
import sdl2/sdl

import types


const
  srate = 48000.0
  audioBuffers = 1

type

  Audio* = object
    samples*: int
    adev: AudioDeviceID

  AudioBuf = ref object
    data: seq[float32]

  AudioPool = object
    buffers: seq[AudioBuf]
    head, tail: int

var
  playPool: AudioPool


{.push stackTrace: off.}

proc on_audio(userdata: pointer, stream: ptr uint8, len: cint) {.cdecl, exportc.} =
  copyMem(stream, playPool.buffers[playPool.tail].data[0].addr, len)
  playPool.tail = (playPool.tail + 1) mod audioBuffers
  var e = sdl.Event(kind: UserEvent)
  discard pushEvent(addr e)

{.pop}


proc start*(audio: Audio) =
  pauseAudioDevice(audio.adev, 0)


proc stop*(audio: Audio) =
  pauseAudioDevice(audio.adev, 1)


proc send*(au: Audio, buf: openArray[Sample]) =
  var p = playPool.buffers[playPool.head]
  for i in 0..<buf.len:
    p.data[i] = buf[i]
  playPool.head = (playPool.head + 1) mod audioBuffers


proc initAudio*(srate: SampleRate): Audio =

  discard sdl.init(sdl.InitAudio)

  let n = sdl.getNumAudioDevices(1)

  var want = AudioSpec(
    freq: srate.int,
    format: AUDIO_F32,
    channels: 1,
    samples: 256,
    callback: on_audio,
    userdata: cast[pointer](0)
  )

  var got = AudioSpec()
  let adev = openAudioDevice(nil, 0, addr want, addr got, 0)

  for i in 0..<audioBuffers:
    let buf = AudioBuf()
    buf.data.setLen got.channels.int * got.samples.int * sizeof(float32)
    playPool.buffers.add buf

  var au: Audio
  au.adev = adev
  au.samples = got.samples.int
  au.start()

  return au

