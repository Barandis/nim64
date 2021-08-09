# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ../../../src/nim64/utils
import ../../../src/nim64/chips/ic6567/raster

include ./common

proc activation_order =
  setup()
  var order = 0

  let phi0 = new_pin(1, "PHI0", Input)
  let ras = new_pin(2, "RAS", Input)
  let cas = new_pin(3, "CAS", Input)

  add_listener(phi0, proc (_: Pin) =
    order += 1
    check order == 1)
  add_listener(ras, proc (pin: Pin) =
    if lowp(pin):
      order += 1
      check order == 2)
  add_listener(cas, proc (pin: Pin) =
    if lowp(pin):
      order += 1
      check order == 3)

  add_pin(traces[PHI0], phi0)
  add_pin(traces[RAS], ras)
  add_pin(traces[CAS], cas)

  check:
    lowp(phi0)
    highp(ras)
    highp(cas)

  set(traces[PHIDOT])

  check:
    highp(phi0)
    lowp(ras)
    lowp(cas)
    order == 3

  order = 0
  clear(traces[PHIDOT])

  check:
    lowp(phi0)
    lowp(ras)
    lowp(cas)
    order == 3

proc phase =
  setup()
  let counter = counter(chip)

  check phase(counter) == 1
  set(traces[PHIDOT])
  check phase(counter) == 2
  clear(traces[PHIDOT])
  check phase(counter) == 1

proc cycle =
  setup()
  let counter = counter(chip)

  for i in 1u..65u:
    check cycle(counter) == i
    set(traces[PHIDOT])
    check cycle(counter) == i
    clear(traces[PHIDOT])
  check cycle(counter) == 1

proc raster =
  setup()
  let counter = counter(chip)

  for i in 0u..262u:
    check raster(counter) == i
    # Test that the raster registers have also updated
    let reg_raster =
      uint(read_register(RASTER)) + (bit_value(uint(read_register(CTRL1)), RST8) shl 8)
    check reg_raster == i
    for _ in 1..65:
      # We've already tested that cycling the clock pin updates the counter, but it gets
      # really slow for a lot of calls in debug mode so we'll just update directly from here
      # on out
      update(counter)
      update(counter)
  check raster(counter) == 0

proc bad_line_normal =
  setup()
  let counter = counter(chip)
  write_register(CTRL1, set_bit(read_register(CTRL1), DEN))

  for i in 0u..262u:
    let expected =
      raster(counter) >= 0x30 and
      raster(counter) <= 0xf7 and
      (raster(counter) and 0x07) == 0
    check bad_line(counter) == expected

    for _ in 1..65:
      update(counter)
      update(counter)

proc bad_line_den_cleared =
  setup()
  let counter = counter(chip)
  # Not setting DEN here, so it retains its default value of 0

  for i in 0u..262u:
    check not bad_line(counter)
    for _ in 1..65:
      update(counter)
      update(counter)

proc bad_line_y_scroll =
  setup()
  let counter = counter(chip)
  write_register(CTRL1, set_bit(read_register(CTRL1), DEN))

  for y in 0u8..7u8:
    write_register(CTRL1, (read_register(CTRL1) and 0b11111000) or y)
    for i in 0u..262u:
      let expected =
        raster(counter) >= 0x30 and
        raster(counter) <= 0xf7 and
        (raster(counter) and 0x07) == y
      check bad_line(counter) == expected

    for _ in 1..65:
      update(counter)
      update(counter)

proc raster_irq =
  setup()
  let counter = counter(chip)

  write_register(RASTER, 0x2f)      # set raster interrupt line to 0x2f
  write_register(IE, 1u8 shl ERST)  # enable the raster interrupt
  while not lowp(traces[IRQ]):      # loop until IRQ goes low
    update(counter)
    update(counter)

  # On raster line 0x2f, RASTER reads 0x2f and the RST8 bit of CTRL1 is 0
  check:
    read_register(RASTER) == 0x2f
    bit_clear(read_register(CTRL1), RST8)
    read_register(IR) == 0b11110001 # IIRQ (bit 7) and IRST (bit 0) set

  # Clear the interrupt register, this should also reset the IRQ pin
  write_register(IR, 0)
  check trip(traces[IRQ])

  # On the next cycle, the raster line should be the same but the interrupt should *not*
  # have fired again because it fires only once per line
  update(counter)
  update(counter)
  check:
    read_register(RASTER) == 0x2f
    trip(traces[IRQ])

  # Sets theg MSB of the raster latch (RST8 in CTRL1) along with the RASTER register. The
  # raster latch should now contain 0x101 (257).
  write_register(RASTER, 0x01)
  write_register(CTRL1, 0x80)
  while not lowp(traces[IRQ]):
    update(counter)
    update(counter)

  # On raster line 0x101, RASTER reads 0x01 and the RST8 bit of CTRL1 is 1
  check:
    read_register(RASTER) == 0x01
    bit_set(read_register(CTRL1), RST8)
    read_register(IR) == 0b11110001

proc raster_irq_disabled =
  setup()
  let counter = counter(chip)

  write_register(RASTER, 0x2f)      # set raster interrupt line to 0x2f
  # do NOT enable the raster interrupt here, leaves it disabled by default

  for _ in 0..262:
    check:
      trip(traces[IRQ])
      read_register(IR) == 0b01110000 # only unused bits are set
    for _ in 1..65:
      update(counter)
      update(counter)

proc all_tests* =
  suite "6567 raster counter and clock generator":
    test "PHI0, RAS, and CAS activate each half cycle in order": activation_order()
    test "phase alternates between 1 and 2 with every clock transition": phase()
    test "cycle increments every 2 phases": cycle()
    test "raster counter and register increment every 65 cycles": raster()
    test "bad lines happen every 8th visible raster line when DEN is set": bad_line_normal()
    test "bad lines don't happen when DEN is cleared": bad_line_den_cleared()
    test "bad lines shift according to y-scroll setting": bad_line_y_scroll()
    test "raster interrupt fires on latched line when enabled": raster_irq()
    test "raster interrupt does not fire when disabled": raster_irq_disabled()

when is_main_module:
  all_tests()
