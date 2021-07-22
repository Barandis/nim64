# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../../src/nim64/components/link
import unittest

proc upInitial* =
  let t = newTrace().pullUp()
  check high(t)

proc upInput* =
  let p = newPin(1, "A", Output)
  let t = newTrace(p).pullUp()

  clear(p)
  check low(t)
  setMode(p, Input)
  check high(t)

proc upNoOutput* =
  let p = newPin(1, "A", Input)
  let t = newTrace(p).pullUp()
  check high(t)

proc upHighOutput* =
  let p1 = newPin(1, "A", Output).set()
  let p2 = newPin(2, "B", Output).clear()
  let t = newTrace(p1, p2).pullUp()
  check high(t)

proc upLowOutput* =
  let p1 = newPin(1, "A", Output).clear()
  let p2 = newPin(2, "B", Output).clear()
  let t = newTrace(p1, p2).pullUp()
  check low(t)

proc upFloatOutput* =
  let p1 = newPin(1, "A", Output).float()
  let p2 = newPin(2, "B", Output).float()
  let t = newTrace(p1, p2).pullUp()
  check high(t)

proc downInitial* =
  let t = newTrace().pullDown()
  check low(t)

proc downInput* =
  let p = newPin(1, "A", Output)
  let t = newTrace(p).pullDown()

  set(p)
  check high(t)
  setMode(p, Input)
  check low(t)

proc downNoOutput* =
  let p = newPin(1, "A", Input)
  let t = newTrace(p).pullDown()
  check low(t)

proc downHighOutput* =
  let p1 = newPin(1, "A", Output).set()
  let p2 = newPin(2, "B", Output).clear()
  let t = newTrace(p1, p2).pullDown()
  check high(t)

proc downLowOutput* =
  let p1 = newPin(1, "A", Output).clear()
  let p2 = newPin(2, "B", Output).clear()
  let t = newTrace(p1, p2).pullDown()
  check low(t)

proc downFloatOutput* =
  let p1 = newPin(1, "A", Output).float()
  let p2 = newPin(2, "B", Output).float()
  let t = newTrace(p1, p2).pullDown()
  check low(t)

proc offInitial* =
  let t = newTrace().pullOff()
  check floating(t)

proc offInput* =
  let p = newPin(1, "A", Output)
  let t = newTrace(p).pullOff()

  set(p)
  check high(t)
  setMode(p, Input)
  check floating(t)

proc offNoOutput* =
  let p = newPin(1, "A", Input)
  let t = newTrace(p).pullOff()
  check floating(t)

proc offHighOutput* =
  let p1 = newPin(1, "A", Output).set()
  let p2 = newPin(2, "B", Output).clear()
  let t = newTrace(p1, p2).pullOff()
  check high(t)

proc offLowOutput* =
  let p1 = newPin(1, "A", Output).clear()
  let p2 = newPin(2, "B", Output).clear()
  let t = newTrace(p1, p2).pullOff()
  check low(t)

proc offFloatOutput* =
  let p1 = newPin(1, "A", Output).float()
  let p2 = newPin(2, "B", Output).float()
  let t = newTrace(p1, p2).pullOff()
  check floating(t)
