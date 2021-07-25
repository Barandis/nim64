# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import sequtils
import strformat

import ../utils
import ../../src/nim64/roms/basic
import ../../src/nim64/roms/kernal
import ../../src/nim64/chips/ic2364
import ../../src/nim64/components/link

proc setup(rom: array[8192, uint8]): (Ic2364, Traces, seq[Trace], seq[Trace]) =
  let chip = newIc2364 rom
  let traces = deviceTraces chip

  set traces[CS]

  let addrTraces = map(toSeq 0..12, proc (i: int): Trace = traces[&"A{i}"])
  let dataTraces = map(toSeq 0..7, proc (i: int): Trace = traces[&"D{i}"])

  result = (chip, traces, addrTraces, dataTraces)

proc readBasic* =
  let (_, traces, addrTraces, dataTraces) = setup BasicRom

  for address in 0..0x1ff:
    valueToTraces uint address, addrTraces
    clear traces[CS]
    let value = uint8 tracesToValue dataTraces
    set traces[CS]

    check value == BasicRom[address]

proc readKernal* =
  let (_, traces, addrTraces, dataTraces) = setup KernalRom

  for address in 0..0x1ff:
    valueToTraces uint address, addrTraces
    clear traces[CS]
    let value = uint8 tracesToValue dataTraces
    set traces[CS]

    check value == KernalRom[address]

when isMainModule:
  readBasic()
  readKernal()
