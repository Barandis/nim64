# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../../src/nim64/components/link
import unittest

proc upInitial =
  let p = newPin(1, "A", Output).pullUp()
  check highp(p)

proc upUnconnected =
  let p = newPin(1, "A", Unconnected).pullUp()
  clear(p)
  check lowp(p)
  tri(p)
  check highp(p)

proc upInput =
  let p = newPin(1, "A", Input).pullUp()
  let t = newTrace(p)

  clear(t)
  check lowp(p)
  tri(t)
  check highp(p)

proc upOutput =
  let p = newPin(1, "A", Output).pullUp()
  let t = newTrace(p)

  clear(p)
  check lowp(t)
  tri(p)
  check highp(t)

proc upBidi =
  let p = newPin(1, "A", Bidi).pullUp()
  let t = newTrace(p)

  clear(p)
  check lowp(t)
  tri(p)
  check highp(t)

proc upAfter =
  let p = newPin(1, "A")
  check trip(p)
  pullUp(p)
  check highp(p)

proc downInitial =
  let p = newPin(1, "A", Output).pullDown()
  check lowp(p)

proc downUnconnected =
  let p = newPin(1, "A", Unconnected).pullDown()
  set(p)
  check highp(p)
  tri(p)
  check lowp(p)

proc downInput =
  let p = newPin(1, "A", Input).pullDown()
  let t = newTrace(p)

  set(t)
  check highp(p)
  tri(t)
  check lowp(p)

proc downOutput =
  let p = newPin(1, "A", Output).pullDown()
  let t = newTrace(p)

  set(p)
  check highp(t)
  tri(p)
  check lowp(t)

proc downBidi =
  let p = newPin(1, "A", Bidi).pullDown()
  let t = newTrace(p)

  set(p)
  check highp(t)
  tri(p)
  check lowp(t)

proc downAfter =
  let p = newPin(1, "A")
  check trip(p)
  pullDown(p)
  check lowp(p)

proc offInitial =
  let p = newPin(1, "A").pullOff()
  check trip(p)

proc offAfterUp =
  let p = newPin(1, "A").pullUp()
  tri(p)
  check highp(p)

  pullOff(p)
  tri(p)
  check trip(p)


proc offAfterDown =
  let p = newPin(1, "A").pullDown()
  tri(p)
  check lowp(p)

  pullOff(p)
  tri(p)
  check trip(p)

proc allTests* =
  suite "Pin pull-up and pull-down":
    test "pulled-up pin initial value is high": upInitial()
    test "unconnected pin pulled up on tri-state": upUnconnected()
    test "input pin pulled up if trace is tri-state": upInput()
    test "output pin pulled up and affects trace level": upOutput()
    test "bidi pin pulled up and affects trace level": upBidi()
    test "pulling up a pin later sets it high if it is still tri-state": upAfter()
    test "pulled-up pin initial value is low": downInitial()
    test "unconnected pin pulled down on tri-state": downUnconnected()
    test "input pin pulled down if trace is tri-state": downInput()
    test "output pin pulled down and affects trace level": downOutput()
    test "bidi pin pulled down and affects trace level": downBidi()
    test "pulling down a pin later sets it low if it is still tri-state": downAfter()
    test "unpulled pin initial value is tri-state": offInitial()
    test "removing pull up tri-states pin if it was high only because of pull-up": offAfterUp()
    test "removing pull down tri-states pin if it was low only becuase of pull-down": offAfterDown()

when isMainModule:
  allTests()