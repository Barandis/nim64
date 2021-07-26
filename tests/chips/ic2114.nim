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

proc fillMemory(traces: Traces, addrTraces: seq[Trace], dataTraces: seq[Trace]) =
  for address in 0..0x3ff:
    let value = address and 0b1111
    valueToTraces uint address, addrTraces
    valueToTraces uint value, dataTraces

    clear traces[WE]
    clear traces[CS]
    set traces[CS]
    set traces[WE]

proc setup: (Ic2114, Traces, seq[Trace], seq[Trace]) =
  let chip = newIc2114()
  let traces = deviceTraces chip

  set traces[CS]
  set traces[WE]

  let addrTraces = map(toSeq 0..9, proc (i: int): Trace = traces[&"A{i}"])
  let dataTraces = map(toSeq 0..3, proc (i: int): Trace = traces[&"D{i}"])  

  result = (chip, traces, addrTraces, dataTraces)

proc readWriteAll =
  let (_, traces, addrTraces, dataTraces) = setup()
  fillMemory traces, addrTraces, dataTraces

  for address in 0..0x3ff:
    let uaddr = uint address
    let expected = uaddr and 0b1111

    valueToTraces uaddr, addrTraces
    clear traces[CS]
    let value = tracesToValue dataTraces
    set traces[CS]

    check value == expected

proc allTests* =
  suite "2114 1k x 4-bit static RAM":
    test "writes to and reads from all locations": readWriteAll()

when isMainModule:
  allTests()  
