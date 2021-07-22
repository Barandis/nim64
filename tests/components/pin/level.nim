# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

from math import classify, fcNan
import ../../../src/nim64/components/link
import unittest

proc isNaN(n: float): bool {.inline.} = n.classify == fcNan

proc functions* =
  let pin = newPin(1, "A", Input)

  float(pin)
  check:
    level(pin).isNaN
    not high(pin)
    not low(pin)
    floating(pin)

  set(pin)
  check:
    level(pin) == 1
    high(pin)
    not low(pin)
    not floating(pin)
  
  clear(pin)
  check:
    level(pin) == 0
    not high(pin)
    low(pin)
    not floating(pin)
  
  setLevel(pin, -0.35)
  check:
    level(pin) == -0.35
    not high(pin)
    low(pin)
    not floating(pin)

proc methods* =
  let pin = newPin(1, "A", Input)

  pin.float()
  check:
    pin.level.isNaN
    not pin.high
    not pin.low
    pin.floating
  
  pin.set()
  check:
    pin.level == 1
    pin.high
    not pin.low
    not pin.floating
  
  pin.clear()
  check:
    pin.level == 0
    not pin.high
    pin.low
    not pin.floating
  
  pin.level = -0.35
  check:
    pin.level == -0.35
    not pin.high
    pin.low
    not pin.floating

proc operators* =
  let pin = newPin(1, "A", Input)

  ~pin
  check:
    pin.level.isNaN
    not pin.high
    not pin.low
    pin.floating
  
  +pin
  check:
    pin.level == 1
    pin.high
    not pin.low
    not pin.floating
  
  -pin
  check:
    pin.level == 0
    not pin.high
    pin.low
    not pin.floating
  
  pin.level = -0.35
  check:
    pin.level == -0.35
    not pin.high
    pin.low
    not pin.floating

proc unconnected* =
  let p = newPin(1, "A", Unconnected)
  let t = newTrace(p)

  t.set()
  check:
    p.floating
    t.high
  
  p.set()
  check:
    p.high
    t.high

  p.clear()
  check:
    p.low
    t.high
  
  p.level = -0.35
  check:
    p.level == -0.35
    t.high
  
  p.float()
  check:
    p.floating
    t.high

proc input* =
  let p = newPin(1, "A", Input)
  let t = newTrace(p)

  t.set()
  check:
    p.high
    t.high
  
  p.set()
  check:
    p.high
    t.high

  p.clear()
  check:
    p.high
    t.high
  
  p.level = -0.35
  check:
    p.high
    t.high
  
  p.float()
  check:
    p.high
    t.high

proc output* =
  let p = newPin(1, "A", Output)
  let t = newTrace(p)

  t.set()
  check:
    p.floating
    t.high
  
  p.set()
  check:
    p.high
    t.high

  p.clear()
  check:
    p.low
    t.low
  
  p.level = -0.35
  check:
    p.level == -0.35
    t.level == -0.35
  
  p.float()
  check:
    p.floating
    t.floating

proc bidi* =
  let p = newPin(1, "A", Bidi)
  let t = newTrace(p)

  t.set()
  check:
    p.high
    t.high
  
  p.set()
  check:
    p.high
    t.high

  p.clear()
  check:
    p.low
    t.low
  
  p.level = -0.35
  check:
    p.level == -0.35
    t.level == -0.35
  
  p.float()
  check:
    p.floating
    t.floating

proc toggleHigh* =
  let p = newPin(1, "A")
  p.clear()
  p.toggle()
  check p.level == 1

  p.level = -0.35
  p.toggle()
  check p.level == 1

proc toggleLow* =
  let p = newPin(1, "A")
  p.set()
  p.toggle()
  check p.level == 0

  p.level = 1729
  p.toggle()
  check p.level == 0

proc toggleFloating* =
  let p = newPin(1, "A")
  p.float()
  p.toggle()
  check p.level.isNaN
