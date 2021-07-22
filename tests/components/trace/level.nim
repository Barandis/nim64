# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../../src/nim64/components/link
import unittest

proc directUnc* =
  let t = newTrace()
  set(t)
  check:
    high(t)
    not low(t)
    not floating(t)

  clear(t)
  check:
    not high(t)
    low(t)
    not floating(t)
  
  float(t)
  check:
    not high(t)
    not low(t)
    floating(t)
  
  setLevel(t, -0.35)
  check level(t) == -0.35

proc directIn* =
  let p = newPin(1, "A", Input)
  let t = newTrace(p)

  set(t)
  check high(t)
  clear(t)
  check low(t)
  float(t)
  check floating(t)
  setLevel(t, -0.35)
  check level(t) == -0.35

proc directOutHigh*() =
  let p1 = newPin(1, "A", Output).set()
  let p2 = newPin(2, "B", Output).clear()
  let t = newTrace(p1, p2)

  set(t)
  check high(t)
  clear(t)
  check high(t)
  float(t)
  check high(t)
  setLevel(t, -0.35)
  check high(t)

proc directOutLow* =
  let p1 = newPin(1, "A", Output).clear()
  let p2 = newPin(2, "B", Output).clear()
  let t = newTrace(p1, p2)

  set(t)
  check low(t)
  clear(t)
  check low(t)
  float(t)
  check low(t)
  setLevel(t, -0.35)
  check level(t) == 0

proc directOutFloat* =
  let p1 = newPin(1, "A", Output).float()
  let p2 = newPin(2, "B", Output).float()
  let t = newTrace(p1, p2)

  set(t)
  check high(t)
  clear(t)
  check low(t)
  float(t)
  check floating(t)
  setLevel(t, -0.35)
  check level(t) == -0.35

proc indirectUnc* =
  let p = newPin(1, "A")
  let t = newTrace(p).clear()

  set(p)
  check:
    low(t)
    high(p)

proc indirectIn* =
  let p = newPin(1, "A", Input)
  let t = newTrace(p).clear()

  set(p)
  check:
    low(t)
    low(p)

proc indirectOut* =
  let p = newPin(1, "A", Output)
  let t = newTrace(p).clear()

  set(p)
  check:
    high(t)
    high(p)

proc indirectBidi* =
  let p = newPin(1, "A", Bidi)
  let t = newTrace(p).clear()

  set(p)
  check:
    high(t)
    high(p)
  
  float(t)
  check:
    floating(t)
    floating(p)

proc indirectOutHigh* =
  let p1 = newPin(1, "A", Output)
  let p2 = newPin(2, "B", Output).set()
  let p3 = newPin(3, "C", Output).set()
  let t = newTrace(p1, p2, p3)

  clear(p1)
  check high(t)

proc indirectOutLow* =
  let p1 = newPin(1, "A", Output)
  let p2 = newPin(2, "B", Output).clear()
  let p3 = newPin(3, "C", Output).clear()
  let t = newTrace(p1, p2, p3)

  clear(p1)
  check low(t)
