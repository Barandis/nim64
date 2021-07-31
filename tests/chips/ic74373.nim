# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import strformat
import unittest
import ../utils
import ../../src/nim64/chips/ic74373
import ../../src/nim64/components/link

proc setup: (Ic74373, Traces) =
  let chip = new_ic74373()
  let traces = device_traces(chip)
  result = (chip, traces)
  clear(traces[OE])

proc pass_on_le_high =
  let (_, traces) = setup()

  set(traces[LE])

  for i in 0..7:
    set(traces[&"D{i}"])
    check highp(traces[&"Q{i}"])
  
    clear(traces[&"D{i}"])
    check lowp(traces[&"Q{i}"])

proc latch_on_le_low =
  let (_, traces) = setup()

  set(traces[LE])

  for i in 0..7:
    set_level(traces[&"D{i}"], float((i + 1) mod 2))
    check level(traces[&"Q{i}"]) == float((i + 1) mod 2)
  
  clear(traces[LE])

  for i in 0..7:
    set(traces[&"D{i}"])
    # Odd outputs remain low even when inputs are high
    check level(traces[&"Q{i}"]) == float((i + 1) mod 2)

    clear(traces[&"D{i}"])
    ## Even inputs remain high even when inputs are low
    check level(traces[&"Q{i}"]) == float((i + 1) mod 2)

proc return_to_pass =
  let (_, traces) = setup()

  set(traces[LE])

  for i in 0..7:
    set_level(traces[&"D{i}"], float((i + 1) mod 2))
  
  clear(traces[LE])

  for i in 0..7:
    # All inputs set high right here
    set(traces[&"D{i}"])
    # LE is low, so we still see the former levels...
    check level(traces[&"Q{i}"]) == float((i + 1) mod 2)
  
  set(traces[LE])

  for i in 0..7:
    # ...until now, when the latch is released and the high inputs pass through
    check highp(traces[&"Q{i}"])

proc tri_on_oe_high =
  let (_, traces) = setup()

  set(traces[LE])

  for i in 0..7:
    set(traces[&"D{i}"])
  
  set(traces[OE])

  for i in 0..7:
    check trip(traces[&"Q{i}"])

  clear traces[OE]

  for i in 0..7:
    check highp(traces[&"Q{i}"])

proc latch_on_oe_high =
  let (_, traces) = setup()

  set(traces[LE])

  for i in 0..7:
    set(traces[&"D{i}"])

  set(traces[OE])

  for i in countup(0, 7, 2):
    clear(traces[&"D{i}"])
  
  clear(traces[LE])
  clear(traces[OE])

  for i in 0..7:
    check level(traces[&"Q{i}"]) == float(i mod 2)

proc all_tests* =
  suite "74373 octal transparent latch":
    test "data passes through when LE is high": pass_on_le_high()
    test "data latches when LE goes low": latch_on_le_low()
    test "data returns to pass through when LE goes high": return_to_pass()
    test "outputs are tri-state on OE high": tri_on_oe_high()
    test "latching still happens when OE is high": latch_on_oe_high()

when is_main_module:
  all_tests()
