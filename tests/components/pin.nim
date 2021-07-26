# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../src/nim64/components/link
import unittest

import ./pin/[level, pull, mode, listener]

proc base_tests =
  suite "Pin":
    test "number":
      let p = new_pin(1, "A")
      check (number p) == 1
    
    test "name":
      let p = new_pin(1, "A")
      check (name p) == "A"

proc all_tests* =
  base_tests()
  level.all_tests()
  pull.all_tests()
  mode.all_tests()
  listener.all_tests()

when is_main_module:
  all_tests()
