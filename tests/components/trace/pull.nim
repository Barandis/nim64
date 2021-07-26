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

proc upTriOutput* =
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

proc downTriOutput* =
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

proc offTriOutput* =
  let p1 = newPin(1, "A", Output).tri()
  let p2 = newPin(2, "B", Output).tri()
  let t = newTrace(p1, p2).pullOff()
  check trip(t)

proc allTests* =
  suite "Trace pull-up and pull-down":
    test "pull-up initial level is high": upInitial()
    test "pulled up with only input pins if trace level not set": upInput()
    test "pulled up with no output pins if trace level not set": upNoOutput()
    test "not pulled up with high output pins": upHighOutput()
    test "not pulled up with low output pins": upLowOutput()
    test "pulled up with tri-state output pins if trace level was not set": upTriOutput()
    test "pull-down initial level is low": downInitial()
    test "pulled down with only input pins if trace level not set": downInput()
    test "pulled down with no output pins if trace level not set": downNoOutput()
    test "not pulled down with high output pins": downHighOutput()
    test "not pulled down with low output pins": downLowOutput()
    test "pulled down with tri-state output pins if trace level was not set": downTriOutput()
    test "unpulled initial level is tri-state": offInitial()
    test "unpulled level with only input pins is tri-state": offInput()
    test "unpulled level with no output pins is tri-state": offNoOutput()
    test "unpulled level with high output pins is high": offHighOutput()
    test "unpulled level with low output pins is low": offLowOutput()
    test "unpulled level wtih tri-stated output pins is tri-state": offTriOutput()
