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
  let chip = newIc7406()
  result = (chip, deviceTraces(chip))

proc lowOnHighIn =
  let (_, traces) = setup()

  for i in 1..6:
    set traces[&"A{i}"]
    check lowp traces[&"Y{i}"]

proc highOnLowIn =
  let (_, traces) = setup()

  for i in 1..6:
    clear traces[&"A{i}"]
    check highp traces[&"Y{i}"]

proc allTests* =
  suite "7406 hex inverter":
    test "output low when input high": lowOnHighIn()
    test "output high when input low": highOnLowIn()

when isMainModule:
  allTests()
