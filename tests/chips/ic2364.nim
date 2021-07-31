# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import sequtils
import strformat

import ../utils
import ../../src/nim64/roms/[basic, kernal]
import ../../src/nim64/chips/ic2364
import ../../src/nim64/components/link

proc setup(rom: array[8192, uint8]): (Ic2364, Traces, seq[Trace], seq[Trace]) =
  let chip = new_ic2364(rom)
  let traces = device_traces(chip)

  set(traces[CS])

  let addr_traces = map(toSeq(0..12), proc (i: int): Trace = traces[&"A{i}"])
  let data_traces = map(toSeq(0..7), proc (i: int): Trace = traces[&"D{i}"])

  result = (chip, traces, addr_traces, data_traces)

proc read_basic =
  let (_, traces, addr_traces, data_traces) = setup BasicRom

  for address in 0..0x1ff:
    value_to_traces(uint(address), addr_traces)
    clear(traces[CS])
    let value = uint8(traces_to_value(data_traces))
    set(traces[CS])

    check value == BasicRom[address]

proc read_kernal =
  let (_, traces, addr_traces, data_traces) = setup KernalRom

  for address in 0..0x1ff:
    value_to_traces(uint(address), addr_traces)
    clear(traces[CS])
    let value = uint8(traces_to_value(data_traces))
    set(traces[CS])

    check value == KernalRom[address]

proc all_tests* =
  suite "2364 8k x 8 ROM":
    test "reads all BASIC memory locations": read_basic()
    test "reads all KERNAL memory locations": read_kernal()

when is_main_module:
  all_tests()
