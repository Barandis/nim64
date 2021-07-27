# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https:#opensource.org/licenses/MIT

# -------------------------------------------------------------------
# Time-of-day clock
#
# This is a more human-usable clock than the microsecond timers. It stores parts of the
# current time in four registers, corresponding to hours, minutes, seconds, and tenths of
# seconds. It runs off 60Hz (default, can be set to 50Hz) pulses at the chip's TOD pin.
#
# If the hour is read, then the registers do not update further until the tenths of seconds
# are read (this keeps the time from advancing during the four reads, possibly creating
# reads that can be up to an hour off). The clock does continue running in this case, just
# in the background. If the hour is *written*, then the clock stops running entirely until
# the tenths of seconds are written.
#
# There is an alarm available, and it can be set by writing to the same TOD registers with
# the Alarm bit in Control Register B set. In this implementation the alarm is being kept in
# the latches.

# Adds 1 to a BCD number, accounting for carry. Rolling over the tens digit isn't
# implemented because we never have a number over 59 anyway.
proc bcd_inc(value: uint8): uint8 =
  var digit0 = (value and 0x0f) + 1
  var digit1 = (value and 0xf0) shr 4

  if digit0 == 0x0a:
    digit0 = 0
    digit1 += 1
  
  (digit1 shl 4) or digit0

# Tests a BCD number to see if it's greater than or equal to a decimal number.
proc bcd_gte(bcd, decimal: uint8): bool =
  decimal <= (bcd and 0x0f) + 10 * ((bcd and 0xf0) shr 4)

type TodState = tuple
  # Whether or not the TOD clock is running or updating its registers. Both of these `false`
  # is normal operation; `latched` being `true` means that the clock continues to run even
  # though it is not updating its registers as it does so, and `halted` being true means the
  # clock is not running at all.
  latched: bool
  halted: bool

  # Internal count of the number of TOD pulses since the last tenth-of-seconds update.
  pulses: int

  # Values of the actual running clock. These are necessary because the clock does not
  # always update its registers, so the values need to be kept somewhere. For convenience,
  # these are encoded as 8-bit unsigned numbers representing two BCD digits, the same format
  # used in the registers.
  #
  # Also just as with the registers, bit 7 of `hours` is the AM (0)/PM (1) flag.
  tenths: uint8
  seconds: uint8
  minutes: uint8
  hours: uint8

var tod: TodState = (false, false, 0, 0u8, 0u8, 0u8, 0u8)

# Increments the hours, handling both AM/PM and rolling over after 12.
proc inc_hours =
  let pm_mask = 1u8 shl PM
  tod.hours = bcd_inc tod.hours

  if (tod.hours and not pm_mask) == 0x12:
    tod.hours = uint8 toggle_bit(tod.hours, PM)
  elif bcd_gte(tod.hours and not pm_mask, 13):
    tod.hours = (tod.hours and pm_mask) or 1

# Increments the minutes, rolling over and incrementing the hours after 60.
proc inc_minutes =
  tod.minutes = bcd_inc tod.minutes
  if bcd_gte(tod.minutes, 60):
    tod.minutes = 0
    inc_hours()

# Increments the seconds, rolling over and incrementing the minutes after 60.
proc inc_seconds =
  tod.seconds = bcd_inc tod.seconds
  if bcd_gte(tod.seconds, 60):
    tod.seconds = 0
    inc_minutes()

# Increments the tehnts of seconds, rolling over and incrementing the seconds after 10.
proc inc_tenths =
  tod.tenths = bcd_inc tod.tenths
  if bcd_gte(tod.tenths, 10):
    tod.tenths = 0
    inc_seconds()

# Writes to the tenths-of-seconds register. Doing so will unlatch the clock, if it latched
# because of reading hours prior to now. If the ALARM bit is set, then this will set the
# tenths of seconds of the alarm rather than of the clock.
proc write_tenths(value: uint8) =
  let masked = value and 0x0f
  if bit_set(registers[CRB], ALARM):
    latches[TOD10TH] = masked
  else:
    registers[TOD10TH] = masked
    tod.tenths = masked
    tod.halted = false

# Reads the tenths-of-seconds register. In addition to returning the register value, this
# will cancel a latch that was in place and copy data to the registers from the internal
# state.
proc read_tenths: uint8 =
  if tod.latched:
    tod.latched = false
    registers[TOD10TH] = tod.tenths
    registers[TODSEC] = tod.seconds
    registers[TODMIN] = tod.minutes
    registers[TODHR] = tod.hours
  registers[TOD10TH]

# Writes to the seconds register. If the ALARM bit is set, then this will set the seconds
# of the alarm rather than of the clock.
proc write_seconds(value: uint8) =
  let masked = value and 0x7f
  if bit_set(registers[CRB], ALARM):
    latches[TODSEC] = masked
  else:
    registers[TODSEC] = masked
    tod.seconds = masked

# Writes to the minutes register. If the ALARM bit is set, then this will set the minutes
# of the alarm rather than of the clock.
proc write_minutes(value: uint8) =
  let masked = value and 0x7f
  if bit_set(registers[CRB], ALARM):
    latches[TODMIN] = masked
  else:
    registers[TODMIN] = masked
    tod.minutes = masked

# Writes to the hours register. If the ALARM bit is set, then this will set the hours
# of the alarm rather than of the clock. This write will also halt the clock until the next
# time the tenths are written.
proc write_hours(value: uint8) =
  let masked = value and 0x9f
  if bit_set(registers[CRB], ALARM):
    latches[TODHR] = masked
  else:
    registers[TODHR] = masked
    tod.hours = masked
    tod.halted = true

proc tod_reset=
  tod.latched = false
  tod.halted = false
  tod.pulses = 0
  tod.tenths = 0u8
  tod.seconds = 0u8
  tod.minutes = 0u8
  tod.hours = 0u8

# Reads the hours register. When this happens, the clock latches (so that consistent time
# can be read over several cycles) until TOD10TH is read again.
proc read_hours: uint8 =
  tod.latched = true
  registers[TODHR]

add_listener pins[TOD], proc (pin: Pin) =
  if (highp pin) and not tod.halted:
    tod.pulses += 1
    # runs if 1/10 second has elapsed, counting pulses for that time at either 50Hz or 60Hz
    if tod.pulses == (if bit_set(registers[CRA], TODIN): 5 else: 6):
      tod.pulses = 0
      inc_tenths()

      if not tod.latched:
        # Update registers with the new time
        registers[TOD10TH] = tod.tenths
        registers[TODSEC] = tod.seconds
        registers[TODMIN] = tod.minutes
        registers[TODHR] = tod.hours
      
      # If we've reached the alarm time, fire an interrupt if the ICR says so
      if (
        tod.tenths == latches[TOD10TH] and
        tod.seconds == latches[TODSEC] and
        tod.minutes == latches[TODMIN] and
        tod.hours == latches[TODHR]
      ):
        registers[ICR] = set_bit(registers[ICR], ALRM)
        if bit_set(latches[ICR], ALRM):
          registers[ICR] = set_bit(registers[ICR], IR)
          clear pins[IRQ]
