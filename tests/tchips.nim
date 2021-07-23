# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ./chips/ic7406
import ./chips/ic7408

proc ic7406Tests() =
  suite "7406 hex inverter":
    test "initial levels": initial7406()
    test "output low when input high": lowOnHighIn()
    test "output high when input low": highOnLowIn()

proc ic7408Tests() =
  suite "7408 quad 2-input AND gate":
    test "initial levels": initial7408()
    test "proper outputs on gate 1 inputs": gate1()
    test "proper outputs on gate 2 inputs": gate2()
    test "proper outputs on gate 3 inputs": gate3()
    test "proper outputs on gate 4 inputs": gate4()

proc chipTests*() =
  ic7406Tests()
  ic7408Tests()

when isMainModule:
  chipTests()
