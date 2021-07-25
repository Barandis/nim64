# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import tables
import ../src/nim64/components/link

type
  Traces* = ref object
    byNumber: seq[Trace]
    byName: TableRef[string, Trace]
  
  Device = concept x
    x.items() is Pin

proc `[]`*(tr: Traces, index: int): Trace = tr.byNumber[index]
proc `[]`*(tr: Traces, index: string): Trace = tr.byName[index]

proc deviceTraces*(device: Device): Traces =
  result = Traces(byNumber: @[], byName: newTable[string, Trace]())
  result.byNumber.add(nil)

  for pin in device:
    let trace = newTrace(pin)
    result.byNumber.add(trace)
    result.byName[pin.name] = trace

proc valueToTraces*(value: uint, traces: seq[Trace]) =
  for i, trace in traces:
    setLevel trace, float(value shr i and 1)

proc tracesToValue*(traces: seq[Trace]): uint =
  for i, trace in traces:
    result = result or uint(level trace) shl i
