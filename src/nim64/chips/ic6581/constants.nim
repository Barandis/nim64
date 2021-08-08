# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https =//opensource.org/licenses/MIT

# Pin names
const
  CAP1A*    = 1   ## The pin assignment for filter capacitor 1's first connection pin.
  CAP1B*    = 2   ## The pin assignment for filter capacitor 1's second connection pin.
  CAP2A*    = 3   ## The pin assignment for filter capacitor 2's first connection pin.
  CAP2B*    = 4   ## The pin assignment for filter capacitor 2's second connection pin.
  RES*      = 5   ## The pin assignment for the reset pin.
  PHI2*     = 6   ## The pin assignment for the clock input pin.
  R_W*      = 7   ## The pin assignment for the read/write control pin..
  CS*       = 8   ## The pin assignment for the chip select pin..
  A0*       = 9   ## The pin assignment for address pin 0.
  A1*       = 10  ## The pin assignment for address pin 1.
  A2*       = 11  ## The pin assignment for address pin 2.
  A3*       = 12  ## The pin assignment for address pin 3.
  A4*       = 13  ## The pin assignment for address pin 4.
  GND*      = 14  ## The pin assignment for the ground pin.
  D0*       = 15  ## The pin assignment for data pin 0.
  D1*       = 16  ## The pin assignment for data pin 1.
  D2*       = 17  ## The pin assignment for data pin 2.
  D3*       = 18  ## The pin assignment for data pin 3.
  D4*       = 19  ## The pin assignment for data pin 4.
  D5*       = 20  ## The pin assignment for data pin 5.
  D6*       = 21  ## The pin assignment for data pin 6.
  D7*       = 22  ## The pin assignment for data pin 7.
  POTY*     = 23  ## The pin assignment for the X potentiometer input pin.
  POTX*     = 24  ## The pin assignment for the Y potentiometer input pin.
  VCC*      = 25  ## The pin assignment for the +5V power supply pin.
  EXT*      = 26  ## The pin assignment for the external audio input pin.
  AUDIO*    = 27  ## The pin assignment for the audio output pin.
  VDD*      = 28  ## The pin assignment for the +12V power supply pin.

# Register names
const
  FRELO1*   = 0   ## Voice 1 frequency register (low 8 bits).
  FREHI1*   = 1   ## Voice 1 frequency register (high 8 bits).
  PWLO1*    = 2   ## Voice 1 pulse width register (low 8 bits).
  PWHI1*    = 3   ## Voice 1 pulse width register (high 4 bits).
  VCREG1*   = 4   ## Voice 1 control register.
  ATDCY1*   = 5   ## Voice 1 attack/decay register.
  SUREL1*   = 6   ## Voice 1 sustain/release register.
  FRELO2*   = 7   ## Voice 2 frequency register (low 8 bits).
  FREHI2*   = 8   ## Voice 2 frequency register (high 8 bits).
  PWLO2*    = 9   ## Voice 2 pulse width register (low 8 bits).
  PWHI2*    = 10  ## Voice 2 pulse width register (high 4 bits).
  VCREG2*   = 11  ## Voice 2 control register.
  ATDCY2*   = 12  ## Voice 2 attack/decay register.
  SUREL2*   = 13  ## Voice 2 sustain/release register.
  FRELO3*   = 14  ## Voice 3 frequency register (low 8 bits).
  FREHI3*   = 15  ## Voice 3 frequency register (high 8 bits).
  PWLO3*    = 16  ## Voice 3 pulse width register (low 8 bits).
  PWHI3*    = 17  ## Voice 3 pulse width register (high 4 bits).
  VCREG3*   = 18  ## Voice 3 control register.
  ATDCY3*   = 19  ## Voice 3 attack/decay register.
  SUREL3*   = 20  ## Voice 3 sustain/release register.
  CUTLO*    = 21  ## Filter cutoff register (low 3 bits).
  CUTHI*    = 22  ## Filter cutoff register (high 8 bits).
  RESON*    = 23  ## Filter control/resonance register.
  SIGVOL*   = 24  ## Filter select/master volume register.
  POTXR*    = 25  ## Potentiometer X register.
  POTYR*    = 26  ## Potentiometer Y register.
  OSC3*     = 27  ## Voice 3 oscillator output register.
  ENV3*     = 28  ## Voice 3 envelope output register.
  UNUSED1*  = 29  ## Unused register 1.
  UNUSED2*  = 30  ## Unused register 2.
  UNUSED3*  = 31  ## Unused register 3.

# Control register bits
const
  GATE*     = 0  ## The gate bit of each control register.
  SYNC*     = 1  ## The sync enable bit of each control register.
  RING*     = 2  ## The ring modulation enable bit of each control register.
  TEST*     = 3  ## The test bit of each control register.
  TRIANGLE* = 4  ## The triangle waveform bit of each control register.
  SAWTOOTH* = 5  ## The sawtooth waveform bit of each control register.
  PULSE*    = 6  ## The pulse waveform bit of each control register.
  NOISE*    = 7  ## The noise waveform bit of each control register.

# Filter control register bits
const
  FILTV1*   = 0  ## Voice 1 filter enable bit of the filter control register.
  FILTV2*   = 1  ## Voice 2 filter enable bit of the filter control register.
  FILTV3*   = 2  ## Voice 3 filter enable bit of the filter control register.
  FILTEXT*  = 3  ## External input filter enable bit of the filter control register.

# Filter select register bits
const
  FILTLP*   = 4  ## Low-pass filter enable bit of the filter select register.
  FILTBP*   = 5  ## Band-pass filter enable bit of the filter select register.
  FILTHP*   = 6  ## High-pass filter enable bit of the filter select register.
  DSCNV3*   = 7  ## Voice 3 disconnection bit of the filter select register.
