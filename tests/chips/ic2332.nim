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
  let chip = newIc2332 CharacterRom
  let traces = deviceTraces chip

  clear traces[CS2]
  set traces[CS1]

  let addrTraces = map(toSeq 0..11, proc (i: int): Trace = traces[&"A{i}"])
  let dataTraces = map(toSeq 0..7, proc (i: int): Trace = traces[&"D{i}"])

  result = (chip, traces, addrTraces, dataTraces)

proc readAll =
  let (_, traces, addrTraces, dataTraces) = setup()

  for address in 0..0xff:
    valueToTraces uint address, addrTraces
    clear traces[CS1]
    let value = uint8 tracesToValue dataTraces
    set traces[CS1]

    check value == CharacterRom[address]

proc allTests* =
  suite "2332 4k x 8 ROM":
    test "reads all CHAROM memory locations": readAll()

when isMainModule:
  allTests()
