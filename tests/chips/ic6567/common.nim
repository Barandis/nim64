# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import sequtils
import strformat
import ../../../src/nim64/chips/ic6567
import ../../../src/nim64/components/link
import ../../utils as test_utils

var chip: Ic6567
var traces: Traces
var addr_traces, addr_mux_traces, data_traces: seq[Trace]

proc setup =
  chip = new_ic6567()
  traces = device_traces(chip)

  addr_mux_traces = map(to_seq(24..29), proc (i: int): Trace = traces[i])
  addr_traces = concat(addr_mux_traces, map(to_seq(6..11), proc (i: int): Trace = traces[&"A{i}"]))
  data_traces = map(to_seq(0..7), proc (i: int): Trace = traces[&"D{i}"])

  set(traces[R_W])
  set(traces[CS])

proc write_register(register: uint, value: uint8) {.used.} =
  value_to_traces(value, data_traces)
  value_to_traces(register, addr_traces)
  clear(traces[R_W])
  clear(traces[CS])
  set(traces[CS])
  set(traces[R_W])

proc read_register(register: uint): uint8 {.used.} =
  value_to_traces(register, addr_traces)
  clear(traces[CS])
  result = uint8(traces_to_value(data_traces))
  set(traces[CS])