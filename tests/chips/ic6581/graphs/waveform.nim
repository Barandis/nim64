# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import strformat
import strutils
import ../../../../src/nim64/chips/ic6581/waveform

const
  Path = "./docs/graphs/waveform"

  A4 = (0xd6u, 0x1cu)
  A7 = (0xb0u, 0xe6u)

  Half = (0x00u, 0x08u)
  Quarter = (0x00u, 0x04u)
  ThreeQuarter = (0x00u, 0x0bu)

proc write_to_file(name: string; values: seq[uint]) =
  let str = join(values, ",")
  let text = &"const {name} = [{str}]"
  let path = &"{Path}/{name}.js"
  write_file(path, text)
  echo(&"Wrote file {path}")

proc produce(wave: Waveform, iterations: int = 25000): seq[uint] =
  for _ in 1..iterations:
    clock(wave)
    add(result, output(wave))

proc set_pitch(wave: Waveform, pitch: (uint, uint)) =
  frelo(wave, pitch[0])
  frehi(wave, pitch[1])

proc set_pulse_width(wave: Waveform, pw: (uint, uint)) =
  pwlo(wave, pw[0])
  pwhi(wave, pw[1])

proc graph_sawtooth_a4 =
  let wave = new_waveform()
  set_pitch(wave, A4)
  vcreg(wave, 0x20)

  let values = produce(wave)

  write_to_file("sawtoothA4", values)

proc graph_sawtooth_a7 =
  let wave = new_waveform()
  set_pitch(wave, A7)
  vcreg(wave, 0x20)

  let values = produce(wave)

  write_to_file("sawtoothA7", values)

proc graph_triangle_a4 =
  let wave = new_waveform()
  set_pitch(wave, A4)
  vcreg(wave, 0x10)

  let values = produce(wave)

  write_to_file("triangleA4", values)

proc graph_triangle_a7 =
  let wave = new_waveform()
  set_pitch(wave, A7)
  vcreg(wave, 0x10)

  let values = produce(wave)

  write_to_file("triangleA7", values)

proc graph_pulse25_a4 =
  let wave = new_waveform()
  set_pitch(wave, A4)
  set_pulse_width(wave, Quarter)
  vcreg(wave, 0x40)

  let values = produce(wave)

  write_to_file("pulse25A4", values)

proc graph_pulse25_a7 =
  let wave = new_waveform()
  set_pitch(wave, A7)
  set_pulse_width(wave, Quarter)
  vcreg(wave, 0x40)

  let values = produce(wave)

  write_to_file("pulse25A7", values)

proc graph_pulse50_a4 =
  let wave = new_waveform()
  set_pitch(wave, A4)
  set_pulse_width(wave, Half)
  vcreg(wave, 0x40)

  let values = produce(wave)

  write_to_file("pulse50A4", values)

proc graph_pulse50_a7 =
  let wave = new_waveform()
  set_pitch(wave, A7)
  set_pulse_width(wave, Half)
  vcreg(wave, 0x40)

  let values = produce(wave)

  write_to_file("pulse50A7", values)

proc graph_pulse75_a4 =
  let wave = new_waveform()
  set_pitch(wave, A4)
  set_pulse_width(wave, ThreeQuarter)
  vcreg(wave, 0x40)

  let values = produce(wave)

  write_to_file("pulse75A4", values)

proc graph_pulse75_a7 =
  let wave = new_waveform()
  set_pitch(wave, A7)
  set_pulse_width(wave, ThreeQuarter)
  vcreg(wave, 0x40)

  let values = produce(wave)

  write_to_file("pulse75A7", values)

proc graph_noise_a4 =
  let wave = new_waveform()
  set_pitch(wave, A4)
  vcreg(wave, 0x80)

  let values = produce(wave)

  write_to_file("noiseA4", values)

proc graph_noise_a7 =
  let wave = new_waveform()
  set_pitch(wave, A7)
  vcreg(wave, 0x80)

  let values = produce(wave)

  write_to_file("noiseA7", values)

proc graph_saw_tri_a4 =
  let wave = new_waveform()
  set_pitch(wave, A4)
  vcreg(wave, 0x30)

  let values = produce(wave)

  write_to_file("sawTriA4", values)

proc graph_saw_tri_a7 =
  let wave = new_waveform()
  set_pitch(wave, A7)
  vcreg(wave, 0x30)

  let values = produce(wave)

  write_to_file("sawTriA7", values)

proc graph_saw_pul_a4 =
  let wave = new_waveform()
  set_pitch(wave, A4)
  set_pulse_width(wave, Half)
  vcreg(wave, 0x60)

  let values = produce(wave)

  write_to_file("sawPulA4", values)

proc graph_saw_pul_a7 =
  let wave = new_waveform()
  set_pitch(wave, A7)
  set_pulse_width(wave, Half)
  vcreg(wave, 0x60)

  let values = produce(wave)

  write_to_file("sawPulA7", values)

proc graph_tri_pul_a4 =
  let wave = new_waveform()
  set_pitch(wave, A4)
  set_pulse_width(wave, Half)
  vcreg(wave, 0x50)

  let values = produce(wave)

  write_to_file("triPulA4", values)

proc graph_tri_pul_a7 =
  let wave = new_waveform()
  set_pitch(wave, A7)
  set_pulse_width(wave, Half)
  vcreg(wave, 0x50)

  let values = produce(wave)

  write_to_file("triPulA7", values)

proc graph_saw_tri_pul_a4 =
  let wave = new_waveform()
  set_pitch(wave, A4)
  set_pulse_width(wave, Half)
  vcreg(wave, 0x70)

  let values = produce(wave)

  write_to_file("sawTriPulA4", values)

proc graph_saw_tri_pul_a7 =
  let wave = new_waveform()
  set_pitch(wave, A7)
  set_pulse_width(wave, Half)
  vcreg(wave, 0x70)

  let values = produce(wave)

  write_to_file("sawTriPulA7", values)

proc all_graphs* =
  graph_sawtooth_a4()
  graph_sawtooth_a7()
  graph_triangle_a4()
  graph_triangle_a7()
  graph_pulse25_a4()
  graph_pulse25_a7()
  graph_pulse50_a4()
  graph_pulse50_a7()
  graph_pulse75_a4()
  graph_pulse75_a7()
  graph_noise_a4()
  graph_noise_a7()
  graph_saw_tri_a4()
  graph_saw_tri_a7()
  graph_saw_pul_a4()
  graph_saw_pul_a7()
  graph_tri_pul_a4()
  graph_tri_pul_a7()
  graph_saw_tri_pul_a4()
  graph_saw_tri_pul_a7()

when is_main_module:
  all_graphs()
