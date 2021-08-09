# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ../../../src/nim64/chips/ic6567/access
import ../../../src/nim64/chips/ic6567/memory
import ../../../src/nim64/chips/ic6567/raster

include ./common

when not defined(release):
  proc address_gen_internal =
    setup()

    let counter = counter(chip)
    let memory = memory(chip)

    # Register value puts the video matrix at $0400-$07FF and characters at $1000-$1FFF. The
    # values are not important for this test, but they are the default values in the C64.
    write_register(MEMPTR, 0x14)

    for _ in 1..4: update(counter)

    # Confirm that the updates have put us where we want, at cycle 3, phase 1 of the first
    # raster line.
    check:
      raster(counter) == 0
      cycle(counter) == 3
      phase(counter) == 1

    let (access, address) = generate_address(memory)

    # This address should represent a mob data pointer access to $07FC, the location of mob
    # 4's data pointer when the video matrix begins at $0400.
    check:
      access == MobPtr
      address == 0x7fc

proc address_gen_pins =
  setup()

  var ras_checked = false
  var cas_checked = false

  let ras = new_pin(1, "RAS", Input)
  let cas = new_pin(2, "CAS", Input)
  add_pin(traces[RAS], ras)
  add_pin(traces[CAS], cas)

  # Register value puts the video matrix at $0400-$07FF and characters at $1000-$1FFF. The
  # values are not important for this test, but they are the default values in the C64.
  write_register(MEMPTR, 0x14)

  cycle(traces[PHIDOT])
  set(traces[PHIDOT])
  # We're now at cycle 2 phase 2 of the first raster line, which is one phase *before* where
  # we want to be. Now we can set up the listeners (which we didn't want running on the
  # first three clock transitions) and clear PHIDOT to be at cycle 3 phase 1.

  proc ras_listener(pin: Pin) =
    if lowp(pin):
      # The full 12-bit address $07FC. (RAM will only see the lower 8 bits, $FC, while if
      # this was a read of color RAM or character ROM, those would see the full $07FC.)
      check traces_to_value(addr_traces) == 0b0111_1111_1100
      ras_checked = true

  proc cas_listener(pin: Pin) =
    if lowp(pin):
      # The remnants of the 12-bit address on A6 and higher (hasn't changed since RAS
      # assertion), along with bits 8-13 in the lower 6 bits. The `0111` in bits 8-11 is
      # therefore the same as the `0111` in bits 0-3. In the C64, RAM will only see the
      # lower 6 bits, $07, as bits 6 and 7 will be coming from CIA 1 as VA14 and VA15 and
      # control the 16k bank of memory that the VIC sees.
      #
      # Color RAM and character ROM will still see $07FC because the lowering of RAS also
      # triggers the latch U26 to keep the lower 8 bits on its outputs (which is what color
      # RAM and character ROM actually see) even while the signals behind them change. The
      # upper 4 bits are connected directly to color RAM and character ROM rather than going
      # through the latch, but their values are still the same as they were at RAS
      # assertion.
      check traces_to_value(addr_traces) == 0b0111_1100_0111
      cas_checked = true

  add_listener(ras, ras_listener)
  add_listener(cas, cas_listener)

  clear(traces[PHIDOT])

  # Checks of address values are done in the listeners. We make these checks just to be sure
  # that the listeners actually ran.
  check:
    ras_checked
    cas_checked

proc ba_good_line =
  setup()
  when not defined(release):
    let counter = counter(chip)

  # Set DEN so that bad lines happen
  write_register(CTRL1, 1u8 shl DEN)

  # move to raster line 49, the first visible good raster line
  for _ in 0..48:
    for _ in 1..65:
      cycle(traces[PHIDOT])

  when not defined(release):
    check:
      raster(counter) == 49
      cycle(counter) == 1
      phase(counter) == 1

  # BA should be high in every phase of a good line with no mobs
  for _ in 1..65:
    check highp(traces[BA])
    set(traces[PHIDOT])
    check highp(traces[BA])
    clear(traces[PHIDOT])

proc ba_bad_line =
  setup()
  when not defined(release):
    let counter = counter(chip)

  # Set DEN so that bad lines happen
  write_register(CTRL1, 1u8 shl DEN)

  # move to raster line 48, the first bad raster line
  for _ in 0..47:
    for _ in 1..65:
      cycle(traces[PHIDOT])

  when not defined(release):
    check:
      raster(counter) == 48
      cycle(counter) == 1
      phase(counter) == 1

  # BA should be high except in cycles 12-54
  for cycle in 1..65:
    let expected = if cycle < 12 or cycle > 54: 1.0 else: 0.0
    check level(traces[BA]) == expected
    set(traces[PHIDOT])
    check level(traces[BA]) == expected
    clear(traces[PHIDOT])

proc aec_good_line =
  setup()
  when not defined(release):
    let counter = counter(chip)

  # Set DEN so that bad lines happen
  write_register(CTRL1, 1u8 shl DEN)

  # move to raster line 49, the first visible good raster line
  for _ in 0..48:
    for _ in 1..65:
      cycle(traces[PHIDOT])

  when not defined(release):
    check:
      raster(counter) == 49
      cycle(counter) == 1
      phase(counter) == 1

  # AEC should match the clock in every phase of a good line with no mobs
  for _ in 1..65:
    check lowp(traces[AEC])
    set(traces[PHIDOT])
    check highp(traces[AEC])
    clear(traces[PHIDOT])

proc aec_bad_line =
  setup()
  when not defined(release):
    let counter = counter(chip)

  # Set DEN so that bad lines happen
  write_register(CTRL1, 1u8 shl DEN)

  # move to raster line 48, the first bad raster line
  for _ in 0..47:
    for _ in 1..65:
      cycle(traces[PHIDOT])

  when not defined(release):
    check:
      raster(counter) == 48
      cycle(counter) == 1
      phase(counter) == 1

  # AEC should match the clock except in cyucles 15-54, where it should be low
  for cycle in 1..65:
    # Always low in phase 1, same as clock
    check lowp(traces[AEC])
    set(traces[PHIDOT])

    # High in phase 2, same as clock, except in cycles 15-54
    let expected = if cycle < 15 or cycle > 54: 1.0 else: 0.0
    check level(traces[AEC]) == expected
    clear(traces[PHIDOT])

when not defined(release):
  proc read_mob_pointers =
    setup()
    let counter = counter(chip)
    let memory = memory(chip)

    write_register(MEMPTR, 0x14)

    # We want to get to cycle 60 to start from sprite 0 just to make things easier. This is
    # 59 cycles of 2 phases from where we are now.
    for _ in 1..118:
      update(counter)

    check:
      raster(counter) == 0
      cycle(counter) == 60
      phase(counter) == 1

    for num in 0u..7u:
      let (access, address) = generate_address(memory)
      check:
        access == MobPtr
        address == 0x7f8u + num

      # Update four times (two cycles) to the next mob pointer read
      for _ in 1..4: update(counter)

    check:
      raster(counter) == 1
      cycle(counter) == 11
      phase(counter) == 1

proc all_tests* =
  suite "6567 memory controller":
    when not defined(release):
      test "proper address and access type generated on raster line 1": address_gen_internal()
    test "proper address generated on raster line 1 via pins": address_gen_pins()
    test "BA stays high during an entire good line with no mobs": ba_good_line()
    test "BA low during cycles 12-54 on a bad line": ba_bad_line()
    test "AEC follows the clock during an entire good line with no mobs": aec_good_line()
    test "AEC low during cycles 15-54 on a bad line": aec_bad_line()
    when not defined(release):
      test "proper mob pointers read in cycles 60-65 and 1-10": read_mob_pointers()

when is_main_module:
  all_tests()
