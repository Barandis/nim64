# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ../utils
import ../../src/nim64/chips/ic4066
import ../../src/nim64/components/link

proc setup: (Ic4066, Traces) =
  let chip = new_ic4066()
  let traces = device_traces(chip)
  result = (chip, traces)

proc pass_a_to_b =
  let (_, traces) = setup()

  clear traces[X1]
  set_level traces[A1], 0.5
  check (level traces[B1]) == 0.5

  clear traces[X2]
  set_level traces[A2], 0.75
  check (level traces[B2]) == 0.75

  clear traces[X3]
  set_level traces[A3], 0.25
  check (level traces[B3]) == 0.25

  clear traces[X4]
  set_level traces[A4], 1
  check (level traces[B4]) == 1

proc pass_b_to_a =
  let (_, traces) = setup()

  clear traces[X1]
  set_level traces[B1], 0.5
  check (level traces[A1]) == 0.5

  clear traces[X2]
  set_level traces[B2], 0.75
  check (level traces[A2]) == 0.75

  clear traces[X3]
  set_level traces[B3], 0.25
  check (level traces[A3]) == 0.25

  clear traces[X4]
  set_level traces[B4], 1
  check (level traces[A4]) == 1

proc tri_on_high_x =
  let (_, traces) = setup()

  set traces[X1]
  check:
    trip traces[A1]
    trip traces[B1]
  
  set traces[X2]
  check:
    trip traces[A2]
    trip traces[B2]
  
  set traces[X3]
  check:
    trip traces[A3]
    trip traces[B3]
  
  set traces[X4]
  check:
    trip traces[A4]
    trip traces[B4]

proc no_pass_a_to_b_on_high_x =
  let (_, traces) = setup()

  set traces[X1]
  set_level traces[A1], 0.5
  check trip traces[B1]

  set traces[X2]
  set_level traces[A2], 0.75
  check trip traces[B2]

  set traces[X3]
  set_level traces[A3], 0.25
  check trip traces[B3]

  set traces[X4]
  set_level traces[A4], 1
  check trip traces[B4]

proc no_pass_b_to_a_on_high_x =
  let (_, traces) = setup()

  set traces[X1]
  set_level traces[B1], 0.5
  check trip traces[A1]

  set traces[X2]
  set_level traces[B2], 0.75
  check trip traces[A2]

  set traces[X3]
  set_level traces[B3], 0.25
  check trip traces[A3]

  set traces[X4]
  set_level traces[B4], 1
  check trip traces[A4]

proc last_set_a =
  let (_, traces) = setup()

  set traces[X1]
  set_level traces[B1], 1.5
  set_level traces[A1], 0.5
  clear traces[X1]
  check (level traces[B1]) == 0.5

  set traces[X2]
  set_level traces[B2], 1.5
  set_level traces[A2], 0.75
  clear traces[X2]
  check (level traces[B2]) == 0.75

  set traces[X3]
  set_level traces[B3], 1.5
  set_level traces[A3], 0.25
  clear traces[X3]
  check (level traces[B3]) == 0.25

  set traces[X4]
  set_level traces[B4], 1.5
  set_level traces[A4], 1
  clear traces[X4]
  check (level traces[B4]) == 1

proc last_set_b =
  let (_, traces) = setup()

  set traces[X1]
  set_level traces[A1], 1.5
  set_level traces[B1], 0.5
  clear traces[X1]
  check (level traces[A1]) == 0.5

  set traces[X2]
  set_level traces[A2], 1.5
  set_level traces[B2], 0.75
  clear traces[X2]
  check (level traces[A2]) == 0.75

  set traces[X3]
  set_level traces[A3], 1.5
  set_level traces[B3], 0.25
  clear traces[X3]
  check (level traces[A3]) == 0.25

  set traces[X4]
  set_level traces[A4], 1.5
  set_level traces[B4], 1
  clear traces[X4]
  check (level traces[A4]) == 1

proc last_set_none =
  let (_, traces) = setup()

  set traces[X1]
  clear traces[X1]
  check:
    (level traces[A1]) == 0
    (level traces[B1]) == 0

  set traces[X2]
  clear traces[X2]
  check:
    lowp traces[A2]
    lowp traces[B2]

  set traces[X3]
  clear traces[X3]
  check:
    lowp traces[A3]
    lowp traces[B3]

  set traces[X4]
  clear traces[X4]
  check:
    lowp traces[A4]
    lowp traces[B4]

proc all_tests* =
  suite "4066 quad analog switch":
    test "passes signals from A to B": pass_a_to_b()
    test "passes signals from B to A": pass_b_to_a()
    test "tri-states A and B on high X": tri_on_high_x()
    test "does not pass signals from A to B on high X": no_pass_a_to_b_on_high_x()
    test "does not pass signals from B to A on high X": no_pass_b_to_a_on_high_x()
    test "sets B to A when X goes low if A was last set": last_set_a()
    test "sets A to B when X goes low if B was last set": last_set_b()
    test "clears A and B when X goes low if neither was last set": last_set_none()

when is_main_module:
  all_tests()
