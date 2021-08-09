# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# -------------------------------------------------------------------
# Interrupt Control Register
#
# Controls sending interrupts from the five sources available in the 6526: Timer A
# underflow, Timer B underflow, TOD alarm, serial port full/empty, and FLAG pin clearing.
# One bit in the register is assigned to each source; if an interrupt is generated, the bit
# corresponding to the source(s) will be set.
#
# Writing to the register is slightly more complicated. The write affects an internal latch
# rather than the register itself and sets or clears one or more bits; whether it is set or
# clear depends on bit 7 of the written value (1 = set, 0 = clear). Any set bit in the rest
# of the value determines *which* ICR bit is set or cleared (except for bits 5 and 6, which
# are ignored because there are only five settable bits). These bits then act as a mask; if
# the bit in this latch corresponding to the interrupt event is set, then the interrupt will
# fire. If that bit is not set, the interrupt will be ignored.
#
# When the register is read, it is cleared, so it is the responsibility of the reader to
# store this information elsewhere if it needs it. Reading the register also resets the IRQ
# pin.

proc read_icr: uint8 =
  result = registers[ICR]
  registers[ICR] = 0
  tri(pins[IRQ])

proc write_icr(value: uint8) =
  let masked = value and 0x1f
  if bit_set(value, SC):
    latches[ICR] = latches[ICR] or masked
  else:
    latches[ICR] = latches[ICR] and not masked

# -------------------------------------------------------------------
# Control registers A and B
#
# These two registers are primarily for controlling the two timers, though they also help
# control the serial port and the TOD alarm.

proc write_cra(value: uint8) =
  # The LOAD bit is a strobe and does not get recorded
  registers[CRA] = value and not (1u8 shl LOAD)

  # If PBON is set, PB6 becomes an output for Timer A. Otherwise, bit 6 of the DDRA
  # register controls it.
  if bit_set(value, PBON):
    set_mode(pins[PB6], Output)
    clear(pins[PB6])
  else:
    set_mode(pins[PB6], if bit_set(registers[DDRA], 6): Output else: Input)

  # If LOAD is set, the contents of the timer latch are forced into the timer register
  # immediately (normally the latches are loaded into the register on underflow).
  if bit_set(value, LOAD):
    registers[TALO] = latches[TALO]
    registers[TAHI] = latches[TAHI]

  # If SPMODE is set, the SP pin is set to output. Since the CNT pin is then used to signal
  # new data, it must also be set to output.
  if bit_set(value, SPMODE):
    set_mode(pins[SP], Output)
    set_mode(pins[CNT], Output)
    clear(pins[SP])
    clear(pins[CNT])
  else:
    set_mode(pins[SP], Input)
    set_mode(pins[CNT], Input)

proc write_crb(value: uint8) =
  # The LOAD bit is a strobe and does not get recorded
  registers[CRB] = value and not (1u8 shl LOAD)

  # If PBON is set, PB7 becomes an output for Timer A. Otherwise, bit 6 of the DDRB
  # register controls it.
  if bit_set(value, PBON):
    set_mode(pins[PB7], Output)
    clear(pins[PB7])
  else:
    set_mode(pins[PB7], if bit_set(registers[DDRB], 6): Output else: Input)

  # If LOAD is set, the contents of the timer latch are forced into the timer register
  # immediately (normally the latches are loaded into the register on underflow).
  if bit_set(value, LOAD):
    registers[TBLO] = latches[TBLO]
    registers[TBHI] = latches[TBHI]
