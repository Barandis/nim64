# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ../../../src/nim64/utils

include ./common

proc serial_in =
  setup()
  let data = 0x2f

  for i in countdown(7, 0):
    set_level traces[SP], float (data shr i and 1)
    set traces[CNT]
    clear traces[CNT]
  
  check (read_register SDR) == 0x2fu8

proc serial_in_overwrite =
  setup()
  let data = 0x2f
  write_register SDR, 0xa9

  for i in countdown(7, 0):
    set_level traces[SP], float (data shr i and 1)
    set traces[CNT]
    clear traces[CNT]
  
  check (read_register SDR) == 0x2fu8

proc serial_out =
  setup()
  let data = 0xafu8

  # set timer A to 0x0002, set serial port to output
  write_register TALO, 0x02
  write_register TAHI, 0x00
  write_register CRA, 0b01010001

  # it puts the data into the serial register
  write_register SDR, data

  # 8 loops for 8 bits, MSB first
  for bit in countdown(7, 0):
    # first underflow, CNT is high and SP is the bit value
    for _ in 1..2:
      set traces[PHI2]
      clear traces[PHI2]
    check:
      highp traces[CNT]
      (level traces[SP]) == float (data shr bit and 1)
    
    # second underflow, CNT drops (excpet on the last pass, as CNT stays high after a value
    # is done being set), SP retains its value
    for _ in 1..2:
      set traces[PHI2]
      clear traces[PHI2]
    check:
      (level traces[CNT]) == (if bit == 0: 1.0 else: 0.0)
      (level traces[SP]) == float (data shr bit and 1)

proc serial_ready =
  setup()
  let data = 0xac
  
  # set timer A to 0x0002, set serial port to output
  write_register TALO, 0x02
  write_register TAHI, 0x00
  write_register CRA, 0b01010001

  # drop a 0 into the serial register
  write_register SDR, 0

  # first cycle, before the first timer underflow. This pulls the data from the SDR and puts
  # it into the internal shift register, leaving us free to put something new into the SDR
  set traces[PHI2]
  clear traces[PHI2]
  check:
    lowp traces[SP]
    lowp traces[CNT]

  # drop a new byte of data into the SDR as the old one is being transmitted; this data will
  # automatically be sent once the first byte finishes
  write_register SDR, uint8 data

  # 31 more cycles (32 total) to shift out the 8 bits from the first byte. This comes from
  # the 2 cycles that the timer needs to underflow, times the 2 underflows that it takes to
  # transmit 1 bit, times 8 bits.
  for _ in 1..31:
    set traces[PHI2]
    clear traces[PHI2]
  
  # At this point, `data` is ready to shift out. We don't need to do anything to make that
  # happen since it was already in the SDR when the first byte completed. So we just do the
  # 8 loops.
  for bit in countdown(7, 0):
    # first underflow, CNT is high and SP is the bit value
    for _ in 1..2:
      set traces[PHI2]
      clear traces[PHI2]
    check:
      highp traces[CNT]
      (level traces[SP]) == float (data shr bit and 1)
    
    # second underflow, CNT drops (excpet on the last pass, as CNT stays high after a value
    # is done being set), SP retains its value
    for _ in 1..2:
      set traces[PHI2]
      clear traces[PHI2]
    check:
      (level traces[CNT]) == (if bit == 0: 1.0 else: 0.0)
      (level traces[SP]) == float (data shr bit and 1)

proc irq_unset_in =
  setup()
  let data = 0x30

  # receive the 8 bits on the SP pin
  for i in countdown(7, 0):
    set_level traces[SP], float (data shr i and 1)
    set traces[CNT]
    clear traces[CNT]
  
  # no IRQ has been fired
  check trip traces[IRQ]
  let icr = read_register ICR
  check:
    # SP bit is set
    bit_set(icr, 3)
    # IR bit is not set
    bit_clear(icr, 7)

proc irq_unset_out =
  setup()
  let data = 0xac

  # set timer A to 0x0002, set serial port to output, put data into SDR
  write_register TALO, 0x02
  write_register TAHI, 0x00
  write_register CRA, 0b01010001
  write_register SDR, uint8 data

  # send the 8 bits out the SP pin (32 cycles)
  for _ in 1..32:
    set traces[PHI2]
    clear traces[PHI2]

  # no IRQ has been fired
  check trip traces[IRQ]
  let icr = read_register ICR
  check:
    # SP bit is set
    bit_set(icr, 3)
    # IR bit is not set
    bit_clear(icr, 7)

proc irq_set_in =
  setup()
  let data = 0x30

  # set the SP flag in the ICR
  write_register ICR, 0b10001000

  # receive the 8 bits on the SP pin
  for i in countdown(7, 0):
    set_level traces[SP], float (data shr i and 1)
    set traces[CNT]
    clear traces[CNT]
  
  # IRQ has been fired
  check lowp traces[IRQ]
  let icr = read_register ICR
  check:
    # SP bit is set
    bit_set(icr, 3)
    # IR bit is set
    bit_set(icr, 7)
    # IRQ tri-state again after register read
    trip traces[IRQ]
    # register clear again after being read
    (read_register ICR) == 0

proc irq_set_out =
  setup()
  let data = 0xac

  # set the SP flag in the ICR
  write_register ICR, 0b10001000

  # set timer A to 0x0002, set serial port to output, put data into SDR
  write_register TALO, 0x02
  write_register TAHI, 0x00
  write_register CRA, 0b01010001
  write_register SDR, uint8 data

  # send the 8 bits out the SP pin (32 cycles)
  for _ in 1..32:
    set traces[PHI2]
    clear traces[PHI2]

  # IRQ has been fired
  check lowp traces[IRQ]
  let icr = read_register ICR
  check:
    # SP bit is set
    bit_set(icr, 3)
    # IR bit is set
    bit_set(icr, 7)
    # IRQ tri-state again after register read
    trip traces[IRQ]
    # register clear again after being read
    (read_register ICR) == 0


proc all_tests* =
  suite "6526 CIA serial port":
    test "receives serial input to SDR": serial_in()
    test "read overwrites any data in the SDR": serial_in_overwrite()
    test "sends data from SDR to SP pin": serial_out()
    test "starts the second byte if it's in SDR before the first one finishes": serial_ready()
    test "if flag not set, SP set on byte read but no IRQ fired": irq_unset_in()
    test "if flag not set, SP set on byte write but no IRQ fired": irq_unset_out()
    test "if flag set, SP and IR set on byte read, IRQ fired": irq_set_in()
    test "if flag set, SP and IR set on byte write, IRQ fired": irq_set_out()

if is_main_module:
  all_tests()
