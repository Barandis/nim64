# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ../utils
import ../../src/nim64/chips/ic74258
import ../../src/nim64/components/link

proc setup: (Ic74258, Traces) =
  let chip = new_ic74258()
  let traces = device_traces(chip)
  result = (chip, traces)

proc mux_1_setup: (Ic74258, Traces) =
  result = setup()
  let (_, traces) = result
  clear traces[A1]
  set traces[B1]

proc mux_1_select_a =
  let (_, traces) = mux_1_setup()

  clear traces[SEL]
  check highp traces[Y1]

  set traces[A1]
  check lowp traces[Y1]

proc mux_1_select_b =
  let (_, traces) = mux_1_setup()

  set traces[SEL]
  check lowp traces[Y1]

  clear traces[B1]
  check highp traces[Y1]

proc mux_1_high_oe =
  let (_, traces) = mux_1_setup()

  set traces[SEL]
  check lowp traces[Y1]

  set traces[OE]
  check trip traces[Y1]

  clear traces[SEL]
  check trip traces[Y1]

proc mux_2_setup: (Ic74258, Traces) =
  result = setup()
  let (_, traces) = result
  clear traces[A2]
  set traces[B2]

proc mux_2_select_a =
  let (_, traces) = mux_2_setup()

  clear traces[SEL]
  check highp traces[Y2]
  set traces[A2]
  check lowp traces[Y2]

proc mux_2_select_b =
  let (_, traces) = mux_2_setup()

  set traces[SEL]
  check lowp traces[Y2]

  clear traces[B2]
  check highp traces[Y2]

proc mux_2_high_oe =
  let (_, traces) = mux_2_setup()

  set traces[SEL]
  check lowp traces[Y2]

  set traces[OE]
  check trip traces[Y2]

  clear traces[SEL]
  check trip traces[Y2]

proc mux_3_setup: (Ic74258, Traces) =
  result = setup()
  let (_, traces) = result
  clear traces[A3]
  set traces[B3]

proc mux_3_select_a =
  let (_, traces) = mux_3_setup()

  clear traces[SEL]
  check highp traces[Y3]

  set traces[A3]
  check lowp traces[Y3]

proc mux_3_select_b =
  let (_, traces) = mux_3_setup()

  set traces[SEL]
  check lowp traces[Y3]

  clear traces[B3]
  check highp traces[Y3]

proc mux_3_high_oe =
  let (_, traces) = mux_3_setup()

  set traces[SEL]
  check lowp traces[Y3]

  set traces[OE]
  check trip traces[Y3]

  clear traces[SEL]
  check trip traces[Y3]

proc mux_4_setup: (Ic74258, Traces) =
  result = setup()
  let (_, traces) = result
  clear traces[A4]
  set traces[B4]

proc mux_4_select_a =
  let (_, traces) = mux_4_setup()

  clear traces[SEL]
  check highp traces[Y4]

  set traces[A4]
  check lowp traces[Y4]

proc mux_4_select_b =
  let (_, traces) = mux_4_setup()

  set traces[SEL]
  check lowp traces[Y4]

  clear traces[B4]
  check highp traces[Y4]

proc mux_4_high_oe =
  let (_, traces) = mux_4_setup()

  set traces[SEL]
  check lowp traces[Y4]

  set traces[OE]
  check trip traces[Y4]

  clear traces[SEL]
  check trip traces[Y4]

proc all_tests* =
  suite "74258 quad 2-to-1 multiplexer":
    test "low SEL selects A1": mux_1_select_a()
    test "high SEL selects B1": mux_1_select_b()
    test "high OE tri-states A1 and B1": mux_1_high_oe()
    test "low SEL selects A2": mux_2_select_a()
    test "high SEL selects B2": mux_2_select_b()
    test "high OE tri-states A1 and B1": mux_2_high_oe()
    test "low SEL selects A3": mux_3_select_a()
    test "high SEL selects B3": mux_3_select_b()
    test "high OE tri-states A1 and B1": mux_3_high_oe()
    test "low SEL selects A4": mux_4_select_a()
    test "high SEL selects B4": mux_4_select_b()
    test "high OE tri-states A1 and B1": mux_4_high_oe()

when is_main_module:
  all_tests()
