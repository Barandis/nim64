# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import strformat
import strutils
import ../../../../src/nim64/chips/ic6581/waveform

const
  Path = "./docs/graphs/sync"

  A4 = (0xd6u, 0x1cu)
  A7 = (0xb0u, 0xe6u)
  C4 = (0x25u, 0x11u)
  C7 = (0x2bu, 0x89u)

  Half = (0x00u, 0x08u)

proc write_to_file(name: string; values: seq[uint]) =
  let str = join(values, ",")
  let text = &"const {name} = [{str}]"
  let path = &"{Path}/{name}.js"
  write_file(path, text)
  echo(&"Wrote file {path}")

proc produce(wv, sy: Waveform, iterations: int = 25000): seq[uint] =
  for _ in 1..iterations:
    clock(sy)
    clock(wv)
    add(result, output(wv))

proc set_pitch(wave: Waveform, pitch: (uint, uint)) =
  frelo(wave, pitch[0])
  frehi(wave, pitch[1])

proc set_pulse_width(wave: Waveform, pw: (uint, uint)) =
  pwlo(wave, pw[0])
  pwhi(wave, pw[1])

proc graph_sawtooth_a4_c4 =
  let wv = new_waveform()
  let sy = new_waveform()
  sync(wv, sy)

  set_pitch(wv, A4)
  set_pitch(sy, C4)
  vcreg(wv, 0x22)

  let values = produce(wv, sy)

  write_to_file("sawtoothA4C4", values)

proc graph_sawtooth_a7_c4 =
  let wv = new_waveform()
  let sy = new_waveform()
  sync(wv, sy)

  set_pitch(wv, A7)
  set_pitch(sy, C4)
  vcreg(wv, 0x22)

  let values = produce(wv, sy)

  write_to_file("sawtoothA7C4", values)

proc graph_sawtooth_a7_c7 =
  let wv = new_waveform()
  let sy = new_waveform()
  sync(wv, sy)

  set_pitch(wv, A7)
  set_pitch(sy, C7)
  vcreg(wv, 0x22)

  let values = produce(wv, sy)

  write_to_file("sawtoothA7C7", values)

proc graph_pulse_a4_c4 =
  let wv = new_waveform()
  let sy = new_waveform()
  sync(wv, sy)

  set_pitch(wv, A4)
  set_pitch(sy, C4)
  set_pulse_width(wv, Half)
  vcreg(wv, 0x42)

  let values = produce(wv, sy)

  write_to_file("pulseA4C4", values)

proc graph_pulse_a7_c4 =
  let wv = new_waveform()
  let sy = new_waveform()
  sync(wv, sy)

  set_pitch(wv, A7)
  set_pitch(sy, C4)
  set_pulse_width(wv, Half)
  vcreg(wv, 0x42)

  let values = produce(wv, sy)

  write_to_file("pulseA7C4", values)

proc graph_pulse_a7_c7 =
  let wv = new_waveform()
  let sy = new_waveform()
  sync(wv, sy)

  set_pitch(wv, A7)
  set_pitch(sy, C7)
  set_pulse_width(wv, Half)
  vcreg(wv, 0x42)

  let values = produce(wv, sy)

  write_to_file("pulseA7C7", values)

proc graph_triangle_a4_c4 =
  let wv = new_waveform()
  let sy = new_waveform()
  sync(wv, sy)

  set_pitch(wv, A4)
  set_pitch(sy, C4)
  vcreg(wv, 0x12)

  let values = produce(wv, sy)

  write_to_file("triangleA4C4", values)

proc graph_ring_a4_c4 =
  let wv = new_waveform()
  let sy = new_waveform()
  sync(wv, sy)

  set_pitch(wv, A4)
  set_pitch(sy, C4)
  vcreg(wv, 0x14)

  let values = produce(wv, sy)

  write_to_file("ringA4C4", values)

proc graph_triangle_a7_c4 =
  let wv = new_waveform()
  let sy = new_waveform()
  sync(wv, sy)

  set_pitch(wv, A7)
  set_pitch(sy, C4)
  vcreg(wv, 0x12)

  let values = produce(wv, sy)

  write_to_file("triangleA7C4", values)

proc graph_ring_a7_c4 =
  let wv = new_waveform()
  let sy = new_waveform()
  sync(wv, sy)

  set_pitch(wv, A7)
  set_pitch(sy, C4)
  vcreg(wv, 0x14)

  let values = produce(wv, sy)

  write_to_file("ringA7C4", values)

proc graph_triangle_a7_c7 =
  let wv = new_waveform()
  let sy = new_waveform()
  sync(wv, sy)

  set_pitch(wv, A7)
  set_pitch(sy, C7)
  vcreg(wv, 0x12)

  let values = produce(wv, sy)

  write_to_file("triangleA7C7", values)

proc graph_ring_a7_c7 =
  let wv = new_waveform()
  let sy = new_waveform()
  sync(wv, sy)

  set_pitch(wv, A7)
  set_pitch(sy, C7)
  vcreg(wv, 0x14)

  let values = produce(wv, sy)

  write_to_file("ringA7C7", values)

proc all_graphs* =
  graph_sawtooth_a4_c4()
  graph_sawtooth_a7_c4()
  graph_sawtooth_a7_c7()
  graph_pulse_a4_c4()
  graph_pulse_a7_c4()
  graph_pulse_a7_c7()
  graph_triangle_a4_c4()
  graph_ring_a4_c4()
  graph_triangle_a7_c4()
  graph_ring_a7_c4()
  graph_triangle_a7_c7()
  graph_ring_a7_c7()

if is_main_module:
  all_graphs()
