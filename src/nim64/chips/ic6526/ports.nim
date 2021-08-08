# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https:#opensource.org/licenses/MIT

# -------------------------------------------------------------------
# Data ports
#
# When an input pin of a data register has the data set to it change, it fires off a
# listener that changes the data in the register as well. Similarly, when data is pushed
# into a register, the output pins associated with the register are changed to reflect that
# new state. In other words, the contents of PRA and PRB are kept synched with PA0-PA7 and
# PB0-PB7, respectively.
#
# Because of this, nothing special has to be done when reading a data port register - the
# contents already match that of the pins. When writing, the output pins need to be set by
# the writing function.
#
# NOTE: only the parallel ports are handled here. Since the serial port is intimately linked
# to Timer A, its code appears in the timer file.
#
# The parallel ports on CIA 1 are used entirely for keyboard scanning. A program in the
# kernal ROM sends out bits from each of Port A's pins one at a time; any bit returning to
# Port B must mean that a key was pressed, and the pin that the bit appears on can be
# cross-referenced with the pin that the bit had gone out on to figure out which key was
# pressed. This mechanism is also used to scan joysticks in the same way, and PB6 and PB7's
# timer-out functions are used to control the transmission of the POT signals (paddles) to
# the SID.
#
# The parallel ports on CIA 2 have much more varied use. Port B (and PA2 from port A) are
# used for the parallel port provided at the User Port. Though it does not necessarily have
# to be so, this port is often used for RS-232 communications. When doing so, the pinouts
# look like this:
#
#     PA2: RS-232 Transmitted Data (Sout)
#     PB0: RS-232 Received Data (SIN)
#     PB1: RS-232 Request to Send (RTS)
#     PB2: RS-232 Data Terminal Read (DTR)
#     PB3: RS-232 Ring Indicator (RI)
#     PB4: RS-232 Carrier Detect (DCD)
#     PB6: RS-232 Clear to Send (CTS)
#     PB7: RS-232 Data Set Read (DSR)
#
# The remaining pins on Port A are used to service the C64's Serial Port (PA3...PA7) and to
# provide memory bank switching (effectively, address lines 14 and 15) for the VIC, which
# can on its own only access 16k of memory (PA0...PA1).

# The write functions have to set the values in the registers but then also set the same
# values to the associated pins. The masking ensures that pins that should not be writable -
# meaning pins designated as input by the DDR or pins designated as timer output pins by the
# control registers - are not modified one way or the other.

proc set_port_pins(pins: seq[Pin]; value, mask: uint) =
  for bit in 0..7:
    if bit_set(mask, uint bit):
      set_level(pins[bit], float(bit_value(value, bit)))

proc write_pra(value: uint8) =
  let mask = registers[DDRA]
  registers[PRA] = (registers[PRA] and not mask) or (value and mask)
  set_port_pins(pa_pins, value, mask)

proc write_prb(value: uint8) =
  let mask = registers[DDRB] and
    (if bit_set(registers[CRB], PBON): 0x7f else: 0xff) and
    (if bit_set(registers[CRA], PBON): 0xbf else: 0xff)
  registers[PRB] = (registers[PRB] and not mask) or (value and mask)
  set_port_pins(pb_pins, value, mask)
  clear(pins[PC])

# A read function is only necessary for port B, and only because reading the register lowers
# the PC pin for a cycle.
proc read_prb: uint8 =
  result = registers[PRB]
  clear(pins[PC])

# -------------------------------------------------------------------
# Data direction registers
#
# Reading from one of these simply returned its contents, so no special functions are
# needed. Writing changes the contents of the register normally, but it also sets the
# direction on the pins for the appropriate port. This is reasonably straightforward;
# setting a bit means the corresponding pin is an output, and clearing a bit means it is an
# input. The only exception is for bits 6 and 7 of port B; if the appropriate control flags
# are set, one or both of these may override the setting of DDRB to instead be an output for
# one of the timers.

proc write_ddra(value: uint8) =
  registers[DDRA] = value
  for bit in 0..7:
    set_mode(pins[&"PA{bit}"], if bit_set(value, uint(bit)): Output else: Input)

proc write_ddrb(value: uint8) =
  registers[DDRB] = value
  for bit in 0..7:
    if not (
      (bit == 6 and bit_set(registers[CRA], PBON)) or
      (bit == 7 and bit_set(registers[CRB], PBON))):
        set_mode(pins[&"PB{bit}"], if bit_set(value, uint(bit)): Output else: Input)

# Returns a closure that can be used as a listener. That closure sets a particular bit in
# the the given register if the listened-to pin is high and clears that same bit if the pin
# is low.
proc port_listener(index: int, bit: uint): proc (pin: Pin) =
  result = proc (pin: Pin) =
    if highp(pin):
      registers[index] = set_bit(registers[index], bit)
    elif lowp(pin):
      registers[index] = clear_bit(registers[index], bit)

for i in 0u..7u:
  add_listener(pa_pins[i], port_listener(PRA, i))
  add_listener(pb_pins[i], port_listener(PRB, i))

# Raises the PC pin every cycle, as reading or writing the PB register sets that pin low for
# one cycle
add_listener(pins[PHI2], proc (pin: Pin) =
  if highp(pin): set(pins[PC]))
