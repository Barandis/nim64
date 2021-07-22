# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../../src/nim64/components/link
import unittest

proc upInitial* =
  let p = newPin(1, "A", Output).pullUp()
  check high(p)

proc upUnconnected* =
  let p = newPin(1, "A", Unconnected).pullUp()
  clear(p)
  check low(p)
  float(p)
  check high(p)

proc upInput* =
  let p = newPin(1, "A", Input).pullUp()
  let t = newTrace(p)

  clear(t)
  check low(p)
  float(t)
  check high(p)

proc upOutput* =
  let p = newPin(1, "A", Output).pullUp()
  let t = newTrace(p)

  clear(p)
  check low(t)
  float(p)
  check high(t)

proc upBidi* =
  let p = newPin(1, "A", Bidi).pullUp()
  let t = newTrace(p)

  clear(p)
  check low(t)
  float(p)
  check high(t)

proc upAfter* =
  let p = newPin(1, "A")
  check floating(p)
  pullUp(p)
  check high(p)

proc downInitial* =
  let p = newPin(1, "A", Output).pullDown()
  check low(p)

proc downUnconnected* =
  let p = newPin(1, "A", Unconnected).pullDown()
  set(p)
  check high(p)
  float(p)
  check low(p)

proc downInput* =
  let p = newPin(1, "A", Input).pullDown()
  let t = newTrace(p)

  set(t)
  check high(p)
  float(t)
  check low(p)

proc downOutput* =
  let p = newPin(1, "A", Output).pullDown()
  let t = newTrace(p)

  set(p)
  check high(t)
  float(p)
  check low(t)

proc downBidi* =
  let p = newPin(1, "A", Bidi).pullDown()
  let t = newTrace(p)

  set(p)
  check high(t)
  float(p)
  check low(t)

proc downAfter* =
  let p = newPin(1, "A")
  check floating(p)
  pullDown(p)
  check low(p)

proc offInitial* =
  let p = newPin(1, "A").pullOff()
  check floating(p)

proc offAfterUp* =
  let p = newPin(1, "A").pullUp()
  float(p)
  check high(p)

  pullOff(p)
  float(p)
  check floating(p)


proc offAfterDown* =
  let p = newPin(1, "A").pullDown()
  float(p)
  check low(p)

  pullOff(p)
  float(p)
  check floating(p)