# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../../src/nim64/components/link
import unittest
from sugar import `=>`

proc listenUnc* =
  let p = newPin(1, "A")
  let t = newTrace(p)
  var count = 0

  addListener(p, (_: Pin) => (count += 1))

  set(t)
  check count == 0

proc listenIn* =
  let p = newPin(1, "A", Input)
  let t = newTrace(p)
  var count = 0
  var args: seq[Pin] = @[]

  addListener(p, (pin: Pin) => (count += 1; add(args, pin)))

  set(t)
  check:
    count == 1
    args[0] == p

proc listenOut* =
  let p = newPin(1, "A", Output)
  let t = newTrace(p)
  var count = 0

  addListener(p, (_: Pin) => (count += 1))

  set(t)
  check count == 0

proc listenBidi* =
  let p = newPin(1, "A", Bidi)
  let t = newTrace(p)
  var count = 0
  var args: seq[Pin] = @[]

  addListener(p, (pin: Pin) => (count += 1; add(args, pin)))

  set(t)
  check:
    count == 1
    args[0] == p

proc listenDirect* =
  let p = newPin(1, "A", Input)
  var count = 0

  addListener(p, (_: Pin) => (count += 1))

  set(p)
  check count == 0

proc listenRemove* =
  let p = newPin(1, "A", Input)
  let t = newTrace(p)
  var count1 = 0
  var count2 = 0

  let listen1 = (p: Pin) => (count1 += 1)
  let listen2 = (p: Pin) => (count2 += 1)

  addListener(p, listen1)
  addListener(p, listen2)

  set(t)
  check:
    count1 == 1
    count2 == 1
  
  removeListener(p, listen1)

  clear(t)
  check:
    count1 == 1
    count2 == 2

proc listenNoExist* =
  let p = newPin(1, "A", Input)
  let t = newTrace(p)
  var count1 = 0
  var count2 = 0

  let listen1 = (p: Pin) => (count1 += 1)
  let listen2 = (p: Pin) => (count2 += 1)

  addListener(p, listen2)

  set(t)
  check:
    count1 == 0
    count2 == 1
  
  removeListener(p, listen1)

  clear(t)
  check:
    count1 == 0
    count2 == 2

proc listenDouble* =
  let p = newPin(1, "A", Input)
  let t = newTrace(p)
  var count = 0

  let listen = (_: Pin) => (count += 1)
  addListener(p, listen)
  addListener(p, listen)

  set(t)
  check count == 1
