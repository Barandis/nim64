# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ../../../src/nim64/utils

include ./common

proc initial =
  setup()

  check:
    (read_register TAHI) == 0xff
    (read_register TALO) == 0xff

proc dec_clock =
  setup()

  # start timer A
  write_register CRA, 0b00000001

  for i in 1..10:
    set traces[PHI2]
    check:
      (read_register TAHI) == 0xffu8
      (read_register TALO) == uint8 (0xff - i)
    clear traces[PHI2]

proc dec_cnt =
  setup()

  # set timer A to count CNT pulses and start it
  write_register CRA, 0b00100001

  for i in 1..10:
    set traces[CNT]
    check:
      (read_register TAHI) == 0xffu8
      (read_register TALO) == uint8 (0xff - i)
    clear traces[CNT]

proc rollover =
  setup()

  # force 0 into TALO
  write_register TALO, 0x00
  write_register CRA, 0b00010000
  check (read_register CRA) == 0b00000000  # setting LOAD doesn't write it

  # start timer A
  write_register CRA, 0b00000001

  # one ping only
  set traces[PHI2]
  check:
    (read_register TALO) == 0xff
    (read_register TAHI) == 0xfe

proc stop =
  setup()

  # start the timer
  write_register CRA, 0b00000001

  for i in 1..5:
    set traces[PHI2]
    check:
      (read_register TAHI) == 0xffu8
      (read_register TALO) == uint8 (0xff - i)
    clear traces[PHI2]
  
  # stop the timer
  write_register CRA, 0b00000000

  for _ in 1..5:
    set traces[PHI2]
    check:
      (read_register TAHI) == 0xffu8
      (read_register TALO) == 0xfau8
    clear traces[PHI2]

proc continuous_mode =
  setup()

  # force timer to 2 ticks remaining before underflow, start the timer
  write_register TALO, 0x02
  write_register TAHI, 0x00
  write_register CRA, 0b00010001

  for i in 0..3:
    # continuous mode causes the timer to reset at underflow, but it's only resetting to
    # 0x0002 here, the values we wrote into TAHI and TALO above
    set traces[PHI2]
    check:
      (read_register TAHI) == 0u8
      (read_register TALO) == uint8 (i mod 2 + 1)
    clear traces[PHI2]

proc one_shot_mode =
  setup()

  # force timer to 0x0002, set mode to one-shot, start the timer
  write_register TALO, 0x02
  write_register TAHI, 0x00
  write_register CRA, 0b00011001

  set traces[PHI2]
  check:
    (read_register TAHI) == 0x00
    (read_register TALO) == 0x01

  clear traces[PHI2]
  set traces[PHI2]
  check:
    # timer has underflowed and reset
    (read_register TAHI) == 0x00
    (read_register TALO) == 0x02
    # START bit has been cleared because of one-shot mode (LOAD bit was never written)
    (read_register CRA) == 0b00001000
  
  clear traces[PHI2]
  set traces[PHI2]
  check:
    # timer hasn't moved
    (read_register TAHI) == 0x00
    (read_register TALO) == 0x02

proc pb6_pulse =
  setup()

  # set timer to 0x0005, set to signal on PB6, turn timer on
  write_register TALO, 0x05
  write_register TAHI, 0x00
  write_register CRA, 0b00010011
  check:
    (read_register TAHI) == 0x00
    (read_register TALO) == 0x05
    (mode chip[PB6]) == Output
    lowp traces[PB6]
  
  for _ in 1..3:
    for _ in 1..4:
      # four cycles of decrementing
      set traces[PHI2]
      check lowp traces[PB6]
      clear traces[PHI2]
    set traces[PHI2]
    # underflow has happened, PB6 signals by going high for one cycle
    check highp traces[PB6]
    clear traces[PHI2]

proc pb6_toggle =
  setup()

  # set timer to 0x0005, set to signal on PB6, set output mode to toggle, turn timer on
  write_register TALO, 0x05
  write_register TAHI, 0x00
  write_register CRA, 0b00010111
  check:
    (read_register TAHI) == 0x00
    (read_register TALO) == 0x05
    (mode chip[PB6]) == Output
    lowp traces[PB6]
  
  for i in 0..2:
    for _ in 1..4:
      # four cycles of decrementing
      set traces[PHI2]
      check (level traces[PB6]) == float (i mod 2)
      clear traces[PHI2]
    set traces[PHI2]
    # underflow has happened, PB6 signals by going high for one cycle
    check (level traces[PB6]) == float (1 - (i mod 2))
    clear traces[PHI2]

proc pb6_overwrite =
  setup()

  # set PBON
  write_register CRA, 0b00000010
  check:
    (mode chip[PB6]) == Output
    lowp traces[PB6]
  
  # set to all inputs, including PB6, which will not take
  write_register DDRB, 0x00
  check (mode chip[PB6]) == Output

proc irq_unset =
  setup()

  # set timer to 0x0001 and start it, immediately undeflowing on next clock
  write_register TAHI, 0x00
  write_register TALO, 0x01
  write_register CRA, 0b00010001

  set traces[PHI2]
  # no IRQ signaled
  check trip traces[IRQ]
  # ICR read clears the register, so we have to store its value in a variable
  let icr = read_register ICR
  check:
    # TA bit set whether an IRQ was signaled or not
    bit_set(icr, 0)
    # IR bit is set only when an IRQ is signaled
    bit_clear(icr, 7)
    # ICR has been cleared by prior read
    (read_register ICR) == 0

proc irq_set =
  setup()
  
  # set timer to 0x0001 and start it, immediately undeflowing on next clock
  write_register TAHI, 0x00
  write_register TALO, 0x01
  write_register CRA, 0b00010001
  # set ICR to fire an IRQ on TA
  write_register ICR, 0b10000001

  set traces[PHI2]
  # this time, IRQ gets signaled
  check lowp traces[IRQ]
  # save ICR in a variable since reading it clears it
  let icr = read_register ICR
  check:
    # TA bit set whether an IRQ was signaled or not
    bit_set(icr, 0)
    # IR bit is set because an IRQ was signaled
    bit_set(icr, 7)
    # ICR has been cleared by prior read
    (read_register ICR) == 0

proc all_tests* =
  suite "6526 CIA Timer A":
    test "both timer registers set to all 1's initially": initial()
    test "timer decrements on PHI2 high by default": dec_clock()
    test "timer decrements on CNT high if set to do so": dec_cnt()
    test "TAHI decrements when TALO decrements at 0": rollover()
    test "timer does not decrement when stopped": stop()
    test "timer runs after underflow in continuous mode": continuous_mode()
    test "timer stops at underflow in one-shot mode": one_shot_mode()
    test "timer can be set to signal underflow on PB6": pb6_pulse()
    test "timer can be set to toggle PB6 on underflow": pb6_toggle()
    test "DDRB cannot overwrite PB6 mode when PBON set": pb6_overwrite()
    test "TA set on underflow, but no IRQ by default": irq_unset()
    test "TA and IR set, IRQ low on underflow if TA flag set": irq_set()

when is_main_module:
  all_tests()
