# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import strformat
import strutils
import ../../../../src/nim64/chips/ic6581/voice
import ../../../../src/nim64/chips/ic6581/filter

const
  Path = "./docs/graphs/filter"

  A7 = (0xb0u, 0xe6u)
  C7 = (0x2bu, 0x89u)
  E7 = (0xd2u, 0xacu)

  Half = (0x00u, 0x08u)

  Low = (0x00u, 0x40u)
  Mid = (0x00u, 0x80u)
  High = (0x00u, 0xc0u)

proc write_to_file(name: string; values: seq[int]) =
  let str = join(values, ",")
  let text = &"const {name} = [{str}]"
  let path = &"{Path}/{name}.js"
  write_file(path, text)
  echo(&"Wrote file {path}")

proc produce(
  v1, v2, v3: Voice;
  w1, w2, w3: uint;
  filter: Filter,
  release = 0.75,
  iterations = 25000
): seq[int] =
  let pre = int(float(iterations) * release)
  let post = iterations - pre

  for _ in 1..65536:
    clock(v1)
    clock(v2)
    clock(v3)
    clock(filter, 0, 0, 0, 0)

  if w1 != 0: vcreg(v1, w1 or 0x01)
  if w2 != 0: vcreg(v2, w2 or 0x01)
  if w3 != 0: vcreg(v3, w3 or 0x01)

  for _ in 1..pre:
    clock(v1)
    clock(v2)
    clock(v3)
    clock(filter, output(v1), output(v2), output(v3), 0)
    add(result, output(filter))

  if w1 != 0: vcreg(v1, w1 and 0xfe)
  if w2 != 0: vcreg(v2, w2 and 0xfe)
  if w3 != 0: vcreg(v3, w3 and 0xfe)

  for _ in 1..post:
    clock(v1)
    clock(v2)
    clock(v3)
    clock(filter, output(v1), output(v2), output(v3), 0)
    add(result, output(filter))

proc set_pitch(voice: Voice, pitch: (uint, uint)) =
  frelo(voice, pitch[0])
  frehi(voice, pitch[1])

proc set_pulse_width(voice: Voice, pw: (uint, uint)) =
  pwlo(voice, pw[0])
  pwhi(voice, pw[1])

proc set_envelope(voice: Voice, env: uint) =
  atdcy(voice, (env shr 8) and 0xff)
  surel(voice, env and 0xff)

proc set_cutoff(filter: Filter, cutoff: (uint, uint)) =
  cutlo(filter, cutoff[0])
  cuthi(filter, cutoff[1])

proc sawtooth =
  let v1 = new_voice()
  let v2 = new_voice()
  let v3 = new_voice()
  let filter = new_filter()

  set_pitch(v1, A7)
  set_envelope(v1, 0x0080)
  sigvol(filter, 0x0f)

  let values = produce(v1, v2, v3, 0x20, 0x00, 0x00, filter)

  write_to_file("sawtooth", values)

proc triangle =
  let v1 = new_voice()
  let v2 = new_voice()
  let v3 = new_voice()
  let filter = new_filter()

  set_pitch(v2, C7)
  set_envelope(v2, 0x0080)
  sigvol(filter, 0x0f)

  let values = produce(v1, v2, v3, 0x00, 0x10, 0x00, filter)

  write_to_file("triangle", values)

proc pulse =
  let v1 = new_voice()
  let v2 = new_voice()
  let v3 = new_voice()
  let filter = new_filter()

  set_pitch(v3, E7)
  set_pulse_width(v3, Half)
  set_envelope(v3, 0x0080)
  sigvol(filter, 0x0f)

  let values = produce(v1, v2, v3, 0x00, 0x00, 0x40, filter)

  write_to_file("pulse", values)

proc combined =
  let v1 = new_voice()
  let v2 = new_voice()
  let v3 = new_voice()
  let filter = new_filter()

  set_pitch(v1, A7)
  set_pitch(v2, C7)
  set_pitch(v3, E7)
  set_pulse_width(v3, Half)
  set_envelope(v1, 0x0080)
  set_envelope(v2, 0x0080)
  set_envelope(v3, 0x0080)
  sigvol(filter, 0x0f)

  let values = produce(v1, v2, v3, 0x20, 0x10, 0x40, filter)

  write_to_file("combined", values)

proc lp_low =
  let v1 = new_voice()
  let v2 = new_voice()
  let v3 = new_voice()
  let filter = new_filter()

  set_pitch(v1, A7)
  set_pitch(v2, C7)
  set_pitch(v3, E7)
  set_pulse_width(v3, Half)
  set_envelope(v1, 0x0080)
  set_envelope(v2, 0x0080)
  set_envelope(v3, 0x0080)

  set_cutoff(filter, Low)
  reson(filter, 0x0f)
  sigvol(filter, 0x1f)

  let values = produce(v1, v2, v3, 0x20, 0x10, 0x40, filter)

  write_to_file("lpLow", values)

proc lp_mid =
  let v1 = new_voice()
  let v2 = new_voice()
  let v3 = new_voice()
  let filter = new_filter()

  set_pitch(v1, A7)
  set_pitch(v2, C7)
  set_pitch(v3, E7)
  set_pulse_width(v3, Half)
  set_envelope(v1, 0x0080)
  set_envelope(v2, 0x0080)
  set_envelope(v3, 0x0080)

  set_cutoff(filter, Mid)
  reson(filter, 0x0f)
  sigvol(filter, 0x1f)

  let values = produce(v1, v2, v3, 0x20, 0x10, 0x40, filter)

  write_to_file("lpMid", values)

proc lp_high =
  let v1 = new_voice()
  let v2 = new_voice()
  let v3 = new_voice()
  let filter = new_filter()

  set_pitch(v1, A7)
  set_pitch(v2, C7)
  set_pitch(v3, E7)
  set_pulse_width(v3, Half)
  set_envelope(v1, 0x0080)
  set_envelope(v2, 0x0080)
  set_envelope(v3, 0x0080)

  set_cutoff(filter, High)
  reson(filter, 0x0f)
  sigvol(filter, 0x1f)

  let values = produce(v1, v2, v3, 0x20, 0x10, 0x40, filter)

  write_to_file("lpHigh", values)

proc hp_low =
  let v1 = new_voice()
  let v2 = new_voice()
  let v3 = new_voice()
  let filter = new_filter()

  set_pitch(v1, A7)
  set_pitch(v2, C7)
  set_pitch(v3, E7)
  set_pulse_width(v3, Half)
  set_envelope(v1, 0x0080)
  set_envelope(v2, 0x0080)
  set_envelope(v3, 0x0080)

  set_cutoff(filter, Low)
  reson(filter, 0x0f)
  sigvol(filter, 0x4f)

  let values = produce(v1, v2, v3, 0x20, 0x10, 0x40, filter)

  write_to_file("hpLow", values)

proc hp_mid =
  let v1 = new_voice()
  let v2 = new_voice()
  let v3 = new_voice()
  let filter = new_filter()

  set_pitch(v1, A7)
  set_pitch(v2, C7)
  set_pitch(v3, E7)
  set_pulse_width(v3, Half)
  set_envelope(v1, 0x0080)
  set_envelope(v2, 0x0080)
  set_envelope(v3, 0x0080)

  set_cutoff(filter, Mid)
  reson(filter, 0x0f)
  sigvol(filter, 0x4f)

  let values = produce(v1, v2, v3, 0x20, 0x10, 0x40, filter)

  write_to_file("hpMid", values)

proc hp_high =
  let v1 = new_voice()
  let v2 = new_voice()
  let v3 = new_voice()
  let filter = new_filter()

  set_pitch(v1, A7)
  set_pitch(v2, C7)
  set_pitch(v3, E7)
  set_pulse_width(v3, Half)
  set_envelope(v1, 0x0080)
  set_envelope(v2, 0x0080)
  set_envelope(v3, 0x0080)

  set_cutoff(filter, High)
  reson(filter, 0x0f)
  sigvol(filter, 0x4f)

  let values = produce(v1, v2, v3, 0x20, 0x10, 0x40, filter)

  write_to_file("hpHigh", values)

proc bp_low =
  let v1 = new_voice()
  let v2 = new_voice()
  let v3 = new_voice()
  let filter = new_filter()

  set_pitch(v1, A7)
  set_pitch(v2, C7)
  set_pitch(v3, E7)
  set_pulse_width(v3, Half)
  set_envelope(v1, 0x0080)
  set_envelope(v2, 0x0080)
  set_envelope(v3, 0x0080)

  set_cutoff(filter, Low)
  reson(filter, 0x0f)
  sigvol(filter, 0x2f)

  let values = produce(v1, v2, v3, 0x20, 0x10, 0x40, filter)

  write_to_file("bpLow", values)

proc bp_mid =
  let v1 = new_voice()
  let v2 = new_voice()
  let v3 = new_voice()
  let filter = new_filter()

  set_pitch(v1, A7)
  set_pitch(v2, C7)
  set_pitch(v3, E7)
  set_pulse_width(v3, Half)
  set_envelope(v1, 0x0080)
  set_envelope(v2, 0x0080)
  set_envelope(v3, 0x0080)

  set_cutoff(filter, Mid)
  reson(filter, 0x0f)
  sigvol(filter, 0x2f)

  let values = produce(v1, v2, v3, 0x20, 0x10, 0x40, filter)

  write_to_file("bpMid", values)

proc bp_high =
  let v1 = new_voice()
  let v2 = new_voice()
  let v3 = new_voice()
  let filter = new_filter()

  set_pitch(v1, A7)
  set_pitch(v2, C7)
  set_pitch(v3, E7)
  set_pulse_width(v3, Half)
  set_envelope(v1, 0x0080)
  set_envelope(v2, 0x0080)
  set_envelope(v3, 0x0080)

  set_cutoff(filter, High)
  reson(filter, 0x0f)
  sigvol(filter, 0x2f)

  let values = produce(v1, v2, v3, 0x20, 0x10, 0x40, filter)

  write_to_file("bpHigh", values)

proc all_graphs* =
  sawtooth()
  triangle()
  pulse()
  combined()
  lp_low()
  lp_mid()
  lp_high()
  hp_low()
  hp_mid()
  hp_high()
  bp_low()
  bp_mid()
  bp_high()

when is_main_module:
  all_graphs()
