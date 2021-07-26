# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../../src/nim64/components/link
import unittest

proc direct_unc =
  let t = new_trace()
  set(t)
  check:
    highp(t)
    not lowp(t)
    not trip(t)

  clear(t)
  check:
    not highp(t)
    lowp(t)
    not trip(t)
  
  tri(t)
  check:
    not highp(t)
    not lowp(t)
    trip(t)
  
  set_level(t, -0.35)
  check level(t) == -0.35

proc direct_in =
  let p = new_pin(1, "A", Input)
  let t = new_trace(p)

  set(t)
  check highp(t)
  clear(t)
  check lowp(t)
  tri(t)
  check trip(t)
  set_level(t, -0.35)
  check level(t) == -0.35

proc direct_out_high =
  let p1 = new_pin(1, "A", Output).set()
  let p2 = new_pin(2, "B", Output).clear()
  let t = new_trace(p1, p2)

  set(t)
  check highp(t)
  clear(t)
  check highp(t)
  tri(t)
  check highp(t)
  set_level(t, -0.35)
  check highp(t)

proc direct_out_low =
  let p1 = new_pin(1, "A", Output).clear()
  let p2 = new_pin(2, "B", Output).clear()
  let t = new_trace(p1, p2)

  set(t)
  check lowp(t)
  clear(t)
  check lowp(t)
  tri(t)
  check lowp(t)
  set_level(t, -0.35)
  check level(t) == 0

proc direct_out_tri =
  let p1 = new_pin(1, "A", Output).tri()
  let p2 = new_pin(2, "B", Output).tri()
  let t = new_trace(p1, p2)

  set(t)
  check highp(t)
  clear(t)
  check lowp(t)
  tri(t)
  check trip(t)
  set_level(t, -0.35)
  check level(t) == -0.35

proc indirect_unc =
  let p = new_pin(1, "A")
  let t = new_trace(p).clear()

  set(p)
  check:
    lowp(t)
    highp(p)

proc indirect_in =
  let p = new_pin(1, "A", Input)
  let t = new_trace(p).clear()

  set(p)
  check:
    lowp(t)
    lowp(p)

proc indirect_out =
  let p = new_pin(1, "A", Output)
  let t = new_trace(p).clear()

  set(p)
  check:
    highp(t)
    highp(p)

proc indirect_bidi =
  let p = new_pin(1, "A", Bidi)
  let t = new_trace(p).clear()

  set(p)
  check:
    highp(t)
    highp(p)
  
  tri(t)
  check:
    trip(t)
    trip(p)

proc indirect_out_high =
  let p1 = new_pin(1, "A", Output)
  let p2 = new_pin(2, "B", Output).set()
  let p3 = new_pin(3, "C", Output).set()
  let t = new_trace(p1, p2, p3)

  clear(p1)
  check highp(t)

proc indirect_out_low =
  let p1 = new_pin(1, "A", Output)
  let p2 = new_pin(2, "B", Output).clear()
  let p3 = new_pin(3, "C", Output).clear()
  let t = new_trace(p1, p2, p3)

  clear(p1)
  check lowp(t)

proc all_tests* =
  suite "Trace level":
    test "trace affected by direct set with unconnected pins only": direct_unc()
    test "trace affected by direct set when connected to input pins only": direct_in()
    test "trace unaffected by direct set when connected to high output pins": direct_out_high()
    test "trace unaffected by direct set when connected to low output pins": direct_out_low()
    test "trace affected by direct set when no leveled output pins connected": direct_out_tri()
    test "trace unaffected by setting an unconnected pin": indirect_unc()
    test "trace unaffected by setting a connected input pin": indirect_in()
    test "trace affected by setting a connected output pin": indirect_out()
    test "trace affected by setting a connected bidi pin": indirect_bidi()
    test "trace unaffected if high output set low with other high outputs": indirect_out_high()
    test "trace affected if high output set low with no other high outputs": indirect_out_low()

when is_main_module:
  all_tests()
