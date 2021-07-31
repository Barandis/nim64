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
    read_register(TBHI) == 0xff
    read_register(TBLO) == 0xff

proc dec_clock =
  setup()

  # start timer B
  write_register(CRB, 0b00000001)

  for i in 1..10:
    set(traces[PHI2])
    check:
      read_register(TBHI) == 0xffu8
      read_register(TBLO) == uint8(0xff - i)
    clear(traces[PHI2])

proc dec_cnt =
  setup()

  # set timer B to count CNT pulses and start it
  write_register(CRB, 0b00100001)

  for i in 1..10:
    set(traces[CNT])
    check:
      read_register(TBHI) == 0xffu8
      read_register(TBLO) == uint8(0xff - i)
    clear(traces[CNT])

proc dec_under =
  setup()

  # set timer A to 0x0002 and start the timer
  write_register(TALO, 0x02)
  write_register(TAHI, 0x00)
  write_register(CRA, 0b00010001)
  # set timer B to decrement on timer A overflows, and start that timer too
  write_register(CRB, 0b01000001)

  for i in 1..10:
    # loop causes a timer A overflow and resets it back to 0x0002
    for _ in 1..2:
      set(traces[PHI2])
      clear(traces[PHI2])
    check:
      read_register(TBHI) == 0xffu8
      read_register(TBLO) == uint(0xff - i)

proc dec_cnt_under =
  setup()
  
  write_register(TALO, 0x02)
  write_register(TAHI, 0x00)
  write_register(CRA, 0b00010001)
  # set timer B to decrement on timer A overflows with CNT high, and start that timer too
  write_register(CRB, 0b01100001)

  clear(traces[CNT])
  for i in 1..10:
    # loop causes a timer A overflow and resets it back to 0x0002
    for _ in 1..2:
      set(traces[PHI2])
      clear(traces[PHI2])
    check:
      # timer B has not moved because CNT is low
      read_register(TBHI) == 0xffu8
      read_register(TBLO) == 0xffu8
  
  set(traces[CNT])
  for i in 1..10:
    # loop causes a timer A overflow and resets it back to 0x0002
    for _ in 1..2:
      set(traces[PHI2])
      clear(traces[PHI2])
    check:
      # this time timer B moves, because CNT is high
      read_register(TBHI) == 0xffu8
      read_register(TBLO) == uint(0xff - i)

proc rollover =
  setup()

  # force 0 into TBLO
  write_register(TBLO, 0x00)
  write_register(CRB, 0b00010000)
  check read_register(CRB) == 0b00000000  # setting LOAD doesn't write it

  # start timer B
  write_register(CRB, 0b00000001)

  # one ping only
  set(traces[PHI2])
  check:
    read_register(TBLO) == 0xff
    read_register(TBHI) == 0xfe

proc stop =
  setup()

  # start the timer
  write_register(CRB, 0b00000001)

  for i in 1..5:
    set(traces[PHI2])
    check:
      read_register(TBHI) == 0xffu8
      read_register(TBLO) == uint8(0xff - i)
    clear(traces[PHI2])
  
  # stop the timer
  write_register(CRB, 0b00000000)

  for _ in 1..5:
    set(traces[PHI2])
    check:
      read_register(TBHI) == 0xffu8
      read_register(TBLO) == 0xfau8
    clear(traces[PHI2])

proc continuous_mode =
  setup()

  # force timer to 2 ticks remaining before underflow, start the timer
  write_register(TBLO, 0x02)
  write_register(TBHI, 0x00)
  write_register(CRB, 0b00010001)

  for i in 0..3:
    # continuous mode causes the timer to reset at underflow, but it's only resetting to
    # 0x0002 here, the values we wrote into TBHI and TBLO above
    set(traces[PHI2])
    check:
      read_register(TBHI) == 0u8
      read_register(TBLO) == uint8(i mod 2 + 1)
    clear(traces[PHI2])

proc one_shot_mode =
  setup()

  # force timer to 0x0002, set mode to one-shot, start the timer
  write_register(TBLO, 0x02)
  write_register(TBHI, 0x00)
  write_register(CRB, 0b00011001)

  set(traces[PHI2])
  check:
    read_register(TBHI) == 0x00
    read_register(TBLO) == 0x01

  clear(traces[PHI2])
  set(traces[PHI2])
  check:
    # timer has underflowed and reset
    read_register(TBHI) == 0x00
    read_register(TBLO) == 0x02
    # START bit has been cleared because of one-shot mode (LOAD bit was never written)
    read_register(CRB) == 0b00001000
  
  clear(traces[PHI2])
  set(traces[PHI2])
  check:
    # timer hasn't moved
    read_register(TBHI) == 0x00
    read_register(TBLO) == 0x02

proc pb6_pulse =
  setup()

  # set timer to 0x0005, set to signal on PB7, turn timer on
  write_register(TBLO, 0x05)
  write_register(TBHI, 0x00)
  write_register(CRB, 0b00010011)
  check:
    read_register(TBHI) == 0x00
    read_register(TBLO) == 0x05
    mode(chip[PB7]) == Output
    lowp(traces[PB7])
  
  for _ in 1..3:
    for _ in 1..4:
      # four cycles of decrementing
      set(traces[PHI2])
      check lowp(traces[PB7])
      clear(traces[PHI2])
    set(traces[PHI2])
    # underflow has happened, PB7 signals by going high for one cycle
    check highp(traces[PB7])
    clear(traces[PHI2])

proc pb6_toggle =
  setup()

  # set timer to 0x0005, set to signal on PB7, set output mode to toggle, turn timer on
  write_register(TBLO, 0x05)
  write_register(TBHI, 0x00)
  write_register(CRB, 0b00010111)
  check:
    read_register(TBHI) == 0x00
    read_register(TBLO) == 0x05
    mode(chip[PB7]) == Output
    lowp(traces[PB7])
  
  for i in 0..2:
    for _ in 1..4:
      # four cycles of decrementing
      set(traces[PHI2])
      check level(traces[PB7]) == float(i mod 2)
      clear(traces[PHI2])
    set(traces[PHI2])
    # underflow has happened, PB7 signals by going high for one cycle
    check level(traces[PB7]) == float(1 - (i mod 2))
    clear(traces[PHI2])

proc pb6_overwrite =
  setup()

  # set PBON
  write_register(CRB, 0b00000010)
  check:
    mode(chip[PB7]) == Output
    lowp(traces[PB7])
  
  # set to all inputs, including PB7, which will not take
  write_register(DDRB, 0x00)
  check mode(chip[PB7]) == Output

proc irq_unset =
  setup()

  # set timer to 0x0001 and start it, immediately undeflowing on next clock
  write_register(TBHI, 0x00)
  write_register(TBLO, 0x01)
  write_register(CRB, 0b00010001)

  set(traces[PHI2])
  # no IRQ signaled
  check trip(traces[IRQ])
  # ICR read clears the register, so we have to store its value in a variable
  let icr = read_register(ICR)
  check:
    # TB bit set whether an IRQ was signaled or not
    bit_set(icr, 1)
    # IR bit is set only when an IRQ is signaled
    bit_clear(icr, 7)
    # ICR has been cleared by prior read
    read_register(ICR) == 0

proc irq_set =
  setup()
  
  # set timer to 0x0001 and start it, immediately undeflowing on next clock
  write_register(TBHI, 0x00)
  write_register(TBLO, 0x01)
  write_register(CRB, 0b00010001)
  # set ICR to fire an IRQ on TB
  write_register(ICR, 0b10000010)

  set(traces[PHI2])
  # this time, IRQ gets signaled
  check lowp(traces[IRQ])
  # save ICR in a variable since reading it clears it
  let icr = read_register(ICR)
  check:
    # TB bit set whether an IRQ was signaled or not
    bit_set(icr, 1)
    # IR bit is set because an IRQ was signaled
    bit_set(icr, 7)
    # ICR has been cleared by prior read
    read_register(ICR) == 0

proc all_tests* =
  suite "6526 CIA Timer B":
    test "both timer registers set to all 1's initially": initial()
    test "timer decrements on PHI2 high by default": dec_clock()
    test "timer decrements on CNT high if set to do so": dec_cnt()
    test "timer decrements on Timer A underflow if set to do so": dec_under()
    test "timer decrements on Timer A underflow with CNT set": dec_cnt_under()
    test "TBHI decrements when TBLO decrements at 0": rollover()
    test "timer does not decrement when stopped": stop()
    test "timer runs after underflow in continuous mode": continuous_mode()
    test "timer stops at underflow in one-shot mode": one_shot_mode()
    test "timer can be set to signal underflow on PB7": pb6_pulse()
    test "timer can be set to toggle PB7 on underflow": pb6_toggle()
    test "DDRB cannot overwrite PB7 mode when PBON set": pb6_overwrite()
    test "TB set on underflow, but no IRQ by default": irq_unset()
    test "TB and IR set, IRQ low on underflow if TB flag set": irq_set()

when is_main_module:
  all_tests()
