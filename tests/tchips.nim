# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ./chips/ic7406

proc ic7406Tests() =
  suite "7406 hex inverter":
    test "output low when input high": lowOnHighIn()
    test "output high when input low": highOnLowIn()

ic7406Tests()
