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

proc allTests* =
  baseTests()
  level.allTests()
  pull.allTests()
  mode.allTests()
  listener.allTests()

when isMainModule:
  allTests()
