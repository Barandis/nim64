# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import tables
import ../src/nim64/components/link

type
  Traces* = ref object
    by_number: seq[Trace]
    by_name: TableRef[string, Trace]

  Device* = concept x
    x.items() is Pin

proc `[]`*(tr: Traces, index: int): Trace = tr.by_number[index]
proc `[]`*(tr: Traces, index: string): Trace = tr.by_name[index]

proc device_traces*(device: Device): Traces =
  result = Traces(by_number: @[], by_name: new_table[string, Trace]())
  result.by_number.add(nil)

  for pin in device:
    let trace = new_trace(pin)
    result.by_number.add(trace)
    result.by_name[pin.name] = trace

proc value_to_traces*(value: uint, traces: seq[Trace]) =
  for i, trace in traces:
    set_level trace, float(value shr i and 1)

proc traces_to_value*(traces: seq[Trace]): uint =
  for i, trace in traces:
    result = result or uint(level trace) shl i
