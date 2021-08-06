# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import sequtils
import strformat
import strutils

import ../../../utils
import ../../../../src/nim64/chips/ic6581
import ../../../../src/nim64/components/link

const
  Path = "./docs/graphs/chip"

  A7 = (0xb0u8, 0xe6u8)
  C7 = (0x2bu8, 0x89u8)
  E7 = (0xd2u8, 0xacu8)

  Half = (0x00u8, 0x08u8)

  Low = (0x00u8, 0x40u8)
  Mid = (0x00u8, 0x80u8)
  High = (0x00u8, 0xc0u8)

var chip: Ic6581
var traces: Traces
var addr_traces, data_traces: seq[Trace]

proc write_to_file(name: string; values: seq[int]) =
  let str = join(values, ",")
  let text = &"const {name} = [{str}]"
  let path = &"{Path}/{name}.js"
  write_file(path, text)
  echo(&"Wrote file {path}")

proc setup =
  chip = new_ic6581()
  traces = device_traces(chip)

  set(traces[RES])
  set(traces[R_W])
  set(traces[CS])
  clear(traces[EXT])

  addr_traces = map(to_seq(0..4), proc (i: int): Trace = traces[&"A{i}"])
  data_traces = map(to_seq(0..7), proc (i: int): Trace = traces[&"D{i}"])

proc write_register(register: uint, value: uint8) =
  value_to_traces(value, data_traces)
  value_to_traces(register, addr_traces)
  clear(traces[R_W])
  clear(traces[CS])
  set(traces[CS])
  set(traces[R_W])

proc produce(w1, w2, w3: uint8; release = 0.75, iterations = 25000): seq[int] =
  let pre = int(float(iterations) * release)
  let post = iterations - pre

  for _ in 1..65536:
    set(traces[PHI2])
    clear(traces[PHI2])

  if w1 != 0: write_register(0x04, w1 or 0x01)
  if w2 != 0: write_register(0x0b, w2 or 0x01)
  if w3 != 0: write_register(0x12, w3 or 0x01)

  for _ in 1..pre:
    set(traces[PHI2])
    clear(traces[PHI2])
    add(result, int(level(traces[AUDIO])))

  if w1 != 0: write_register(0x04, w1 and 0xfe)
  if w2 != 0: write_register(0x0b, w2 and 0xfe)
  if w3 != 0: write_register(0x12, w3 and 0xfe)

  for _ in 1..post:
    set(traces[PHI2])
    clear(traces[PHI2])
    add(result, int(level(traces[AUDIO])))

proc set_pitch(voice: int, pitch: (uint8, uint8)) =
  let (frelo, frehi) = case voice:
    of 1: (0x00u, 0x01u)
    of 2: (0x07u, 0x08u)
    of 3: (0x0eu, 0x0fu)
    else: (0x00u, 0x01u)
  write_register(frelo, pitch[0])
  write_register(frehi, pitch[1])

proc set_pulse_width(voice: int, pw: (uint8, uint8)) =
  let (pwlo, pwhi) = case voice:
    of 1: (0x02u, 0x03u)
    of 2: (0x09u, 0x0au)
    of 3: (0x10u, 0x11u)
    else: (0x02u, 0x03u)
  write_register(pwlo, pw[0])
  write_register(pwhi, pw[1])

proc set_envelope(voice: int, env: uint) =
  let (atdcy, surel) = case voice:
    of 1: (0x05u, 0x06u)
    of 2: (0x0cu, 0x0du)
    of 3: (0x13u, 0x14u)
    else: (0x05u, 0x06u)
  write_register(atdcy, uint8(env shr 8))
  write_register(surel, uint8(env and 0xff))

proc set_cutoff(cutoff: (uint8, uint8)) =
  write_register(0x15u, cutoff[0])
  write_register(0x16u, cutoff[1])

proc sawtooth =
  setup()

  set_pitch(1, A7)
  set_envelope(1, 0x0080)
  write_register(0x18, 0x0f)

  let values = produce(0x20, 0x00, 0x00)

  write_to_file("sawtooth", values)

proc triangle =
  setup()

  set_pitch(2, C7)
  set_envelope(2, 0x0080)
  write_register(0x18, 0x0f)

  let values = produce(0x00, 0x10, 0x00)

  write_to_file("triangle", values)

proc pulse =
  setup()

  set_pitch(3, E7)
  set_pulse_width(3, Half)
  set_envelope(3, 0x0080)
  write_register(0x18, 0x0f)

  let values = produce(0x00, 0x00, 0x40)

  write_to_file("pulse", values)

proc combined =
  setup()

  set_pitch(1, A7)
  set_pitch(2, C7)
  set_pitch(3, E7)
  set_pulse_width(3, Half)
  set_envelope(1, 0x0080)
  set_envelope(2, 0x0080)
  set_envelope(3, 0x0080)
  write_register(0x18, 0x0f)

  let values = produce(0x20, 0x10, 0x40)

  write_to_file("combined", values)

proc lpLow =
  setup()

  set_pitch(1, A7)
  set_pitch(2, C7)
  set_pitch(3, E7)
  set_pulse_width(3, Half)
  set_envelope(1, 0x0080)
  set_envelope(2, 0x0080)
  set_envelope(3, 0x0080)
  set_cutoff(Low)
  write_register(0x17, 0x0f)
  write_register(0x18, 0x1f)

  let values = produce(0x20, 0x10, 0x40)

  write_to_file("lpLow", values)

proc lpMid =
  setup()

  set_pitch(1, A7)
  set_pitch(2, C7)
  set_pitch(3, E7)
  set_pulse_width(3, Half)
  set_envelope(1, 0x0080)
  set_envelope(2, 0x0080)
  set_envelope(3, 0x0080)
  set_cutoff(Mid)
  write_register(0x17, 0x0f)
  write_register(0x18, 0x1f)

  let values = produce(0x20, 0x10, 0x40)

  write_to_file("lpMid", values)

proc lpHigh =
  setup()

  set_pitch(1, A7)
  set_pitch(2, C7)
  set_pitch(3, E7)
  set_pulse_width(3, Half)
  set_envelope(1, 0x0080)
  set_envelope(2, 0x0080)
  set_envelope(3, 0x0080)
  set_cutoff(High)
  write_register(0x17, 0x0f)
  write_register(0x18, 0x1f)

  let values = produce(0x20, 0x10, 0x40)

  write_to_file("lpHigh", values)

proc hpLow =
  setup()

  set_pitch(1, A7)
  set_pitch(2, C7)
  set_pitch(3, E7)
  set_pulse_width(3, Half)
  set_envelope(1, 0x0080)
  set_envelope(2, 0x0080)
  set_envelope(3, 0x0080)
  set_cutoff(Low)
  write_register(0x17, 0x0f)
  write_register(0x18, 0x4f)

  let values = produce(0x20, 0x10, 0x40)

  write_to_file("hpLow", values)

proc hpMid =
  setup()

  set_pitch(1, A7)
  set_pitch(2, C7)
  set_pitch(3, E7)
  set_pulse_width(3, Half)
  set_envelope(1, 0x0080)
  set_envelope(2, 0x0080)
  set_envelope(3, 0x0080)
  set_cutoff(Mid)
  write_register(0x17, 0x0f)
  write_register(0x18, 0x4f)

  let values = produce(0x20, 0x10, 0x40)

  write_to_file("hpMid", values)

proc hpHigh =
  setup()

  set_pitch(1, A7)
  set_pitch(2, C7)
  set_pitch(3, E7)
  set_pulse_width(3, Half)
  set_envelope(1, 0x0080)
  set_envelope(2, 0x0080)
  set_envelope(3, 0x0080)
  set_cutoff(High)
  write_register(0x17, 0x0f)
  write_register(0x18, 0x4f)

  let values = produce(0x20, 0x10, 0x40)

  write_to_file("hpHigh", values)

proc bpLow =
  setup()

  set_pitch(1, A7)
  set_pitch(2, C7)
  set_pitch(3, E7)
  set_pulse_width(3, Half)
  set_envelope(1, 0x0080)
  set_envelope(2, 0x0080)
  set_envelope(3, 0x0080)
  set_cutoff(Low)
  write_register(0x17, 0x0f)
  write_register(0x18, 0x2f)

  let values = produce(0x20, 0x10, 0x40)

  write_to_file("bpLow", values)

proc bpMid =
  setup()

  set_pitch(1, A7)
  set_pitch(2, C7)
  set_pitch(3, E7)
  set_pulse_width(3, Half)
  set_envelope(1, 0x0080)
  set_envelope(2, 0x0080)
  set_envelope(3, 0x0080)
  set_cutoff(Mid)
  write_register(0x17, 0x0f)
  write_register(0x18, 0x2f)

  let values = produce(0x20, 0x10, 0x40)

  write_to_file("bpMid", values)

proc bpHigh =
  setup()

  set_pitch(1, A7)
  set_pitch(2, C7)
  set_pitch(3, E7)
  set_pulse_width(3, Half)
  set_envelope(1, 0x0080)
  set_envelope(2, 0x0080)
  set_envelope(3, 0x0080)
  set_cutoff(High)
  write_register(0x17, 0x0f)
  write_register(0x18, 0x2f)

  let values = produce(0x20, 0x10, 0x40)

  write_to_file("bpHigh", values)

proc all_tests* =
  sawtooth()
  triangle()
  pulse()
  combined()
  lpLow()
  lpMid()
  lpHigh()
  hpLow()
  hpMid()
  hpHigh()
  bpLow()
  bpMid()
  bpHigh()

when is_main_module:
  all_tests()
