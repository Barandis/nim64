# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../src/nim64/components/link
import unittest
from sugar import `=>`

import ./trace/level
import ./trace/pull

proc baseTests =
  suite "components.trace":
    test "no double add":
      let p = newPin(1, "a", Input)
      let t = newTrace(p, p)
      var count = 0

      addListener(p, (_: Pin) => (count += 1))
      set(t)
      check count == 1

proc levelTests =
  suite "components.trace.level.direct":
    test "unconnected": directUnc()
    test "input": directIn()
    test "high output": directOutHigh()
    test "low output": directOutLow()
    test "floating output": directOutFloat()
  suite "components.trace.level.indirect":
    test "unconnected": indirectUnc()
    test "input": indirectIn()
    test "output": indirectOut()
    test "bidi": indirectBidi()
    test "output with other high outputs": indirectOutHigh()
    test "output with other low outputs": indirectOutLow()

proc pullTests =
  suite "components.trace.pull.up":
    test "initial": upInitial()
    test "inputs": upInput()
    test "no outputs": upNoOutput()
    test "high outputs": upHighOutput()
    test "low outputs": upLowOutput()
    test "floating outputs": upFloatOutput()
  suite "components.trace.pull.down":
    test "initial": downInitial()
    test "inputs": downInput()
    test "no outputs": downNoOutput()
    test "high outputs": downHighOutput()
    test "low outputs": downLowOutput()
    test "floating outputs": downFloatOutput()
  suite "components.trace.pull.off":
    test "initial": offInitial()
    test "inputs": offInput()
    test "no outputs": offNoOutput()
    test "high outputs": offHighOutput()
    test "low outputs": offLowOutput()
    test "floating outputs": offFloatOutput()

proc traceTests* =
  baseTests()
  levelTests()
  pullTests()