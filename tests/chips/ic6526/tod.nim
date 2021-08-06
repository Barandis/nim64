# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ../../../src/nim64/utils

include ./common

proc bcd(hex: uint8): uint8 = ((hex div 10) shl 4) or (hex mod 10)

proc tenths_advance =
  setup()

  for i in 0u8..5u8:
    for _ in 1..5:
      set(traces[TOD])
      check read_register(TOD10TH) == i
      clear(traces[TOD])
    set(traces[TOD])
    check read_register(TOD10TH) == i + 1
    clear(traces[TOD])

proc tenths_advance_50 =
  setup()

  # set TOD clock to use 50Hz
  write_register(CRA, 0b10000000)

  for i in 0u8..5u8:
    for _ in 1..4:
      set(traces[TOD])
      check read_register(TOD10TH) == i
      clear(traces[TOD])
    set(traces[TOD])
    check read_register(TOD10TH) == i + 1
    clear(traces[TOD])

proc seconds_advance =
  setup()

  for t in 0u8..9u8:
    check read_register(TOD10TH) == t
    check read_register(TODSEC) == 0u8
    # this loop cycles the clock 6 times, advancing the tenths once
    for _ in 1..6:
      set(traces[TOD])
      clear(traces[TOD])

  # 60 cycles have happened, clock should read 1 second
  check:
    read_register(TOD10TH) == 0u8
    read_register(TODSEC) == 1u8

proc bcd_seconds =
  setup()

  # set clock to 9.9 seconds
  write_register(TOD10TH, 0x09)
  write_register(TODSEC, 0x09)

  # 6 clock cycles, so 1 tenth, making the clock read 10 seconds
  for _ in 1..6:
    set(traces[TOD])
    clear(traces[TOD])

  check:
    read_register(TOD10TH) == 0u8
    # non-BCD would be 10 in decimal, or 0x0a in hex
    read_register(TODSEC) == 0x10u8

proc minutes_advance =
  setup()

  for s in 0u8..59u8:
    for t in 0u8..9u8:
      check:
        read_register(TOD10TH) == t
        read_register(TODSEC) == bcd(s)
      # this loop cycles the clock 6 times, advancing the tenths once
      for _ in 1..6:
        set(traces[TOD])
        clear(traces[TOD])

  # 3600 cycles have happened, clock should read 1 minute
  check:
    read_register(TOD10TH) == 0u8
    read_register(TODSEC) == 0u8
    read_register(TODMIN) == 1u8

proc bcd_minutes =
  setup()

  # set clock to 00:09:59.9
  write_register(TOD10TH, 0x09)
  write_register(TODSEC, 0x59)
  write_register(TODMIN, 0x09)

  # 6 clock cycles, so 1 tenth, making the clock read 10 minutes
  for _ in 1..6:
    set(traces[TOD])
    clear(traces[TOD])

  check:
    read_register(TOD10TH) == 0u8
    read_register(TODSEC) == 0u8
    # non-BCD would be 10 in decimal, or 0x0a in hex
    read_register(TODMIN) == 0x10u8

proc hours_advance =
  setup()

  for m in 0u8..59u8:
    for s in 0u8..59u8:
      for t in 0u8..9u8:
        check:
          read_register(TOD10TH) == t
          read_register(TODSEC) == bcd(s)
          read_register(TODMIN) == bcd(m)
        # this loop cycles the clock 6 times, advancing the tenths once
        for _ in 1..6:
          set(traces[TOD])
          clear(traces[TOD])

  # 216,000 cycles have happened, clock should read 1 hour
  check:
    read_register(TOD10TH) == 0u8
    read_register(TODSEC) == 0u8
    read_register(TODMIN) == 0u8
    read_register(TODHR) == 1u8

proc bcd_hours =
  setup()

  # set clock to 09:59:59.9
  write_register(TODHR, 0x09)
  write_register(TODMIN, 0x59)
  write_register(TODSEC, 0x59)
  write_register(TOD10TH, 0x09)

  # 6 clock cycles, so 1 tenth, making the clock read 10 hours
  for _ in 1..6:
    set(traces[TOD])
    clear(traces[TOD])

  check:
    # non-BCD would be 10 in decimal, or 0x0a in hex
    read_register(TODHR) == 0x10u8
    read_register(TODMIN) == 0u8
    read_register(TODSEC) == 0u8
    read_register(TOD10TH) == 0u8

proc am_to_pm =
  setup()

  # set clock to 11:59:59.9 AM
  write_register(TODHR, 0x11)
  write_register(TODMIN, 0x59)
  write_register(TODSEC, 0x59)
  write_register(TOD10TH, 0x09)

  # 6 clock cycles, so 1 tenth, making the clock read noon
  for _ in 1..6:
    set(traces[TOD])
    clear(traces[TOD])

  check:
    # bit 7 is the AM/PM flag, set to PM at noon
    read_register(TODHR) == set_bit(0x12u8, 7)
    read_register(TODMIN) == 0u8
    read_register(TODSEC) == 0u8
    read_register(TOD10TH) == 0u8

proc pm_to_am =
  setup()

  # set clock to 11:59:59.9 PM
  write_register(TODHR, set_bit(0x11u8, 7))
  write_register(TODMIN, 0x59)
  write_register(TODSEC, 0x59)
  write_register(TOD10TH, 0x09)

  # 6 clock cycles, so 1 tenth, making the clock read midnight
  for _ in 1..6:
    set(traces[TOD])
    clear(traces[TOD])

  check:
    # bit 7 is the AM/PM flag, clear to AM at midnight
    read_register(TODHR) == 0x12u8
    read_register(TODMIN) == 0u8
    read_register(TODSEC) == 0u8
    read_register(TOD10TH) == 0u8

proc latch =
  setup()

  write_register(TODHR, 0x12)
  write_register(TODMIN, 0x59)
  write_register(TODSEC, 0x59)
  write_register(TOD10TH, 0x09)

  # reading the hours register will pause register updates not not stop the clock
  discard read_register(TODHR)

  for _ in 1..6:
    set(traces[TOD])
    clear(traces[TOD])

  check:
    # current time is 1:00:00.0, register updates did not happen
    read_register(TODHR) == 0x12u8
    read_register(TODMIN) == 0x59u8
    read_register(TODSEC) == 0x59u8
    # reading the tenths register restores updates and sets registers to actual time
    read_register(TOD10TH) == 0u8
    read_register(TODSEC) == 0u8
    read_register(TODMIN) == 0u8
    read_register(TODHR) == 0x01u8

proc halt =
  setup()

  write_register TOD10TH, 0x09
  write_register TODSEC, 0x59
  write_register TODMIN, 0x59
  # writing to hours halts the clock until the next write to tenths
  write_register TODHR, 0x12

  # if the clock was merely latched, this would be enough to push it to 1:00:00.0
  for _ in 1..6:
    set(traces[TOD])
    clear(traces[TOD])

  # this write restarts the clock
  write_register(TOD10TH, 0x09)

  # had the clock been latched, the 6 cycles would have still pushed it to 1:00:00
  check:
    # but it was halted, so the 6 cycles had no effect
    read_register(TODHR) == 0x12u8
    read_register(TODMIN) == 0x59u8
    read_register(TODSEC) == 0x59u8
    read_register(TOD10TH) == 0x09u8

  # since the clock is running again, THIS will be enough to push it to 1:00:00.0
  for _ in 1..6:
    set(traces[TOD])
    clear(traces[TOD])

  check:
    read_register(TODHR) == 0x01u8
    read_register(TODMIN) == 0x00u8
    read_register(TODSEC) == 0x00u8
    read_register(TOD10TH) == 0x00u8

proc irq_unset_alarm =
  setup()

  # set the time to 12:59:59.9
  write_register(TODHR, 0x12)
  write_register(TODMIN, 0x59)
  write_register(TODSEC, 0x59)
  write_register(TOD10TH, 0x09)

  # setting this bit means that further writes will set the alarm, not the clock
  write_register(CRB, 0b10000000)

  # set the alarm to 1:00:00.0
  write_register(TODHR, 0x01)
  write_register(TODMIN, 0x00)
  write_register(TODSEC, 0x00)
  write_register(TOD10TH, 0x00)

  # confirm those writes did not affect the clock
  check:
    read_register(TODHR) == 0x12u8
    read_register(TODMIN) == 0x59u8
    read_register(TODSEC) == 0x59u8
    read_register(TOD10TH) == 0x09u8

  # 6 cycles makes time match alarm
  for _ in 1..6:
    set(traces[TOD])
    clear(traces[TOD])

  # read IRQ state and ICR into a variable because the read resets both
  let irq = level(traces[IRQ])
  let icr = read_register(ICR)

  check:
    # confirm time matches the alarm
    read_register(TODHR) == 1u8
    read_register(TODMIN) == 0u8
    read_register(TODSEC) == 0u8
    read_register(TOD10TH) == 0u8
    # ALRM bit is set
    bit_set(icr, 2)
    # IR bit is NOT set
    bit_clear(icr, 7)
    # IRQ did not fire
    nanp(irq)

proc irq_set_alarm =
  setup()

  # set the time to 12:59:59.9
  write_register(TODHR, 0x12)
  write_register(TODMIN, 0x59)
  write_register(TODSEC, 0x59)
  write_register(TOD10TH, 0x09)

  # setting this bit means that further writes will set the alarm, not the clock
  write_register(CRB, 0b10000000)

  # set the alarm to 1:00:00.0
  write_register(TODHR, 0x01)
  write_register(TODMIN, 0x00)
  write_register(TODSEC, 0x00)
  write_register(TOD10TH, 0x00)

  # set the ALRM bit in the ICR, which will make interrupts for alarms fire
  write_register(ICR, 0b10000100)

  # confirm those writes did not affect the clock
  check:
    read_register(TODHR) == 0x12u8
    read_register(TODMIN) == 0x59u8
    read_register(TODSEC) == 0x59u8
    read_register(TOD10TH) == 0x09u8

  # 6 cycles makes time match alarm
  for _ in 1..6:
    set(traces[TOD])
    clear(traces[TOD])

  # read IRQ level and ICR into a variable becuase the read resets both
  let irq = level(traces[IRQ])
  let icr = read_register(ICR)

  check:
    # confirm time matches the alarm
    read_register(TODHR) == 1u8
    read_register(TODMIN) == 0u8
    read_register(TODSEC) == 0u8
    read_register(TOD10TH) == 0u8
    # ALRM bit is set
    bit_set(icr, 2)
    # IR bit is set this time
    bit_set(icr, 7)
    # IRQ did fire this time
    irq == 0.0
    # ICR is reset
    read_register(ICR) == 0u8
    # IRQ is back to tri-state
    trip(traces[IRQ])


proc all_tests* =
  suite "6526 CIA time-of-day clock":
    test "tenths advance every 6 TOD pulses": tenths_advance()
    test "tenths advance every 5 TOD pulses when set to 50Hz": tenths_advance_50()
    test "seconds advance every 10 tenths": seconds_advance()
    test "seconds are counted in BCD": bcd_seconds()
    test "minutes advance every 60 seconds": minutes_advance()
    test "minutes are counted in BCD": bcd_minutes()
    test "hours advance every 60 minutes": hours_advance()
    test "hours are counted in BCD": bcd_hours()
    test "AM/PM flag is set at noon": am_to_pm()
    test "AM/PM flag is cleared at midnight": pm_to_am()
    test "time is latched when TODHR is read and until TOD10TH is read": latch()
    test "time is halted when TODHR is written and until TOD10TH is written": halt()
    test "sets ALRM but does not fire an IRQ when ARLM flag not set": irq_unset_alarm()
    test "sets ALRM and IR, fires IRQ when ALRM flag is set": irq_set_alarm()

when is_main_module:
  all_tests()
