# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https:#opensource.org/licenses/MIT

import ./constants
import ../../utils
import ../../components/[link, pins, registers]

type RasterCounter* = ref object
  pins: Pins
  registers: Registers
  raster: uint
  cycle: uint
  phase: uint
  bad_line: bool
  den: bool
  update_raster: bool
  raster_latch: uint

proc new_raster_counter*(pins: Pins, registers: Registers): RasterCounter =
  RasterCounter(
    pins: pins,
    registers: registers,
    raster: RASTER_LINES_PER_FRAME,
    cycle: CYCLES_PER_LINE,
    phase: 2,
    bad_line: false,
    den: false,
    update_raster: false,
    raster_latch: 0,
  )

proc update*(counter: RasterCounter) =
  let pins = counter.pins
  let registers = counter.registers

  counter.update_raster = false
  # All of this just ensures that phase resets to 1 after reaching 2, cycle resets to 1
  # after cycle 65, and the raster line resets to 0 after raster line 262. Cycle numbers are
  # 1-based mostly because that's how they are in all of the timing diagrams I have
  # available, and phase is 1-based because the literature invariably talkes about "phase 1"
  # and "phase 2".
  if counter.phase == 2:
    counter.phase = 1
    counter.cycle += 1
    if counter.cycle > CYCLES_PER_LINE:
      counter.cycle = 1
      counter.raster += 1
      counter.update_raster = true
      if counter.raster >= RASTER_LINES_PER_FRAME:
        counter.raster = 0
  else:
    counter.phase = 2

  # Raster value is 9 bits - the MSB comes from the RST8 bit in the CTRL1 register; the
  # other 8 bits come from the RASTER register.
  if counter.update_raster:
    registers[RASTER] = uint8(counter.raster and 0xff)
    registers[CTRL1] = set_bit_value(registers[CTRL1], RST8, uint(counter.raster and 0x100) shr 8)

    # Fire an interrupt if the raster line has just changed to the one set via register
    # AND if the raster interrupt enable bit is set
    if counter.raster == counter.raster_latch and bit_set(registers[IE], ERST):
      registers[IR] = registers[IR] or (1 shl IIRQ) or (1 shl IRST)
      clear(pins[IRQ])

  # The value of the DEN (display enable) bit on raster line 0x30 is recorded and used for
  # the rest of the frame for determining whether a line is a bad line. (Whether the display
  # is enabled or not cannot be changed in the middle of a frame, even if the register value
  # itself changes in the middle of a frame.) This happens at an "arbitrary" cycle and phase
  # on line $30, so we just choose the first one.
  if counter.raster == RASTER_MIN_VISIBLE and counter.cycle == 1 and counter.phase == 1:
    counter.den = bit_set(registers[CTRL1], DEN)

  # From http:#www.zimmers.net/cbmpics/cbm/c64/vic-ii.txt:
  #
  # A Bad Line Condition is given at any arbitrary clock cycle, if at the negative edge of
  # ø0 at the beginning of the cycle RASTER >= $30 and RASTER <= $f7 and the lower three
  # bits of RASTER are equal to YSCROLL and if the DEN bit was set during an arbitrary cycle
  # of raster line $30.
  let yscroll = registers[CTRL1] and 0x07
  counter.bad_line =
    counter.raster >= RASTER_MIN_VISIBLE and
    counter.raster <= RASTER_MAX_VISIBLE and
    (counter.raster and 0x07) == yscroll and
    counter.den

proc set_raster_latch_low8*(counter: RasterCounter, value: uint) {.inline.} =
  counter.raster_latch = (counter.raster_latch and 0x100) or value

proc set_raster_latch_msb*(counter: RasterCounter, value: uint) {.inline.} =
  counter.raster_latch = set_bit_value(counter.raster_latch, 8, value)

proc raster*(counter: RasterCounter): uint {.inline.} =
  counter.raster

proc cycle*(counter: RasterCounter): uint {.inline.} =
  counter.cycle

proc phase*(counter: RasterCounter): uint {.inline.} =
  counter.phase

proc bad_line*(counter: RasterCounter): bool {.inline.} =
  counter.bad_line
