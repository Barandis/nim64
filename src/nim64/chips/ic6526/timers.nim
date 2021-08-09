# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

type SpState = tuple
  # The shift register from which the value is sent out over the SP pin bit-by-bit. This is
  # the value in the shift register (`shift`) and the last bit to have been sent out
  # (`bit`).
  shift: uint8
  bit: uint

  # Flag to tell whether to skip transmission on the next undeflow. This happens every other
  # underflow (the send rate is defined to be half the underflow rate). If an undeflow is
  # skipped, the CNT pin will be cleared instead.
  skip: bool

  # Indicates whether transmission is finshed. This happens if the shift register has all 8
  # bits sent out and there is not a new 8 bits waiting in the SDR to be sent out.
  done: bool

  # Flag to indicate whether the value in the SDR is waiting to be sent out the serial
  # port.
  ready: bool

var sp: SpState = (0u8, 0u, false, true, false)

# --------------------------------------------------------------------------------------
# Serial port
#
# If the port is set to input, a bit is read into the shift register (MSB first) each time
# the CNT pin transitions high from an outside source. Once 8 bits have been read, the
# contents of the shift register are dumped into the Serial Data Register and an interrupt
# is fired off.
#
# If the port is set to output, the clock used will be Timer A. Every *other* time it
# underflows (the data rate out is half the Timer A underflow rate), the next bit (MSB
# first) will be put onto the SP pin and the CNT pin will go high. Once all 8 bits have been
# sent, an interrupt fires and, if new data had already been loaded into the SDR, the
# process will immediately repeat.
#
# The code for the serial port appears here because output is dependent upon the timers
# located here as well.

# Handles the shifting of bits out the serial port pin, as described above. This also
# controls the output on the CNT pin, which will alternate high to low each time this
# function is called.
proc handle_sp_out =
  if not sp.done:
    if sp.skip:
      # On skipped underflows, CNT is cleared in preparation for setting it on the next
      # underflow when data goes out the SP pin.
      clear pins[CNT]
    else:
      if sp.bit == 0:
        sp.bit = 8
      sp.bit -= 1

      # Put the next bit of the shift register on the SP pin and set the CNT pin to indicate
      # that new data is available
      set_level pins[SP], float bit_value(sp.shift, sp.bit)
      set pins[CNT]

      #  When the shift register has been completely transmitted:
      if sp.bit == 0:
        if sp.ready:
          # If there is a new value ready to be loaded into the shift register, do it
          sp.ready = false
          sp.shift = registers[SDR]
        else:
          # Otherwise clear the shift register and record that there is nothing new to
          # send
          sp.done = true
          sp.shift = 0

          # Set the interrupt bit and then fire off an interrupt if the ICR says to
          registers[ICR] = set_bit(registers[ICR], SPI)
          if bit_set(latches[ICR], SPI):
            registers[ICR] = set_bit(registers[ICR], IR)
            clear pins[IRQ]

    sp.skip = not sp.skip

proc write_sdr(value: uint8) =
  registers[SDR] = value
  # If the serial port is configured to send (i.e., if it's set to output mode and if Timer
  # A is set to continuous mode)
  if bit_set(registers[CRA], SPMODE) and bit_clear(registers[CRA], RUNMODE):
    if sp.done:
      sp.done = false
      sp.shift = value
    else:
      sp.ready = true

# Responds to the CNT pin transitioning high *if* the serial port is set to input mode. This
# will read a bit off the serial port into the internal serial shift register; once that
# shift register is full (i.e., once 8 bits have been read), the SDR is updated and an
# interrupt is potentially signalled.
proc serial_listener(pin: Pin) =
  # Only do anything if CNT is transitioning high and the serial port is set to input
  if (highp pin) and bit_clear(registers[CRA], SPMODE):
    if sp.bit == 0: sp.bit = 8
    sp.bit -= 1
    if highp pins[SP]: sp.shift = set_bit(sp.shift, sp.bit)

    # If the last bit of the byte has been read, push the byte to the SP register and, if
    # the ICR says so, fire off an IRQ
    if sp.bit == 0:
      registers[SDR] = sp.shift
      sp.shift = 0
      registers[ICR] = set_bit(registers[ICR], SPI)
      if bit_set(latches[ICR], SPI):
        registers[ICR] = set_bit(registers[ICR], IR)
        clear pins[IRQ]

add_listener pins[CNT], serial_listener

# --------------------------------------------------------------------------------------
# Timer B

# Handles an underflow of timer B. This is run any time timer B's counter reaches zero. It
# resets the timer to the value in its latch and does an number of optional things depending
# on register settings (e.g., manipulates the PB7 output, fires an interrupt, or resets the
# start bit if the timer is in one-shot mode).
proc underflow_timer_b =
  let crb = registers[CRB]

  # Set PB7 to appropriate value if on
  if bit_set(crb, PBON):
    if bit_set(crb, OUTMODE): toggle pins[PB7]
    else: set pins[PB7]

  #  Set the interrupt bit, and fire interrupt if the ICR says so
  registers[ICR] = set_bit(registers[ICR], TB)
  if bit_set(latches[ICR], TB):
    registers[ICR] = set_bit(registers[ICR], IR)
    clear pins[IRQ]

  # Reset register value to match the latch
  registers[TBLO] = latches[TBLO]
  registers[TBHI] = latches[TBHI]

  # Clear start bit if in one-shot mode
  if bit_set(crb, RUNMODE):
    registers[CRB] = clear_bit(crb, START)

# Called on clock to decrement timer B. This will call underflow_timer_b once both TBLO and
# TBHI are 0.
proc decrement_timer_b =
  registers[TBLO] = registers[TBLO] - 1u8
  if registers[TBLO] == 0 and registers[TBHI] == 0: underflow_timer_b()
  elif registers[TBLO] == 255: registers[TBHI] = registers[TBHI] - 1u8

# --------------------------------------------------------------------------------------
# Timer A

# Handles an underflow of timer A. This is run any time timer A's counter reaches zero. It
# resets the timer to the value in its latch and does an number of optional things depending
# on register settings (e.g., manipulates the PB6 output, fires an interrupt, or resets the
# start bit if the timer is in one-shot mode).
#
# Timer A can also be set to decrement timer B when the former reaches 0, letting the timers
# be chained together. This happens in this function as well.
#
# Notably, if the serial port is in output mode and timer A is in continuous mode, it is
# used as the baud rate generator for the serial port. In that case, underflow will call
# handle_sp_out, which will send a bit out the serial port (and set the CNT pin high) every
# *other* time it's called (data is shifted out the serial port at one-half the timer A
# underflow rate).
proc underflow_timer_a =
  let cra = registers[CRA]
  let crb = registers[CRB]

  # Set PB6 to appropriate level if on
  if bit_set(cra, PBON):
    if bit_set(cra, OUTMODE): toggle(pins[PB6])
    else: set(pins[PB6])

  # Decrement timer B if CRB says so
  if bit_set(crb, INMODE1):
    if (if bit_set(crb, INMODE0): highp(pins[CNT]) else: true): decrement_timer_b()

  # Potentially send a bit out the serial port if it is set to output mode and if the timer
  # is set to run continuously
  if bit_set(cra, SPMODE) and bit_clear(cra, RUNMODE): handle_sp_out()

  # Set the ICR bit, and fire interrupt if the ICR says so
  registers[ICR] = set_bit(registers[ICR], TA)
  if bit_set(latches[ICR], TA):
    registers[ICR] = set_bit(registers[ICR], IR)
    clear(pins[IRQ])

  #  Reset value to that in latch
  registers[TALO] = latches[TALO]
  registers[TAHI] = latches[TAHI]

  # Clear start bit if in one-shot mode
  if bit_set(cra, RUNMODE):
    registers[CRA] = clear_bit(cra, START)

# Called on clock to decrement timer A. This will call underflow_timer_a once both TALO and
# TAHI are 0.
proc decrement_timer_a =
  registers[TALO] = registers[TALO] - 1u8
  if registers[TALO] == 0 and registers[TAHI] == 0: underflow_timer_a()
  elif registers[TALO] == 255: registers[TAHI] = registers[TAHI] - 1u8

# --------------------------------------------------------------------------------------
# Timer Listeners

# Handles timer tasks that must be handled on each clock cycle. This does two things to each
# timer: 1) it decrements the timer register(s) if that timer is set to use clock pulses as
# input, and 2) it sets PB6 or PB7 to low if the timer is set to use that pin as an output
# *and* the output mode is pulse. Pulse output mode causes the PB6/7 pin to go high for one
# cycle; the underflow code handles setting it high, and this sets it back low on the next
# clock.
add_listener pins[PHI2], proc (pin: Pin) =
  if highp(pin):
    let cra = registers[CRA]
    let crb = registers[CRB]

    # Reset PB6 if on and output mode = pulse
    if bit_set(cra, PBON) and bit_clear(cra, OUTMODE):
      clear(pins[PB6])

    # Reset PB7 if on and output mode = pulse
    if bit_set(crb, PBON) and bit_clear(crb, OUTMODE):
      clear(pins[PB7])

    # Decrement Timer A if its input is clock pulses and timer is started
    if bit_set(cra, START) and bit_clear(cra, INMODE):
      decrement_timer_a()

    # Decrement Timer B if its input is clock pulses and timer is started
    if bit_set(crb, START) and bit_clear(crb, INMODE0) and bit_clear(crb, INMODE1):
      decrement_timer_b()

# Handles decrementing the timers if they're set to use CNT pulses as input.
add_listener(pins[CNT], proc (pin: Pin) =
  if highp(pin):
    let cra = registers[CRA]
    let crb = registers[CRB]

    # Decrement Timer A if its input is CNT pulses
    if bit_set(cra, START) and bit_set(cra, INMODE):
      decrement_timer_a()

    # Decrement Timer B if its input is CNT pulses
    if bit_set(crb, START) and bit_set(crb, INMODE0) and bit_clear(crb, INMODE1):
      decrement_timer_b())

# Resets our state object, called by chip-wide reset
proc timer_reset =
  sp.shift = 0u8
  sp.bit = 0u
  sp.skip = false
  sp.done = true
  sp.ready = false
