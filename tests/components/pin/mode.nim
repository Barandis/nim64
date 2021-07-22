# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../../src/nim64/components/link
import unittest

proc modeInitial* =
  let p1 = newPin(1, "A", Unconnected)
  let p2 = newPin(2, "B", Input)
  let p3 = newPin(3, "C", Output)
  let p4 = newPin(4, "D", Bidi)

  check:
    mode(p1) == Unconnected
    not isInput(p1)
    not isOutput(p1)

    mode(p2) == Input
    isInput(p2)
    not isOutput(p2)

    mode(p3) == Output
    not isInput(p3)
    isOutput(p3)

    mode(p4) == Bidi
    isInput(p4)
    isOutput(p4)

proc modeChange* =
  let p = newPin(1, "A")
  check mode(p) == Unconnected
  setMode(p, Input)
  check mode(p) == Input
  setMode(p, Output)
  check mode(p) == Output
  setMode(p, Bidi)
  check mode(p) == Bidi

proc modeOutToIn* =
  let p = newPin(1, "A", Output)
  let t = newTrace(p, newPin(2, "B", Input))

  set(p)
  check high(t)
  setMode(p, Input)
  check floating(t)

proc modeBidiToIn* =
  let p = newPin(1, "A", Bidi)
  let t = newTrace(p, newPin(2, "B", Input))

  set(p)
  check high(t)
  setMode(p, Input)
  check floating(t)

proc modeUncToIn* =
  let p = newPin(1, "A")
  let t = newTrace(p, newPin(2, "B", Input))

  set(p)
  check floating(t)
  setMode(p, Input)
  check floating(t)

proc modeBidiToOut* =
  let p = newPin(1, "A", Bidi)
  let t = newTrace(p)

  set(p)
  check high(t)
  setMode(p, Output)
  check high(t)

proc modeUncToOut* =
  let p = newPin(1, "A")
  let t = newTrace(p)

  set(p)
  check floating(t)
  setMode(p, Output)
  check high(t)

proc modeInToUnc* =
  let p = newPin(1, "A", Input)
  let t = newTrace(p)

  set(t)
  check high(p)
  setMode(p, Unconnected)
  check high(t)
  check high(p)
