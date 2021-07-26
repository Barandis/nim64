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

proc allTests* =
  baseTests()
  level.allTests()
  pull.allTests()

when isMainModule:
  allTests()
