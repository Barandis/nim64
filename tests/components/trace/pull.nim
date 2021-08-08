# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../../src/nim64/components/link
import unittest

proc up_initial* =
  let t = set_pull(new_trace(), Up)
  check highp(t)

proc up_input =
  let p = new_pin(1, "A", Output)
  let t = set_pull(new_trace(p), Up)

  clear(p)
  check lowp(t)
  set_mode(p, Input)
  check highp(t)

proc up_no_output =
  let p = new_pin(1, "A", Input)
  let t = set_pull(new_trace(p), Up)
  check highp(t)

proc up_high_output =
  let p1 = set(new_pin(1, "A", Output))
  let p2 = clear(new_pin(2, "B", Output))
  let t = set_pull(new_trace(p1, p2), Up)
  check highp(t)

proc up_low_output =
  let p1 = clear(new_pin(1, "A", Output))
  let p2 = clear(new_pin(2, "B", Output))
  let t = set_pull(new_trace(p1, p2), Up)
  check lowp(t)

proc up_tri_output =
  let p1 = tri(new_pin(1, "A", Output))
  let p2 = tri(new_pin(2, "B", Output))
  let t = set_pull(new_trace(p1, p2), Up)
  check highp(t)

proc down_initial =
  let t = set_pull(new_trace(), Down)
  check lowp(t)

proc down_input =
  let p = new_pin(1, "A", Output)
  let t = set_pull(new_trace(p), Down)

  set(p)
  check highp(t)
  set_mode(p, Input)
  check lowp(t)

proc down_no_output =
  let p = new_pin(1, "A", Input)
  let t = set_pull(new_trace(p), Down)
  check lowp(t)

proc down_high_output =
  let p1 = set(new_pin(1, "A", Output))
  let p2 = clear(new_pin(2, "B", Output))
  let t = set_pull(new_trace(p1, p2), Down)
  check highp(t)

proc down_low_output =
  let p1 = clear(new_pin(1, "A", Output))
  let p2 = clear(new_pin(2, "B", Output))
  let t = set_pull(new_trace(p1, p2), Down)
  check lowp(t)

proc down_tri_output =
  let p1 = tri(new_pin(1, "A", Output))
  let p2 = tri(new_pin(2, "B", Output))
  let t = set_pull(new_trace(p1, p2), Down)
  check lowp(t)

proc off_initial =
  let t = set_pull(new_trace(), Off)
  check trip(t)

proc off_input =
  let p = new_pin(1, "A", Output)
  let t = set_pull(new_trace(p), Off)

  set(p)
  check highp(t)
  set_mode(p, Input)
  check trip(t)

proc off_no_output =
  let p = new_pin(1, "A", Input)
  let t = set_pull(new_trace(p), Off)
  check trip(t)

proc off_high_output =
  let p1 = set(new_pin(1, "A", Output))
  let p2 = clear(new_pin(2, "B", Output))
  let t = set_pull(new_trace(p1, p2), Off)
  check highp(t)

proc off_low_output =
  let p1 = clear(new_pin(1, "A", Output))
  let p2 = clear(new_pin(2, "B", Output))
  let t = set_pull(new_trace(p1, p2), Off)
  check lowp(t)

proc off_tri_output =
  let p1 = tri(new_pin(1, "A", Output))
  let p2 = tri(new_pin(2, "B", Output))
  let t = set_pull(new_trace(p1, p2), Off)
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

when is_main_module:
  all_tests()
