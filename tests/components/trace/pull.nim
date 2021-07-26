# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../../src/nim64/components/link
import unittest

proc up_initial* =
  let t = new_trace().pull_up()
  check highp(t)

proc up_input =
  let p = new_pin(1, "A", Output)
  let t = new_trace(p).pull_up()

  clear(p)
  check lowp(t)
  set_mode(p, Input)
  check highp(t)

proc up_no_output =
  let p = new_pin(1, "A", Input)
  let t = new_trace(p).pull_up()
  check highp(t)

proc up_high_output =
  let p1 = new_pin(1, "A", Output).set()
  let p2 = new_pin(2, "B", Output).clear()
  let t = new_trace(p1, p2).pull_up()
  check highp(t)

proc up_low_output =
  let p1 = new_pin(1, "A", Output).clear()
  let p2 = new_pin(2, "B", Output).clear()
  let t = new_trace(p1, p2).pull_up()
  check lowp(t)

proc up_tri_output =
  let p1 = new_pin(1, "A", Output).tri()
  let p2 = new_pin(2, "B", Output).tri()
  let t = new_trace(p1, p2).pull_up()
  check highp(t)

proc down_initial =
  let t = new_trace().pull_down()
  check lowp(t)

proc down_input =
  let p = new_pin(1, "A", Output)
  let t = new_trace(p).pull_down()

  set(p)
  check highp(t)
  set_mode(p, Input)
  check lowp(t)

proc down_no_output =
  let p = new_pin(1, "A", Input)
  let t = new_trace(p).pull_down()
  check lowp(t)

proc down_high_output =
  let p1 = new_pin(1, "A", Output).set()
  let p2 = new_pin(2, "B", Output).clear()
  let t = new_trace(p1, p2).pull_down()
  check highp(t)

proc down_low_output =
  let p1 = new_pin(1, "A", Output).clear()
  let p2 = new_pin(2, "B", Output).clear()
  let t = new_trace(p1, p2).pull_down()
  check lowp(t)

proc down_tri_output =
  let p1 = new_pin(1, "A", Output).tri()
  let p2 = new_pin(2, "B", Output).tri()
  let t = new_trace(p1, p2).pull_down()
  check lowp(t)

proc off_initial =
  let t = new_trace().pull_off()
  check trip(t)

proc off_input =
  let p = new_pin(1, "A", Output)
  let t = new_trace(p).pull_off()

  set(p)
  check highp(t)
  set_mode(p, Input)
  check trip(t)

proc off_no_output =
  let p = new_pin(1, "A", Input)
  let t = new_trace(p).pull_off()
  check trip(t)

proc off_high_output =
  let p1 = new_pin(1, "A", Output).set()
  let p2 = new_pin(2, "B", Output).clear()
  let t = new_trace(p1, p2).pull_off()
  check highp(t)

proc off_low_output =
  let p1 = new_pin(1, "A", Output).clear()
  let p2 = new_pin(2, "B", Output).clear()
  let t = new_trace(p1, p2).pull_off()
  check lowp(t)

proc off_tri_output =
  let p1 = new_pin(1, "A", Output).tri()
  let p2 = new_pin(2, "B", Output).tri()
  let t = new_trace(p1, p2).pull_off()
  check trip(t)

proc allTests* =
  suite "Trace pull-up and pull-down":
    test "pull-up initial level is high": up_initial()
    test "pulled up with only input pins if trace level not set": up_input()
    test "pulled up with no output pins if trace level not set": up_no_output()
    test "not pulled up with high output pins": up_high_output()
    test "not pulled up with low output pins": up_low_output()
    test "pulled up with tri-state output pins if trace level was not set": up_tri_output()
    test "pull-down initial level is low": down_initial()
    test "pulled down with only input pins if trace level not set": down_input()
    test "pulled down with no output pins if trace level not set": down_no_output()
    test "not pulled down with high output pins": down_high_output()
    test "not pulled down with low output pins": down_low_output()
    test "pulled down with tri-state output pins if trace level was not set": down_tri_output()
    test "unpulled initial level is tri-state": off_initial()
    test "unpulled level with only input pins is tri-state": off_input()
    test "unpulled level with no output pins is tri-state": off_no_output()
    test "unpulled level with high output pins is high": off_high_output()
    test "unpulled level with low output pins is low": off_low_output()
    test "unpulled level wtih tri-stated output pins is tri-state": off_tri_output()
