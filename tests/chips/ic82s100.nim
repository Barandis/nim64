# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import sequtils
import strformat

import ../utils as test_utils
import ../../src/nim64/chips/ic82s100
import ../../src/nim64/components/link
import ../../src/nim64/utils

proc setup: (Ic82S100, Traces, seq[Trace], seq[Trace]) =
  let chip = new_ic82S100()
  let traces = device_traces chip

  clear traces[OE] 

  let in_traces = map(to_seq 0..15, proc (i: int): Trace = traces[&"I{i}"])
  let out_traces = map(to_seq 0..7, proc (i: int): Trace = traces[&"F{i}"])

  (chip, traces, in_traces, out_traces)

# This program was adapted from a C program that provides a 64k table of outputs for PLA
# based on all of the possible inputs. The original is located at
# http://www.zimmers.net/anonftp/pub/cbm/firmware/computers/c64/pla.c.

proc get_expected(input: uint16): uint8 =
  let a = bit_set(input, 0)
  let b = bit_set(input, 1)
  let c = bit_set(input, 2)
  let d = bit_set(input, 3)
  let e = bit_set(input, 4)
  let f = bit_set(input, 5)
  let g = bit_set(input, 6)
  let h = bit_set(input, 7)
  let i = bit_set(input, 8)
  let j = bit_set(input, 9)
  let k = bit_set(input, 10)
  let l = bit_set(input, 11)
  let m = bit_set(input, 12)
  let n = bit_set(input, 13)
  let o = bit_set(input, 14)
  let p = bit_set(input, 15)

  let f0 = (b and c and f and not g and h and not k and l and n) or
    (c and f and g and h and not k and l and n) or
    (c and f and g and h and not k and l and not m and not n) or
    (c and not d and f and g and not h and i and not k and l and n) or
    (b and not d and f and g and not h and i and not k and l and n) or
    (c and not d and f and g and not h and i and not k and l and not m and not n) or
    (e and k and n and not o and p) or
    (e and k and not m and not n and not o and p) or
    (c and d and f and g and not h and i and j and not k and l and n) or
    (c and d and f and g and not h and i and not k and not l and n) or
    (b and d and f and g and not h and i and j and not k and l and n) or
    (b and d and f and g and not h and i and not k and not l and n) or
    (c and d and f and g and not h and i and j and not k and l and not m and not n) or
    (c and d and f and g and not h and i and not k and not l and not m and not n) or
    (b and d and f and g and not h and i and j and not k and l and not m and not n) or
    (b and d and f and g and not h and i and not k and not l and not m and not n) or
    (f and g and not h and i and j and not k and l and m and not n) or
    (f and g and not h and i and not k and not l and m and not n) or
    (b and c and f and not g and not h and not k and l and not m) or
    (f and not g and not h and not k and m and not n) or
    (c and f and not g and h and not k and l and not m and not n) or
    (f and g and h and not k and m and not n) or
    (k and m and not n and o and p) or
    (not f and not g and i and m and not n) or
    (not f and not g and h and m and not n) or
    (not f and g and m and not n) or
    (f and not g and h and m and not n) or
    (f and g and not h and not i and m and not n) or
    a
  let f1 = not b or not c or not f or g or not h or k or not l or not n
  let f2 = (not c or not f or not g or not h or k or not l or not n) and
    (not c or not f or not g or not h or k or not l or m or n)
  let f3 = (not c or d or not f or not g or h or not i or k or not l or not n) and
    (not b or d or not f or not g or h or not i or k or not l or not n) and
    (not c or d or not f or not g or h or not i or k or not l or m or n) and
    (not e or not k or not n or o or not p) and
    (not e or not k or m or n or o or not p)
  let f4 = a or not f or not g or h or not i or k or l
  let f5 = (not c or not d or not f or not g or h or not i or not j or k or not l or not n) and
    (not c or not d or not f or not g or h or not i or k or l or not n) and
    (not b or not d or not f or not g or h or not i or not j or k or not l or not n) and
    (not b or not d or not f or not g or h or not i or k or l or not n) and
    (not c or not d or not f or not g or h or not i or not j or k or not l or m or n) and
    (not c or not d or not f or not g or h or not i or k or l or m or n) and
    (not b or not d or not f or not g or h or not i or not j or k or not l or m or n) and
    (not b or not d or not f or not g or h or not i or k or l or m or n) and
    (not f or not g or h or not i or not j or k or not l or not m or n) and
    (not f or not g or h or not i or k or l or not m or n)
  let f6 = (not b or not c or not f or g or h or k or not l or m) and
    (not f or g or h or k or not m or n)
  let f7 = (not c or not f or g or not h or k or not l or m or n) and
    (not f or not g or not h or k or not m or n) and
    (not k or not m or n or not o or not p)

  if f0: result += 1
  if f1: result += 2
  if f2: result += 4
  if f3: result += 8
  if f4: result += 16
  if f5: result += 32
  if f6: result += 64
  if f7: result += 128

proc triOnHighOe =
  let (_, traces, _, _) = setup()

  set traces[OE]
  for i in 0..7:
    check trip traces[&"F{i}"]
  clear traces[OE]

proc combinations =
  let (_, _, in_traces, out_traces) = setup()

  for i in 0u16..0xffffu16:
    let expected = get_expected i

    value_to_traces i, in_traces
    let actual = traces_to_value out_traces

    check actual == expected

proc all_tests* =
  suite "82S100 programmable logic array":
    test "all outputs tri-stated when OE is high": triOnHighOe()
    test "all logic combinations resolve correctly": combinations()

if is_main_module:
  all_tests()
