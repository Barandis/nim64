# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../src/nim64/components/link
import unittest

import ./pin/level
import ./pin/pull
import ./pin/mode
import ./pin/listener

proc baseTests =
  suite "components.pin":
    test "number":
      let p = newPin(1, "A")
      check p.number == 1
    
    test "name":
      let p = newPin(1, "A")
      check p.name == "A"

proc levelTests =
  suite "components.pin.level":
    test "without trace, functions": functions()
    test "without trace, methods": methods()
    test "without trace, operators": operators()
    test "unconnected pin": unconnected()
    test "input pin": input()
    test "output pin": output()
    test "bidi pin": bidi()
    test "toggle to high": toggleHigh()
    test "toggle to low": toggleLow()
    test "toggle floating": toggleFloating()
  
proc pullTests =
  suite "components.pin.pull.up":
    test "initial": upInitial()
    test "unconnected": upUnconnected()
    test "input": upInput()
    test "output": upOutput()
    test "bidi": upBidi()
    test "after": upAfter()
  suite "components.pin.pull.down":
    test "initial": downInitial()
    test "unconnected": downUnconnected()
    test "input": downInput()
    test "output": downOutput()
    test "bidi": downBidi()
    test "after": downAfter()
  suite "components.pin.pull.off":
    test "initial": offInitial()
    test "after pull up": offAfterUp()
    test "after pull down": offAfterDown()

proc modeTests =
  suite "components.pin.mode":
    test "initial": modeInitial()
    test "mode change": modeChange()
    test "output to input": modeOutToIn()
    test "bidi to input": modeBidiToIn()
    test "unconnected to input": modeUncToIn()
    test "bidi to output": modeBidiToOut()
    test "unconnected to output": modeUncToOut()
    test "input to unconnected": modeInToUnc()

proc listenerTests =
  suite "components.pin.listener":
    test "unconnected": listenUnc()
    test "input": listenIn()
    test "output": listenOut()
    test "bidi": listenBidi()
    test "direct pin change": listenDirect()
    test "remove": listenRemove()
    test "remove non-existent": listenNoExist()
    test "add listener twice": listenDouble()


proc pinTests* =
  baseTests()
  levelTests()
  pullTests()
  modeTests()
  listenerTests()