# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import sequtils
import strformat

import ../utils
import ../../src/nim64/chips/ic4164
import ../../src/nim64/components/link

proc setup: (Ic4164, Traces, seq[Trace]) =
  let chip = new_ic4164()
  let traces = device_traces(chip)

  set(traces[WE])
  set(traces[CAS])
  set(traces[RAS])

  let addr_traces = map(to_seq(0..7), proc (i: int): Trace = traces[&"A{i}"])  

  result = (chip, traces, addr_traces)

proc read_mode =
  let (_, traces, addr_traces) = setup()

  value_to_traces(0, addr_traces)

  clear(traces[RAS])
  clear(traces[CAS])
  # data at location 0x0000, Q should have the data on it
  check lowp(traces[Q])

  set(traces[CAS])
  set(traces[RAS])
  # After the end of read mode, Q should be tri-stated
  check trip(traces[Q])

proc write_mode =
  let (_, traces, addr_traces) = setup()

  value_to_traces(0, addr_traces)
  clear(traces[D])
  
  clear(traces[RAS])
  clear(traces[WE])
  clear(traces[CAS])
  # Q should be tri-stated during write
  check trip(traces[Q])

  set(traces[CAS])
  set(traces[WE])
  set(traces[CAS])
  # Q should still be tri-stated
  check trip(traces[Q])

proc rmw_mode =
  let (_, traces, addr_traces) = setup()

  value_to_traces(0, addr_traces)
  clear(traces[D])

  clear(traces[RAS])
  clear(traces[CAS])
  clear(traces[WE])
  # RMW mode because CAS went low before WE, Q should be enabled and reading 0x0000
  check lowp(traces[Q])

  set(traces[WE])
  set(traces[CAS])
  set(traces[RAS])
  # Q should still be tri-stated
  check trip(traces[Q])

proc bit_value(row: uint, col: uint): float =
  let bit = col and 0b00011111
  result = float((row shr bit) and 1)

proc read_write =
  let (_, traces, addr_traces) = setup()

  # write all 65,536 locations with a bit determined by the top 8 address bits and the
  # bottom 8 address bits
  for address in 0..0xffff:
    let row = uint(address and 0xff00) shr 8
    let col = uint(address and 0x00ff)

    value_to_traces(row, addr_traces)
    clear(traces[RAS])

    value_to_traces(col, addr_traces)
    clear(traces[CAS])

    set_level(traces[D], bit_value(row, col))
    clear(traces[WE])

    set(traces[RAS])
    set(traces[CAS])
    set(traces[WE])
  
  # read all of those locations one at a time and confirm that each bit is the correct
  # value
  for address in 0..0xffff:
    let row = uint(address and 0xff00) shr 8
    let col = uint(address and 0x00ff)

    value_to_traces(row, addr_traces)
    clear(traces[RAS])

    value_to_traces(col, addr_traces)
    clear(traces[CAS])

    check level(traces[Q]) == bit_value(row, col)

    set(traces[RAS])
    set(traces[CAS])

proc same_page =
  let (_, traces, addr_traces) = setup()

  let row = 0x30u # arbitrary, just the author's age
  value_to_traces(row, addr_traces)
  clear(traces[RAS])

  # write data in all columns in row 0x30 without ever unlatching RAS
  for col in 0u..255u:
    value_to_traces(col, addr_traces)
    clear(traces[CAS])

    set_level(traces[D], bit_value(row, col))
    clear(traces[WE])

    set(traces[CAS])
    set(traces[WE])
  
  # now read that data, again without ever unlatching RAS
  for col in 0u..255u:
    value_to_traces(uint col, addr_traces)
    clear(traces[CAS])

    check level(traces[Q]) == bit_value(row, col)

    set(traces[CAS])

  set traces[RAS]

proc all_tests* =
  suite "4164 64k x 1 bit dynamic RAM":
    test "Q enabled during read mode": read_mode()
    test "Q not enabled during write mode": write_mode()
    test "Q enabled during read-modify-write mode": rmw_mode()
    test "all memory locations written and read": read_write()
    test "reads and writes in the same page without resetting row": same_page()

when is_main_module:
  all_tests()
