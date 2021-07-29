# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../../src/nim64/components/link
import unittest

proc mode_initial =
  let p1 = new_pin(1, "A", Unconnected)
  let p2 = new_pin(2, "B", Input)
  let p3 = new_pin(3, "C", Output)
  let p4 = new_pin(4, "D", Bidi)

  check:
    (mode p1) == Unconnected
    not inputp p1
    not outputp p1

    (mode p2) == Input
    inputp p2
    not outputp p2

    (mode p3) == Output
    not inputp p3
    outputp p3

    (mode p4) == Bidi
    inputp p4
    outputp p4

proc mode_change =
  let p = new_pin(1, "A")
  check (mode p) == Unconnected
  set_mode p, Input
  check (mode p) == Input
  set_mode p, Output
  check (mode p) == Output
  set_mode p, Bidi
  check (mode p) == Bidi

proc mode_out_to_in =
  let p = new_pin(1, "A", Output)
  let t = new_trace(p, new_pin(2, "B", Input))

  set p
  check highp t
  set_mode p, Input
  check trip t

proc modeBidiToIn =
  let p = new_pin(1, "A", Bidi)
  let t = new_trace(p, new_pin(2, "B", Input))

  set p
  check highp t
  set_mode p, Input
  check trip t

proc mode_unc_to_in =
  let p = new_pin(1, "A")
  let t = new_trace(p, new_pin(2, "B", Input))

  echo level t
  set p
  check trip t
  set_mode p, Input
  check trip t

proc mode_bidi_to_out =
  let p = new_pin(1, "A", Bidi)
  let t = new_trace p

  set p
  check highp t
  set_mode p, Output
  check highp t

proc mode_unc_to_out =
  let p = new_pin(1, "A")
  let t = new_trace p

  set p
  check trip t
  set_mode p, Output
  check highp t

proc mode_in_to_unc =
  let p = new_pin(1, "A", Input)
  let t = new_trace p

  set t
  check highp p
  set_mode p, Unconnected
  check highp t
  check highp p

proc all_tests* =
  suite "Pin mode":
    test "initial": mode_initial()
    test "mode change": mode_change()
    test "output to input": mode_out_to_in()
    test "bidi to input": mode_bidi_to_in()
    test "unconnected to input": mode_unc_to_in()
    test "bidi to output": mode_bidi_to_out()
    test "unconnected to output": mode_unc_to_out()
    test "input to unconnected": mode_in_to_unc()

when is_main_module:
  all_tests()
