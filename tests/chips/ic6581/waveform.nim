# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ../../../src/nim64/utils
import ../../../src/nim64/chips/ic6581/waveform

proc setup: Waveform =
  let wv = new_waveform()
  wv

# Tests waveform output values for every clock cycle for a sawtooth wave with frequency
# register settings of 0x0100, 0x0200, 0x0400, and 0x0800.
proc sawtooth =
  let wv = setup()

  for f in [1u, 2u, 4u, 8u]:
    reset(wv)
    frelo(wv, 0)
    frehi(wv, f)
    vcreg(wv, 0x20)

    let inc = f shl 8
    var acc = 0u

    for _ in 1..4:
      for _ in 0..(0x1000000 div inc):
        clock(wv)
        acc += inc
        let expected = (acc shr 12) and 0xfff
        check output(wv) == expected

# Tests waveform output values for every clock cycle for a triangle wave with frequency
# register settings of 0x0100, 0x0200, 0x0400, and 0x0800.
proc triangle =
  let wv = setup()

  for f in [1u, 2u, 4u, 8u]:
    reset(wv)
    frelo(wv, 0)
    frehi(wv, f)
    vcreg(wv, 0x10)

    let inc = f shl 8
    var acc = 0u

    for _ in 1..4:
      for _ in 0..(0x1000000 div inc):
        clock(wv)
        acc += inc
        let expected = ((if bit_set(acc, 23): not acc else: acc) shr 11) and 0xfff
        check output(wv) == expected

# Tests waveform output values for every clock cycle for a pulse wave with frequency
# register settings of 0x0100, 0x0200, 0x0400, and 0x0800, each with pulse width register
# settings of the same four values.
proc pulse =
  let wv = setup()

  for f in [1u, 2u, 4u, 8u]:
    for p in [1u, 2u, 4u, 8u]:
      reset(wv)
      frelo(wv, 0)
      frehi(wv, f)
      pwlo(wv, 0)
      pwhi(wv, p)
      vcreg(wv, 0x40)

      let inc = f shl 8
      let pw = p shl 8
      var acc = 0u

      for _ in 1..4:
        for _ in 0..(0x1000000 div inc):
          clock(wv)
          acc += inc
          let expected = if ((acc shr 12) and 0xfff) < pw: 0xfffu else: 0x000u
          check output(wv) == expected

# Tests waveform output values for every clock cycle for a nosie wave with frequency
# register settings of 0x0100, 0x0200, 0x0400, and 0x0800.
proc noise =
  let wv = setup()

  for f in [1u, 2u, 4u, 8u]:
    reset(wv)
    frelo(wv, 0)
    frehi(wv, f)
    vcreg(wv, 0x80)

    let inc = f shl 8
    var acc = 0u
    var lfsr = 0x7ffff8u
    var last_clock = false

    for _ in 1..4:
      for _ in 0..(0x1000000 div inc):
        clock(wv)
        acc += inc

        let bit19 = bit_set(acc, 19)
        if not last_clock and bit19:
          lfsr = lfsr shl 1
          lfsr = lfsr or uint(bit_set(lfsr, 17) xor bit_set(lfsr, 22))
          lfsr = lfsr and 0x7fffff
        last_clock = bit19
        let expected = uint(bit_set(lfsr, 0)) shl 4 or
          uint(bit_set(lfsr, 2)) shl 5 or
          uint(bit_set(lfsr, 5)) shl 6 or
          uint(bit_set(lfsr, 9)) shl 7 or
          uint(bit_set(lfsr, 11)) shl 8 or
          uint(bit_set(lfsr, 14)) shl 9 or
          uint(bit_set(lfsr, 18)) shl 10 or
          uint(bit_set(lfsr, 20)) shl 11

        check output(wv) == expected

# Tests waveform output values for every clock cycle for a sawtooth wave with frequency
# register settings of 0x0100, 0x0200, 0x0400, and 0x0800, synched with another waveform
# generator using frequency register settings of 0x0080, 0x00a0, 0x00c0, and 0x00e0.
proc sync =
  let wv = setup()
  let sy = setup()
  sync(wv, sy)

  for f in [1u, 2u, 4u, 8u]:
    let inc = f shl 8

    for s in [0x80u, 0xa0u, 0xc0u, 0xe0u]:
      reset(wv)
      frelo(wv, 0)
      frehi(wv, f)
      vcreg(wv, 0x22)

      reset(sy)
      frelo(sy, s)
      frehi(sy, 0)
      # This one HAS to be set to sawtooth. We cannot peer directly into the accumulator,
      # which is what guides the sync timing, but using a sawtooth wave output gives us a
      # 12-bit version of the accumulator that includes the same MSB. For pure purposes of
      # sync without testing it, only the frequency matters and not the waveform.
      vcreg(sy, 0x20)

      var acc = 0u
      var msb = false

      for _ in 1..4:
        for _ in 0..(0x1000000 div inc):
          # For the purpose of testing exact numbers, we have to run the sync clock first.
          # When it comes to actual use, the sound difference between the two orders should
          # be indistinguisable.
          clock(sy)
          clock(wv)

          let new_msb = bit_set(output(sy), 11)
          acc = if not msb and new_msb: 0u else: acc + inc
          msb = new_msb

          let expected = (acc shr 12) and 0xfff
          check output(wv) == expected

# Tests waveform output values for every clock cycle for a triangle wave with frequency
# register settings of 0x0100, 0x0200, 0x0400, and 0x0800, ring modulated by another
# waveform generator using frequency register settings of 0x0080, 0x00a0, 0x00c0, and
# 0x00e0.
proc ring =
  let wv = setup()
  let sy = setup()
  sync(wv, sy)

  for f in [1u, 2u, 4u, 8u]:
    let inc = f shl 8

    for s in [0x80u, 0xa0u, 0xc0u, 0xe0u]:
      reset(wv)
      frelo(wv, 0)
      frehi(wv, f)
      vcreg(wv, 0x14)

      reset(sy)
      frelo(sy, s)
      frehi(sy, 0)
      # Again, for this test, this HAS to be set to sawtooth. See the sync test for the
      # reasoning.
      vcreg(sy, 0x20)

      var acc = 0u

      for _ in 1..4:
        for _ in 0..(0x1000000 div inc):
          # For the purpose of testing exact numbers, we have to run the sync clock first.
          # When it comes to actual use, the sound difference between the two orders should
          # be indistinguisable.
          clock(sy)
          clock(wv)

          acc += inc
          let msb = bit_set(acc, 23) xor bit_set(output(sy), 11)
          let expected = ((if msb: not acc else: acc) shr 11) and 0xfff
          check output(wv) == expected


proc all_tests* =
  suite "6581 waveform generator":
    test "sawtooth wave for multiple frequencies": sawtooth()
    test "triangle wave for multiple frequencies": triangle()
    test "pulse wave for multiple frequencies and pulse widths": pulse()
    test "noise wave for multiple frequencies": noise()
    test "synched sawtooth wave for multiple frequencies": sync()
    test "ring modulated triangle wave for multiple frequencies": ring()

if is_main_module:
  all_tests()
