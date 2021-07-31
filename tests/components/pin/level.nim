# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../../src/nim64/utils
import ../../../src/nim64/components/link
import unittest

proc functions =
  let pin = new_pin(1, "A", Input)

  tri(pin)
  check:
    nanp(level(pin))
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
    nanp(pin.level)
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

  set(t)
  check:
    trip(p)
    highp(t)
  
  set(p)
  check:
    highp(p)
    highp(t)

  clear(p)
  check:
    lowp(p)
    highp(t)
  
  set_level(p, -0.35)
  check:
    level(p) == -0.35
    highp(t)
  
  tri(p)
  check:
    trip(p)
    highp(t)

proc input =
  let p = new_pin(1, "A", Input)
  let t = new_trace(p)

  set(t)
  check:
    highp(p)
    highp(t)
  
  set(p)
  check:
    highp(p)
    highp(t)

  clear(p)
  check:
    highp(p)
    highp(t)
  
  set_level(p, -0.35)
  check:
    highp(p)
    highp(t)
  
  tri(p)
  check:
    highp(p)
    highp(t)

proc output =
  let p = new_pin(1, "A", Output)
  let t = new_trace(p)

  set(t)
  check:
    trip(p)
    highp(t)
  
  set(p)
  check:
    highp(p)
    highp(t)

  clear(p)
  check:
    lowp(p)
    lowp(t)
  
  set_level(p, -0.35)
  check:
    level(p) == -0.35
    level(t) == -0.35
  
  tri(p)
  check:
    trip(p)
    trip(t)

proc bidi =
  let p = new_pin(1, "A", Bidi)
  let t = new_trace(p)

  set(t)
  check:
    highp(p)
    highp(t)
  
  set(p)
  check:
    highp(p)
    highp(t)

  clear(p)
  check:
    lowp(p)
    lowp(t)
  
  set_level(p, -0.35)
  check:
    level(p) == -0.35
    level(t) == -0.35
  
  tri(p)
  check:
    trip(p)
    trip(t)

proc toggle_high =
  let p = new_pin(1, "A")
  clear(p)
  toggle(p)
  check level(p) == 1

  set_level(p, -0.35)
  toggle(p)
  check level(p) == 1

proc toggle_low =
  let p = new_pin(1, "A")
  set(p)
  toggle(p)
  check level(p) == 0

  set_level(p, 1729)
  toggle(p)
  check level(p) == 0

proc toggle_tri =
  let p = new_pin(1, "A")
  tri(p)
  toggle(p)
  check nanp(level(p))

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
