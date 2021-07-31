# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ../utils
import ../../src/nim64/chips/ic7408
import ../../src/nim64/components/link

proc setup: (Ic7408, Traces) =
  let chip = new_ic7408()
  result = (chip, device_traces(chip))

proc gate_1 =
  let (_, traces) = setup()

  clear(traces[A1])
  clear(traces[B1])
  check lowp(traces[Y1])

  clear(traces[A1])
  set(traces[B1])
  check lowp(traces[Y1])

  set(traces[A1])
  clear(traces[B1])
  check lowp(traces[Y1])

  set(traces[A1])
  set(traces[B1])
  check highp(traces[Y1])

proc gate_2 =
  let (_, traces) = setup()

  clear(traces[A2])
  clear(traces[B2])
  check lowp(traces[Y2])

  clear(traces[A2])
  set(traces[B2])
  check lowp(traces[Y2])

  set(traces[A2])
  clear(traces[B2])
  check lowp(traces[Y2])

  set(traces[A2])
  set(traces[B2])
  check highp(traces[Y2])

proc gate_3 =
  let (_, traces) = setup()

  clear(traces[A3])
  clear(traces[B3])
  check lowp(traces[Y3])

  clear(traces[A3])
  set(traces[B3])
  check lowp(traces[Y3])

  set(traces[A3])
  clear(traces[B3])
  check lowp(traces[Y3])

  set(traces[A3])
  set(traces[B3])
  check highp(traces[Y3])

proc gate_4 =
  let (_, traces) = setup()

  clear(traces[A4])
  clear(traces[B4])
  check lowp(traces[Y4])

  clear(traces[A4])
  set(traces[B4])
  check lowp(traces[Y4])

  set(traces[A4])
  clear(traces[B4])
  check lowp(traces[Y4])

  set(traces[A4])
  set(traces[B4])
  check highp(traces[Y4])

proc all_tests* =
  suite "7408 quad 2-input AND gate":
    test "sets X1 to A1 and B1": gate_1()
    test "sets X2 to A2 and B2": gate_2()
    test "sets X3 to A3 and B3": gate_3()
    test "sets X4 to A4 and B4": gate_4()

when is_main_module:
  all_tests()
