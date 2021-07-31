# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../src/nim64/components/link
import unittest
from sugar import `=>`

import ./trace/[level, pull]

proc base_tests =
  suite "Trace":
    test "no double add":
      let p = new_pin(1, "a", Input)
      let t = new_trace(p, p)
      var count = 0

      add_listener(p, (_: Pin) => (count += 1))
      set(t)
      check count == 1

proc all_tests* =
  base_tests()
  level.all_tests()
  pull.all_tests()

when is_main_module:
  all_tests()
