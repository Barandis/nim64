# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import strformat
import strutils
import ../../../../src/nim64/chips/ic6581/voice

const
  Path = "./docs/graphs/voice"

  A7 = (0xb0u, 0xe6u)
  C7 = (0x2bu, 0x89u)

  Half = (0x00u, 0x08u)

proc write_to_file(name: string; values: seq[int]) =
  let str = join(values, ",")
  let text = &"const {name} = [{str}]"
  let path = &"{Path}/{name}.js"
  write_file(path, text)
  echo(&"Wrote file {path}")

proc produce(voice: Voice, waveform: uint, release = 0.75, iterations = 25000): seq[int] =
  let pre = int(float(iterations) * release)
  let post = iterations - pre

  vcreg(voice, waveform or 0x01)

  for _ in 1..pre:
    clock(voice)
    add(result, output(voice))

  vcreg(voice, waveform and 0xfe)

  for _ in 1..post:
    clock(voice)
    add(result, output(voice))

proc produce_sync(voice, sy: Voice; waveform: uint, release = 0.75, iterations = 25000): seq[int] =
  let pre = int(float(iterations) * release)
  let post = iterations - pre

  vcreg(voice, waveform or 0x01)

  for _ in 1..pre:
    clock(sy)
    clock(voice)
    add(result, output(voice))

  vcreg(voice, waveform and 0xfe)

  for _ in 1..post:
    clock(sy)
    clock(voice)
    add(result, output(voice))

proc set_pitch(voice: Voice, pitch: (uint, uint)) =
  frelo(voice, pitch[0])
  frehi(voice, pitch[1])

proc set_pulse_width(voice: Voice, pw: (uint, uint)) =
  pwlo(voice, pw[0])
  pwhi(voice, pw[1])

proc set_envelope(voice: Voice, env: uint) =
  atdcy(voice, (env shr 8) and 0xff)
  surel(voice, env and 0xff)

proc sawtooth =
  let voice = new_voice()
  set_pitch(voice, A7)
  set_envelope(voice, 0x0080)

  let values = produce(voice, 0x20)

  write_to_file("sawtooth", values)

proc triangle =
  let voice = new_voice()
  set_pitch(voice, A7)
  set_envelope(voice, 0x0080)

  let values = produce(voice, 0x10)

  write_to_file("triangle", values)

proc pulse =
  let voice = new_voice()
  set_pitch(voice, A7)
  set_pulse_width(voice, Half)
  set_envelope(voice, 0x0080)

  let values = produce(voice, 0x40)

  write_to_file("pulse", values)

proc noise =
  let voice = new_voice()
  set_pitch(voice, A7)
  set_envelope(voice, 0x0080)

  let values = produce(voice, 0x80)

  write_to_file("noise", values)

proc sawtooth_sync =
  let voice = new_voice()
  let sy = new_voice()
  sync(voice, sy)

  set_pitch(voice, A7)
  set_pitch(sy, C7)
  set_envelope(voice, 0x0080)

  let values = produce_sync(voice, sy, 0x22)

  write_to_file("sawtoothSync", values)

proc triangle_sync =
  let voice = new_voice()
  let sy = new_voice()
  sync(voice, sy)

  set_pitch(voice, A7)
  set_pitch(sy, C7)
  set_envelope(voice, 0x0080)

  let values = produce_sync(voice, sy, 0x12)

  write_to_file("triangleSync", values)

proc pulse_sync =
  let voice = new_voice()
  let sy = new_voice()
  sync(voice, sy)

  set_pitch(voice, A7)
  set_pitch(sy, C7)
  set_pulse_width(voice, Half)
  set_envelope(voice, 0x0080)

  let values = produce_sync(voice, sy, 0x42)

  write_to_file("pulseSync", values)

proc triangle_ring =
  let voice = new_voice()
  let sy = new_voice()
  sync(voice, sy)

  set_pitch(voice, A7)
  set_pitch(sy, C7)
  set_envelope(voice, 0x0080)

  let values = produce_sync(voice, sy, 0x14)

  write_to_file("triangleRing", values)

proc all_graphs* =
  sawtooth()
  triangle()
  pulse()
  noise()
  sawtooth_sync()
  triangle_sync()
  pulse_sync()
  triangle_ring()

when is_main_module:
  all_graphs()
