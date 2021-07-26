# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

from math import classify, fcNan
import ../../../src/nim64/components/link
import unittest

proc isNaN(n: float): bool {.inline.} = n.classify == fcNan

proc functions =
  let pin = newPin(1, "A", Input)

  tri(pin)
  check:
    level(pin).isNaN
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
  let pin = newPin(1, "A", Input)

  pin.tri()
  check:
    pin.level.isNaN
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
  let p = newPin(1, "A", Unconnected)
  let t = newTrace(p)

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
  let p = newPin(1, "A", Input)
  let t = newTrace(p)

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
  let p = newPin(1, "A", Output)
  let t = newTrace(p)

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
  let p = newPin(1, "A", Bidi)
  let t = newTrace(p)

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

proc toggleHigh =
  let p = newPin(1, "A")
  p.clear()
  p.toggle()
  check p.level == 1

  p.level = -0.35
  p.toggle()
  check p.level == 1

proc toggleLow =
  let p = newPin(1, "A")
  p.set()
  p.toggle()
  check p.level == 0

  p.level = 1729
  p.toggle()
  check p.level == 0

proc toggleTri =
  let p = newPin(1, "A")
  p.tri()
  p.toggle()
  check p.level.isNaN

proc allTests* =
  suite "Pin level":
    test "pin levels without trace, proc syntax": functions()
    test "pin levels without trace, method syntax": methods()
    test "unconnected pin levels affected by setting, unaffected by trace": unconnected()
    test "input pin levels unaffected by setting, affected by trace": input()
    test "output pin levels affected by setting, set trace level": output()
    test "bidi pin levels affected by setting, affected by trace": bidi()
    test "toggling a low pin changes it to high": toggleHigh()
    test "toggling a high pin changes it to low": toggleLow()
    test "toggling tri-state has no effect": toggleTri()

when isMainModule:
  allTests()
