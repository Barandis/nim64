# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import random
import ../../../src/nim64/utils

randomize()

include ./common

proc reset =
  setup()

  # set some random register values
  for i in 0..15: write_register(uint(i), uint8(rand(0xff)))

  # reset!
  clear(traces[RES])
  set(traces[RES])

  # Here are the rules we check for:
  # 1. Sets interval timer registers to max ($FF each)
  # 2. Clears all other registers ($00 each) *
  # 3. Clears the IRQ mask in the ICR latch (can't check this directly)
  # 4. Disconnects all data lines (output mode and tri-state)
  # 5. Sets SP and CNT as inputs
  # 6. Resets IRQ and PC outputs to their default values
  #
  # * Note that pins PA0-PA7 and PB0-PB7 are pulled up by internal resistors, which is
  #   emulated, so the PCR registers will read all 1's for unconnected lines on reset.

  check:
    mode(chip[SP]) == Input
    mode(chip[CNT]) == Input
    trip(traces[IRQ])
    highp(traces[PC])
  for i in 0..7:
    let name = "D" & $i
    check:
      mode(chip[name]) == Output
      trip(traces[name])

  # reading PRB will lower PC, so we already checked that
  for i in 0u..15u:
    if i <= PRB or (i >= TALO and i <= TBHI):
      check read_register(i) == 0xffu8
    else:
      check read_register(i) == 0x00u8

proc irq_unset_flag =
  setup()

  clear(traces[FLAG])
  check trip(traces[IRQ])
  let icr = read_register(ICR)
  check:
    bit_set(icr, 4)
    bit_clear(icr, 7)

proc irq_set_flag =
  setup()
  write_register(ICR, 0b10010000)

  clear(traces[FLAG])
  check lowp(traces[IRQ])
  let icr = read_register(ICR)
  check:
    bit_set(icr, 4)
    bit_set(icr, 7)
    # the register read resets these both
    trip(traces[IRQ])
    read_register(ICR) == 0


proc all_tests* =
  suite "6526 CIA miscellaneous":
    test "lowering RES resets the chip": reset()
    test "if flag not set, FLG set on lowering FLAG but no IRQ fired": irq_unset_flag()
    test "if flag set, FLG and IR set on lowering FLAG, IRQ fired": irq_set_flag()

when is_main_module:
  all_tests()
