# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

from math import classify, fcNan
import ../../../src/nim64/components/link
import unittest

proc nanp(n: float): bool {.inline.} = n.classify == fcNan

proc functions =
  let pin = new_pin(1, "A", Input)

  tri(pin)
  check:
    nanp level(pin)
    not highp(pin)
    not lowp(pin)
    trip(pin)

  set(pin)
  check:
    level(pin) == 1
    highp(pin)
    not lowp(pin)
    not trip(pin)
  
  clear(pin)
  check:
    level(pin) == 0
    not highp(pin)
    lowp(pin)
    not trip(pin)
  
  setLevel(pin, -0.35)
  check:
    level(pin) == -0.35
    not highp(pin)
    lowp(pin)
    not trip(pin)

proc methods =
  let pin = new_pin(1, "A", Input)

  pin.tri()
  check:
    pin.level.nanp
    not pin.highp
    not pin.lowp
    pin.trip
  
  pin.set()
  check:
    pin.level == 1
    pin.highp
    not pin.lowp
    not pin.trip
  
  pin.clear()
  check:
    pin.level == 0
    not pin.highp
    pin.lowp
    not pin.trip
  
  pin.level = -0.35
  check:
    pin.level == -0.35
    not pin.highp
    pin.lowp
    not pin.trip

proc unconnected =
  let p = new_pin(1, "A", Unconnected)
  let t = new_trace(p)

  t.set()
  check:
    p.trip
    t.highp
  
  p.set()
  check:
    p.highp
    t.highp

  p.clear()
  check:
    p.lowp
    t.highp
  
  p.level = -0.35
  check:
    p.level == -0.35
    t.highp
  
  p.tri()
  check:
    p.trip
    t.highp

proc input =
  let p = new_pin(1, "A", Input)
  let t = new_trace(p)

  t.set()
  check:
    p.highp
    t.highp
  
  p.set()
  check:
    p.highp
    t.highp

  p.clear()
  check:
    p.highp
    t.highp
  
  p.level = -0.35
  check:
    p.highp
    t.highp
  
  p.tri()
  check:
    p.highp
    t.highp

proc output =
  let p = new_pin(1, "A", Output)
  let t = new_trace(p)

  t.set()
  check:
    p.trip
    t.highp
  
  p.set()
  check:
    p.highp
    t.highp

  p.clear()
  check:
    p.lowp
    t.lowp
  
  p.level = -0.35
  check:
    p.level == -0.35
    t.level == -0.35
  
  p.tri()
  check:
    p.trip
    t.trip

proc bidi =
  let p = new_pin(1, "A", Bidi)
  let t = new_trace(p)

  t.set()
  check:
    p.highp
    t.highp
  
  p.set()
  check:
    p.highp
    t.highp

  p.clear()
  check:
    p.lowp
    t.lowp
  
  p.level = -0.35
  check:
    p.level == -0.35
    t.level == -0.35
  
  p.tri()
  check:
    p.trip
    t.trip

proc toggle_high =
  let p = new_pin(1, "A")
  p.clear()
  p.toggle()
  check p.level == 1

  p.level = -0.35
  p.toggle()
  check p.level == 1

proc toggle_low =
  let p = new_pin(1, "A")
  p.set()
  p.toggle()
  check p.level == 0

  p.level = 1729
  p.toggle()
  check p.level == 0

proc toggle_tri =
  let p = new_pin(1, "A")
  p.tri()
  p.toggle()
  check nanp p.level

proc all_tests* =
  suite "Pin level":
    test "pin levels without trace, proc syntax": functions()
    test "pin levels without trace, method syntax": methods()
    test "unconnected pin levels affected by setting, unaffected by trace": unconnected()
    test "input pin levels unaffected by setting, affected by trace": input()
    test "output pin levels affected by setting, set trace level": output()
    test "bidi pin levels affected by setting, affected by trace": bidi()
    test "toggling a low pin changes it to high": toggle_high()
    test "toggling a high pin changes it to low": toggle_low()
    test "toggling tri-state has no effect": toggle_tri()

when is_main_module:
  all_tests()
