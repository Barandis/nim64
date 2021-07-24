# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../../src/nim64/components/link
import unittest

proc upInitial* =
  let p = newPin(1, "A", Output).pullUp()
  check highp(p)

proc upUnconnected* =
  let p = newPin(1, "A", Unconnected).pullUp()
  clear(p)
  check lowp(p)
  float(p)
  check highp(p)

proc upInput* =
  let p = newPin(1, "A", Input).pullUp()
  let t = newTrace(p)

  clear(t)
  check lowp(p)
  float(t)
  check highp(p)

proc upOutput* =
  let p = newPin(1, "A", Output).pullUp()
  let t = newTrace(p)

  clear(p)
  check lowp(t)
  float(p)
  check highp(t)

proc upBidi* =
  let p = newPin(1, "A", Bidi).pullUp()
  let t = newTrace(p)

  clear(p)
  check lowp(t)
  float(p)
  check highp(t)

proc upAfter* =
  let p = newPin(1, "A")
  check floatp(p)
  pullUp(p)
  check highp(p)

proc downInitial* =
  let p = newPin(1, "A", Output).pullDown()
  check lowp(p)

proc downUnconnected* =
  let p = newPin(1, "A", Unconnected).pullDown()
  set(p)
  check highp(p)
  float(p)
  check lowp(p)

proc downInput* =
  let p = newPin(1, "A", Input).pullDown()
  let t = newTrace(p)

  set(t)
  check highp(p)
  float(t)
  check lowp(p)

proc downOutput* =
  let p = newPin(1, "A", Output).pullDown()
  let t = newTrace(p)

  set(p)
  check highp(t)
  float(p)
  check lowp(t)

proc downBidi* =
  let p = newPin(1, "A", Bidi).pullDown()
  let t = newTrace(p)

  set(p)
  check highp(t)
  float(p)
  check lowp(t)

proc downAfter* =
  let p = newPin(1, "A")
  check floatp(p)
  pullDown(p)
  check lowp(p)

proc offInitial* =
  let p = newPin(1, "A").pullOff()
  check floatp(p)

proc offAfterUp* =
  let p = newPin(1, "A").pullUp()
  float(p)
  check highp(p)

  pullOff(p)
  float(p)
  check floatp(p)


proc offAfterDown* =
  let p = newPin(1, "A").pullDown()
  float(p)
  check lowp(p)

  pullOff(p)
  float(p)
  check floatp(p)