# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import sequtils
import strformat
import ../../../src/nim64/chips/ic6526
import ../../../src/nim64/components/link
import ../../utils as test_utils

var chip: Ic6526
var traces: Traces
var addr_traces, data_traces, pa_traces, pb_traces: seq[Trace]

proc setup =
  chip = new_ic6526()
  traces = device_traces(chip)

  addr_traces = map(to_seq(0..3), proc (i: int): Trace = traces[&"A{i}"])
  data_traces = map(to_seq(0..7), proc (i: int): Trace = traces[&"D{i}"])
  pa_traces = map(to_seq(0..7), proc (i: int): Trace = traces[&"PA{i}"])
  pb_traces = map(to_seq(0..7), proc (i: int): Trace = traces[&"PB{i}"])

  set(traces[R_W])
  set(traces[CS])
  set(traces[RES])
  set(traces[FLAG])

proc write_register(register: uint, value: uint8) =
  value_to_traces(value, data_traces)
  value_to_traces(register, addr_traces)
  clear(traces[R_W])
  clear(traces[CS])
  set(traces[CS])
  set(traces[R_W])

proc read_register(register: uint): uint8 =
  value_to_traces(register, addr_traces)
  clear(traces[CS])
  result = uint8(traces_to_value(data_traces))
  set(traces[CS])
