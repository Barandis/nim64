# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import sequtils
import strformat

import ../utils
import ../../src/nim64/roms/character
import ../../src/nim64/chips/ic2332
import ../../src/nim64/components/link

proc setup: (Ic2332, Traces, seq[Trace], seq[Trace]) =
  let chip = new_ic2332(CharacterRom)
  let traces = device_traces(chip)

  clear(traces[CS2])
  set(traces[CS1])

  let addr_traces = map(to_seq(0..11), proc (i: int): Trace = traces[&"A{i}"])
  let data_traces = map(to_seq(0..7), proc (i: int): Trace = traces[&"D{i}"])

  result = (chip, traces, addr_traces, data_traces)

proc read_all =
  let (_, traces, addr_traces, data_traces) = setup()

  for address in 0..0xff:
    value_to_traces(uint(address), addr_traces)
    clear(traces[CS1])
    let value = uint8(traces_to_value(data_traces))
    set(traces[CS1])

    check value == CharacterRom[address]

proc all_tests* =
  suite "2332 4k x 8 ROM":
    test "reads all CHAROM memory locations": read_all()

when is_main_module:
  all_tests()
