# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import random
import sequtils
import strformat
import tables
import ../../utils as test_utils
import ../../../src/nim64/utils
import ../../../src/nim64/chips/ic6581
import ../../../src/nim64/components/link

let breakpoints = to_table([
  (0xffu, 1), (0x5du, 2), (0x36u, 4), (0x1au, 8), (0x0eu, 16), (0x06u, 30)])

proc setup: (Ic6581, Traces, seq[Trace], seq[Trace]) =
  let chip = new_ic6581()
  let traces = device_traces(chip)

  set(traces[RES])
  set(traces[R_W])
  set(traces[CS])
  clear(traces[EXT])
  clear(traces[PHI2])

  let addr_traces = map(to_seq(0..4), proc (i: int): Trace = traces[&"A{i}"])
  let data_traces = map(to_seq(0..7), proc (i: int): Trace = traces[&"D{i}"])

  randomize()

  (chip, traces, addr_traces, data_traces)

proc read_register(traces: Traces; addr_traces, data_traces: seq[Trace]; index: uint): uint =
  value_to_traces(index, addr_traces)
  clear(traces[CS])
  result = traces_to_value(data_traces)
  set(traces[CS])

proc write_register(traces: Traces; addr_traces, data_traces: seq[Trace]; index, value: uint) =
  value_to_traces(index, addr_traces)
  value_to_traces(value, data_traces)
  clear(traces[R_W])
  clear(traces[CS])
  set(traces[CS])
  set(traces[R_W])

proc pot_registers_init =
  let (_, traces, addr_traces, data_traces) = setup()

  let potx = read_register(traces, addr_traces, data_traces, 0x19u)
  check potx == 0u

  let poty = read_register(traces, addr_traces, data_traces, 0x1au)
  check poty == 0u

proc pot_registers_update =
  let (_, traces, addr_traces, data_traces) = setup()
  let x = rand(256)
  let y = rand(256)

  set_level(traces[POTX], float(x))
  set_level(traces[POTY], float(y))

  var potx = read_register(traces, addr_traces, data_traces, 0x19u)
  var poty = read_register(traces, addr_traces, data_traces, 0x1au)
  check potx == 0u
  check poty == 0u

  for _ in 1..511:
    set(traces[PHI2])
    clear(traces[PHI2])

  potx = read_register(traces, addr_traces, data_traces, 0x19u)
  poty = read_register(traces, addr_traces, data_traces, 0x1au)
  check potx == 0u
  check poty == 0u

  set(traces[PHI2])
  clear(traces[PHI2])

  potx = read_register(traces, addr_traces, data_traces, 0x19u)
  poty = read_register(traces, addr_traces, data_traces, 0x1au)
  check potx == uint(x)
  check poty == uint(y)

proc osc3_sawtooth =
  let (_, traces, addr_traces, data_traces) = setup()

  for f in [1u, 2u, 4u, 8u]:
    clear(traces[RES])
    for _ in 1..10: clear(set(traces[PHI2]))
    set(traces[RES])

    write_register(traces, addr_traces, data_traces, 0x0e, 0x00)
    write_register(traces, addr_traces, data_traces, 0x0f, f)
    write_register(traces, addr_traces, data_traces, 0x12, 0x20)

    let inc = f shl 8
    var acc = 0u

    for _ in 0..(0x100000 div inc):
      clear(set(traces[PHI2]))
      acc += inc
      let expected = (acc shr 16) and 0xff
      let actual = read_register(traces, addr_traces, data_traces, 0x1b)
      check actual == expected

proc osc3_triangle =
  let (_, traces, addr_traces, data_traces) = setup()

  for f in [1u, 2u, 4u, 8u]:
    clear(traces[RES])
    for _ in 1..10: clear(set(traces[PHI2]))
    set(traces[RES])

    write_register(traces, addr_traces, data_traces, 0x0e, 0x00)
    write_register(traces, addr_traces, data_traces, 0x0f, f)
    write_register(traces, addr_traces, data_traces, 0x12, 0x10)

    let inc = f shl 8
    var acc = 0u

    for _ in 0..(0x100000 div inc):
      clear(set(traces[PHI2]))
      acc += inc
      let expected = ((if bit_set(acc, 23): not acc else: acc) shr 15) and 0xff
      let actual = read_register(traces, addr_traces, data_traces, 0x1b)
      check actual == expected

proc osc3_pulse =
  let (_, traces, addr_traces, data_traces) = setup()

  for f in [1u, 2u, 4u, 8u]:
    clear(traces[RES])
    for _ in 1..10: clear(set(traces[PHI2]))
    set(traces[RES])

    write_register(traces, addr_traces, data_traces, 0x0e, 0x00)
    write_register(traces, addr_traces, data_traces, 0x0f, f)
    write_register(traces, addr_traces, data_traces, 0x10, 0x00)
    write_register(traces, addr_traces, data_traces, 0x11, 0x08)
    write_register(traces, addr_traces, data_traces, 0x12, 0x40)

    let inc = f shl 8
    var acc = 0u

    for _ in 0..(0x100000 div inc):
      clear(set(traces[PHI2]))
      acc += inc
      let expected = if ((acc shr 12) and 0xfff) < 0x800: 0xffu else: 0x00u
      let actual = read_register(traces, addr_traces, data_traces, 0x1b)
      check actual == expected

proc osc3_noise =
  let (_, traces, addr_traces, data_traces) = setup()

  for f in [1u, 2u, 4u, 8u]:
    clear(traces[RES])
    for _ in 1..10: clear(set(traces[PHI2]))
    set(traces[RES])

    write_register(traces, addr_traces, data_traces, 0x0e, 0x00)
    write_register(traces, addr_traces, data_traces, 0x0f, f)
    write_register(traces, addr_traces, data_traces, 0x12, 0x80)

    let inc = f shl 8
    var acc = 0u
    var lfsr = 0x7ffff8u
    var last_clock = false

    for _ in 0..(0x100000 div inc):
      clear(set(traces[PHI2]))
      acc += inc

      let bit19 = bit_set(acc, 19)
      if not last_clock and bit19:
        lfsr = lfsr shl 1
        lfsr = lfsr or uint(bit_set(lfsr, 17) xor bit_set(lfsr, 22))
        lfsr = lfsr and 0x7fffff
      last_clock = bit19

      let expected = uint(bit_set(lfsr, 0)) or
        uint(bit_set(lfsr, 2)) shl 1 or
        uint(bit_set(lfsr, 5)) shl 2 or
        uint(bit_set(lfsr, 9)) shl 3 or
        uint(bit_set(lfsr, 11)) shl 4 or
        uint(bit_set(lfsr, 14)) shl 5 or
        uint(bit_set(lfsr, 18)) shl 6 or
        uint(bit_set(lfsr, 20)) shl 7
      let actual = read_register(traces, addr_traces, data_traces, 0x1b)
      check actual == expected

proc env3_envelope =
  let (_, traces, addr_traces, data_traces) = setup()

  write_register(traces, addr_traces, data_traces, 0x13, 0x00)
  write_register(traces, addr_traces, data_traces, 0x14, 0x80)
  write_register(traces, addr_traces, data_traces, 0x12, 0x01)

  # Attack phase
  for i in 0x00u..0xffu:
    check read_register(traces, addr_traces, data_traces, 0x1c) == i
    for _ in 1..9: cycle(traces[PHI2])

  # Decay phase
  for i in countdown(0xfeu, 0x88u):
    check read_register(traces, addr_traces, data_traces, 0x1c) == i
    # No falloff change from 1 because sustain level is higher than first breakpoint
    # All falloff changes happen in release phase
    for _ in 1..9: cycle(traces[PHI2])

  # Sustain phase
  for _ in 1..256:
    check read_register(traces, addr_traces, data_traces, 0x1c) == 0x88

  # Release phase, where the falloff changes happen
  write_register(traces, addr_traces, data_traces, 0x12, 0x00)
  var falloff = 1

  for i in countdown(0x88u, 0x00u):
    if i in breakpoints: falloff = breakpoints[i]
    check read_register(traces, addr_traces, data_traces, 0x1c) == i
    for _ in 1..9:
      for _ in 1..falloff: cycle(traces[PHI2])

proc read_writable =
  let (_, traces, addr_traces, data_traces) = setup()

  let value = uint(rand(256))
  write_register(traces, addr_traces, data_traces, 0x09, value)

  for i in 0x00u..0x18u:
    check read_register(traces, addr_traces, data_traces, i) == value

  for _ in 1..1999: cycle(traces[PHI2])

  for i in 0x00u..0x18u:
    check read_register(traces, addr_traces, data_traces, i) == value

  cycle(traces[PHI2])

  for i in 0x00u..0x18u:
    check read_register(traces, addr_traces, data_traces, i) == 0u


proc all_tests* =
  suite "6581 registers":
    test "potentiometer registers are zero if pin unset": pot_registers_init()
    test "potentiometer registers update every 512 cycles": pot_registers_update()
    test "oscillator 3 register reflects sawtooth from voice 3": osc3_sawtooth()
    test "oscillator 3 register reflects triangle from voice 3": osc3_triangle()
    test "oscillator 3 register reflects pulse from voice 3": osc3_pulse()
    test "oscillator 3 register reflects noise from voice 3": osc3_noise()
    test "envelope 3 register reflects envelope from voice 3": env3_envelope()
    test "reading write-only register returns last written value": read_writable()

when is_main_module:
  all_tests()
