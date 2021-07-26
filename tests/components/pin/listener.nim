# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../../src/nim64/components/link
import unittest
from sugar import `=>`

proc listen_unc =
  let p = new_pin(1, "A")
  let t = new_trace p
  var count = 0

  add_listener p, (_: Pin) => (count += 1)

  set t
  check count == 0

proc listen_in =
  let p = new_pin(1, "A", Input)
  let t = new_trace p
  var count = 0
  var args: seq[Pin] = @[]

  add_listener p, (pin: Pin) => (count += 1; add args, pin)

  set t
  check:
    count == 1
    args[0] == p

proc listen_out =
  let p = new_pin(1, "A", Output)
  let t = new_trace p
  var count = 0

  add_listener p, (_: Pin) => (count += 1)

  set t
  check count == 0

proc listen_bidi =
  let p = new_pin(1, "A", Bidi)
  let t = new_trace p
  var count = 0
  var args: seq[Pin] = @[]

  add_listener p, (pin: Pin) => (count += 1; add args, pin)

  set t
  check:
    count == 1
    args[0] == p

proc listen_direct =
  let p = new_pin(1, "A", Input)
  var count = 0

  add_listener p, (_: Pin) => (count += 1)

  set p
  check count == 0

proc listen_remove =
  let p = new_pin(1, "A", Input)
  let t = new_trace p
  var count1 = 0
  var count2 = 0

  let listen1 = (p: Pin) => (count1 += 1)
  let listen2 = (p: Pin) => (count2 += 1)

  add_listener p, listen1
  add_listener p, listen2

  set t
  check:
    count1 == 1
    count2 == 1
  
  remove_listener p, listen1

  clear t
  check:
    count1 == 1
    count2 == 2

proc listen_no_exist =
  let p = new_pin(1, "A", Input)
  let t = new_trace p
  var count1 = 0
  var count2 = 0

  let listen1 = (p: Pin) => (count1 += 1)
  let listen2 = (p: Pin) => (count2 += 1)

  add_listener p, listen2

  set t
  check:
    count1 == 0
    count2 == 1
  
  remove_listener p, listen1

  clear t
  check:
    count1 == 0
    count2 == 2

proc listen_double =
  let p = new_pin(1, "A", Input)
  let t = new_trace p
  var count = 0

  let listen = (_: Pin) => (count += 1)
  add_listener p, listen
  add_listener p, listen

  set t
  check count == 1

proc all_tests* =
  suite "Pin listeners":
    test "unconnected pins do not fire listeners": listen_unc()
    test "input pins fire listeners": listen_in()
    test "output pins do not fire listeners": listen_out()
    test "bidi pins fire listeners": listen_bidi()
    test "direct pin level changes do not fire listeners": listen_direct()
    test "removed listeners cease to fire": listen_remove()
    test "removing unadded listener has no effect": listen_no_exist()
    test "listeners is not added if already added": listen_double()

when is_main_module:
  all_tests()
