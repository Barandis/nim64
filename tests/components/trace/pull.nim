# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../../src/nim64/components/link
import unittest

proc upInitial* =
  let t = newTrace().pullUp()
  check highp(t)

proc upInput* =
  let p = newPin(1, "A", Output)
  let t = newTrace(p).pullUp()

  clear(p)
  check lowp(t)
  setMode(p, Input)
  check highp(t)

proc upNoOutput* =
  let p = newPin(1, "A", Input)
  let t = newTrace(p).pullUp()
  check highp(t)

proc upHighOutput* =
  let p1 = newPin(1, "A", Output).set()
  let p2 = newPin(2, "B", Output).clear()
  let t = newTrace(p1, p2).pullUp()
  check highp(t)

proc upLowOutput* =
  let p1 = newPin(1, "A", Output).clear()
  let p2 = newPin(2, "B", Output).clear()
  let t = newTrace(p1, p2).pullUp()
  check lowp(t)

proc upFloatOutput* =
  let p1 = newPin(1, "A", Output).tri()
  let p2 = newPin(2, "B", Output).tri()
  let t = newTrace(p1, p2).pullUp()
  check highp(t)

proc downInitial* =
  let t = newTrace().pullDown()
  check lowp(t)

proc downInput* =
  let p = newPin(1, "A", Output)
  let t = newTrace(p).pullDown()

  set(p)
  check highp(t)
  setMode(p, Input)
  check lowp(t)

proc downNoOutput* =
  let p = newPin(1, "A", Input)
  let t = newTrace(p).pullDown()
  check lowp(t)

proc downHighOutput* =
  let p1 = newPin(1, "A", Output).set()
  let p2 = newPin(2, "B", Output).clear()
  let t = newTrace(p1, p2).pullDown()
  check highp(t)

proc downLowOutput* =
  let p1 = newPin(1, "A", Output).clear()
  let p2 = newPin(2, "B", Output).clear()
  let t = newTrace(p1, p2).pullDown()
  check lowp(t)

proc downFloatOutput* =
  let p1 = newPin(1, "A", Output).tri()
  let p2 = newPin(2, "B", Output).tri()
  let t = newTrace(p1, p2).pullDown()
  check lowp(t)

proc offInitial* =
  let t = newTrace().pullOff()
  check trip(t)

proc offInput* =
  let p = newPin(1, "A", Output)
  let t = newTrace(p).pullOff()

  set(p)
  check highp(t)
  setMode(p, Input)
  check trip(t)

proc offNoOutput* =
  let p = newPin(1, "A", Input)
  let t = newTrace(p).pullOff()
  check trip(t)

proc offHighOutput* =
  let p1 = newPin(1, "A", Output).set()
  let p2 = newPin(2, "B", Output).clear()
  let t = newTrace(p1, p2).pullOff()
  check highp(t)

proc offLowOutput* =
  let p1 = newPin(1, "A", Output).clear()
  let p2 = newPin(2, "B", Output).clear()
  let t = newTrace(p1, p2).pullOff()
  check lowp(t)

proc offFloatOutput* =
  let p1 = newPin(1, "A", Output).tri()
  let p2 = newPin(2, "B", Output).tri()
  let t = newTrace(p1, p2).pullOff()
  check trip(t)
