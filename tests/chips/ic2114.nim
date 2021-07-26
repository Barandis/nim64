# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import sequtils
import strformat

import ../utils
import ../../src/nim64/chips/ic2114
import ../../src/nim64/components/link

proc fill_memory(traces: Traces, addr_traces: seq[Trace], data_traces: seq[Trace]) =
  for address in 0..0x3ff:
    let value = address and 0b1111
    valueToTraces uint address, addr_traces
    valueToTraces uint value, data_traces

    clear traces[WE]
    clear traces[CS]
    set traces[CS]
    set traces[WE]

proc setup: (Ic2114, Traces, seq[Trace], seq[Trace]) =
  let chip = new_ic2114()
  let traces = device_traces chip

  set traces[CS]
  set traces[WE]

  let addr_traces = map(to_seq 0..9, proc (i: int): Trace = traces[&"A{i}"])
  let data_traces = map(to_seq 0..3, proc (i: int): Trace = traces[&"D{i}"])  

  result = (chip, traces, addr_traces, data_traces)

proc read_write_all =
  let (_, traces, addr_traces, data_traces) = setup()
  fill_memory traces, addr_traces, data_traces

  for address in 0..0x3ff:
    let uaddr = uint address
    let expected = uaddr and 0b1111

    value_to_traces uaddr, addr_traces
    clear traces[CS]
    let value = traces_to_value dataTraces
    set traces[CS]

    check value == expected

proc all_tests* =
  suite "2114 1k x 4-bit static RAM":
    test "writes to and reads from all locations": read_write_all()

when is_main_module:
  all_tests()  
