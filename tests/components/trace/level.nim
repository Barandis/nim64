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
  
  setLevel(t, -0.35)
  check level(t) == -0.35

proc directIn* =
  let p = newPin(1, "A", Input)
  let t = newTrace(p)

  set(t)
  check highp(t)
  clear(t)
  check lowp(t)
  tri(t)
  check trip(t)
  setLevel(t, -0.35)
  check level(t) == -0.35

proc directOutHigh*() =
  let p1 = newPin(1, "A", Output).set()
  let p2 = newPin(2, "B", Output).clear()
  let t = newTrace(p1, p2)

  set(t)
  check highp(t)
  clear(t)
  check highp(t)
  tri(t)
  check highp(t)
  setLevel(t, -0.35)
  check highp(t)

proc directOutLow* =
  let p1 = newPin(1, "A", Output).clear()
  let p2 = newPin(2, "B", Output).clear()
  let t = newTrace(p1, p2)

  set(t)
  check lowp(t)
  clear(t)
  check lowp(t)
  tri(t)
  check lowp(t)
  setLevel(t, -0.35)
  check level(t) == 0

proc directOutFloat* =
  let p1 = newPin(1, "A", Output).tri()
  let p2 = newPin(2, "B", Output).tri()
  let t = newTrace(p1, p2)

  set(t)
  check highp(t)
  clear(t)
  check lowp(t)
  tri(t)
  check trip(t)
  setLevel(t, -0.35)
  check level(t) == -0.35

proc indirectUnc* =
  let p = newPin(1, "A")
  let t = newTrace(p).clear()

  set(p)
  check:
    lowp(t)
    highp(p)

proc indirectIn* =
  let p = newPin(1, "A", Input)
  let t = newTrace(p).clear()

  set(p)
  check:
    lowp(t)
    lowp(p)

proc indirectOut* =
  let p = newPin(1, "A", Output)
  let t = newTrace(p).clear()

  set(p)
  check:
    highp(t)
    highp(p)

proc indirectBidi* =
  let p = newPin(1, "A", Bidi)
  let t = newTrace(p).clear()

  set(p)
  check:
    highp(t)
    highp(p)
  
  tri(t)
  check:
    trip(t)
    trip(p)

proc indirectOutHigh* =
  let p1 = newPin(1, "A", Output)
  let p2 = newPin(2, "B", Output).set()
  let p3 = newPin(3, "C", Output).set()
  let t = newTrace(p1, p2, p3)

  clear(p1)
  check highp(t)

proc indirectOutLow* =
  let p1 = newPin(1, "A", Output)
  let p2 = newPin(2, "B", Output).clear()
  let p3 = newPin(3, "C", Output).clear()
  let t = newTrace(p1, p2, p3)

  clear(p1)
  check lowp(t)
