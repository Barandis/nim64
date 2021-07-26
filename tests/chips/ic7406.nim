# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import strformat
import ../utils
import ../../src/nim64/chips/ic7406
import ../../src/nim64/components/link

proc setup: (Ic7406, Traces) =
  let chip = new_ic7406()
  result = (chip, device_traces(chip))

proc low_on_high_in =
  let (_, traces) = setup()

  for i in 1..6:
    set traces[&"A{i}"]
    check lowp traces[&"Y{i}"]

proc high_on_low_in =
  let (_, traces) = setup()

  for i in 1..6:
    clear traces[&"A{i}"]
    check highp traces[&"Y{i}"]

proc all_tests* =
  suite "7406 hex inverter":
    test "output low when input high": low_on_high_in()
    test "output high when input low": high_on_low_in()

when is_main_module:
  all_tests()
