# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https* =//opensource.org/licenses/MIT

# Pin names
const
  VSS*     = 1   ## The pin assignment for the 0V power supply (ground) pin.
  PA0*     = 2   ## The pin assignment for parallel port A pin 0.
  PA1*     = 3   ## The pin assignment for parallel port A pin 1.
  PA2*     = 4   ## The pin assignment for parallel port A pin 2.
  PA3*     = 5   ## The pin assignment for parallel port A pin 3.
  PA4*     = 6   ## The pin assignment for parallel port A pin 4.
  PA5*     = 7   ## The pin assignment for parallel port A pin 5.
  PA6*     = 8   ## The pin assignment for parallel port A pin 6.
  PA7*     = 9   ## The pin assignment for parallel port A pin 7.
  PB0*     = 10  ## The pin assignment for parallel port B pin 0.
  PB1*     = 11  ## The pin assignment for parallel port B pin 1.
  PB2*     = 12  ## The pin assignment for parallel port B pin 2.
  PB3*     = 13  ## The pin assignment for parallel port B pin 3.
  PB4*     = 14  ## The pin assignment for parallel port B pin 4.
  PB5*     = 15  ## The pin assignment for parallel port B pin 5.
  PB6*     = 16  ## The pin assignment for parallel port B pin 6.
  PB7*     = 17  ## The pin assignment for parallel port B pin 7.
  PC*      = 18  ## The pin assignment for the handshaking output pin.
  TOD*     = 19  ## The pin assignment for the time-of-day clock input pin.
  VCC*     = 20  ## The pin assignment for the +5V power supply pin.
  IRQ*     = 21  ## The pin assignment for the interrupt request pin.
  R_W*     = 22  ## The pin assignment for the read/write control pin.
  CS*      = 23  ## The pin assignment for the chip select pin.
  FLAG*    = 24  ## The pin assignment for the handshaking input pin.
  PHI2*    = 25  ## The pin assignment for the clock input pin.
  D7*      = 26  ## The pin assignment for data pin 7.
  D6*      = 27  ## The pin assignment for data pin 6.
  D5*      = 28  ## The pin assignment for data pin 5.
  D4*      = 29  ## The pin assignment for data pin 4.
  D3*      = 30  ## The pin assignment for data pin 3.
  D2*      = 31  ## The pin assignment for data pin 2.
  D1*      = 32  ## The pin assignment for data pin 1.
  D0*      = 33  ## The pin assignment for data pin 0.
  RES*     = 34  ## The pin assignment for the reset pin.
  A3*      = 35  ## The pin assignment for address pin 3.
  A2*      = 36  ## The pin assignment for address pin 2.
  A1*      = 37  ## The pin assignment for address pin 1.
  A0*      = 38  ## The pin assignment for address pin 0.
  SP*      = 39  ## The pin assignment for the serial port pin.
  CNT*     = 40  ## The pin assignment for the counter pin.

# Register names
const
  PRA*     = 0   ## Parallel data register A.
  PRB*     = 1   ## Parallel data register B.
  DDRA*    = 2   ## Data direction register A.
  DDRB*    = 3   ## Data direction register B.
  TALO*    = 4   ## Timer A low byte register.
  TAHI*    = 5   ## Timer A high byte register.
  TBLO*    = 6   ## Timer B low byte register.
  TBHI*    = 7   ## Timer B high byte register.
  TOD10TH* = 8   ## Time-of-day tenths of seconds register.
  TODSEC*  = 9   ## Time-of-day seconds register.
  TODMIN*  = 10  ## Time-of-day minutes register.
  TODHR*   = 11  ## Time-of-day hours register.
  SDR*     = 12  ## Serial data register.
  ICR*     = 13  ## Interrupt control register.
  CRA*     = 14  ## Control register A.
  CRB*     = 15  ## Control register B.

# Interrupt Control Register bits
const
  TA*      = 0   ## The timer A underflow interrupt bit of the `ICR` register.
  TB*      = 1   ## The timer B underflow interrupt bit of the `ICR` register.
  ALRM*    = 2   ## The TOD alarm interrupt bit of the `ICR` register.
  SPI*     = 3   ## The serial port interrupt bit of the `ICR` register.
  FLG*     = 4   ## The `FLAG` pin interrupt bit of the `ICR` register.
  IR*      = 7   ## The interrupt indicator bit of the `ICR` register (read-only).
  SC*      = 7   ## The set/clear bit of the `ICR` register (write-only).

# Control Register bits
const
  START*   = 0   ## The timer start bit of the `CRA` and `CRB` registers.
  PBON*    = 1   ## The `PB6`/`PB7` timer output bit of the `CRA` and `CRB` registers.
  OUTMODE* = 2   ## The timer output mode bit of the `CRA` and `CRB` registers.
  RUNMODE* = 3   ## The timer run mode bit of the `CRA` and `CRB` registers.
  LOAD*    = 4   ## The force load strobe bit of the `CRA` and `CRB` registers.
  INMODE*  = 5   ## The timer input mode bit of the `CRA` register.
  INMODE0* = 5   ## The low bit of the timer input mode of the `CRB` register.
  SPMODE*  = 6   ## The serial port direction bit of the `CRA` register.
  INMODE1* = 6   ## The high bit of the timer input mode of the `CRB` register.
  TODIN*   = 7   ## The TOD frequency bit of the `CRA` register.
  ALARM*   = 7   ## The TOD alarm selection bit of the `CRB` register.

# Other register bits
const
  PM*      = 7   ## The AM/PM bit of the `TODHR` register.