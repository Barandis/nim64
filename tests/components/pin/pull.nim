# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../../src/nim64/components/link
import unittest

proc up_initial =
  let p = pull_up(new_pin(1, "A", Output))
  check highp(p)

proc up_unconnected =
  let p = pull_up(new_pin(1, "A", Unconnected))
  clear(p)
  check lowp(p)
  tri(p)
  check highp(p)

proc up_input =
  let p = pull_up(new_pin(1, "A", Input))
  let t = new_trace(p)

  clear(t)
  check lowp(p)
  tri(t)
  check highp(p)

proc up_output =
  let p = pull_up(new_pin(1, "A", Output))
  let t = new_trace(p)

  clear(p)
  check lowp(t)
  tri(p)
  check highp(t)

proc up_bidi =
  let p = pull_up(new_pin(1, "A", Bidi))
  let t = new_trace(p)

  clear(p)
  check lowp(t)
  tri(p)
  check highp(t)

proc up_after =
  let p = new_pin(1, "A")
  check trip(p)
  pull_up(p)
  check highp(p)

proc down_initial =
  let p = pull_down(new_pin(1, "A", Output))
  check lowp(p)

proc down_unconnected =
  let p = pull_down(new_pin(1, "A", Unconnected))
  set(p)
  check highp(p)
  tri(p)
  check lowp(p)

proc down_input =
  let p = pull_down(new_pin(1, "A", Input))
  let t = new_trace(p)

  set(t)
  check highp(p)
  tri(t)
  check lowp(p)

proc down_output =
  let p = pull_down(new_pin(1, "A", Output))
  let t = new_trace(p)

  set(p)
  check highp(t)
  tri(p)
  check lowp(t)

proc down_bidi =
  let p = pull_down(new_pin(1, "A", Bidi))
  let t = new_trace(p)

  set(p)
  check highp(t)
  tri(p)
  check lowp(t)

proc down_after =
  let p = new_pin(1, "A")
  check trip(p)
  pull_down(p)
  check lowp(p)

proc off_initial =
  let p = pull_off(new_pin(1, "A"))
  check trip(p)

proc off_after_up =
  let p = pull_up(new_pin(1, "A"))
  tri(p)
  check highp(p)

  pull_off(p)
  tri(p)
  check trip(p)


proc off_after_down =
  let p = pull_down(new_pin(1, "A"))
  tri(p)
  check lowp(p)

  pull_off(p)
  tri(p)
  check trip(p)

proc all_tests* =
  suite "Pin pull-up and pull-down":
    test "pulled-up pin initial value is high": up_initial()
    test "unconnected pin pulled up on tri-state": up_unconnected()
    test "input pin pulled up if trace is tri-state": up_input()
    test "output pin pulled up and affects trace level": up_output()
    test "bidi pin pulled up and affects trace level": up_bidi()
    test "pulling up a pin later sets it high if it is still tri-state": up_after()
    test "pulled-up pin initial value is low": down_initial()
    test "unconnected pin pulled down on tri-state": down_unconnected()
    test "input pin pulled down if trace is tri-state": down_input()
    test "output pin pulled down and affects trace level": down_output()
    test "bidi pin pulled down and affects trace level": down_bidi()
    test "pulling down a pin later sets it low if it is still tri-state": down_after()
    test "unpulled pin initial value is tri-state": off_initial()
    test "removing pull up tri-states pin if it was high because of pull-up": off_after_up()
    test "removing pull down tri-states pin if it was low becuase of pull-down": off_after_down()

when is_main_module:
  all_tests()