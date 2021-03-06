# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

## An emulation of the 4066 quad bilateral switch.
##
## The 4066 is one of the 4000-series CMOS logic chips, consisting of four symmetrical
## analog switches. The data pins transfer data bidirectionally as long as their associated
## control pin is low. When the control pin goes high, no data can be passed through the
## switch.
##
## When the control pin returns to low, both data pins return to the level of the *last of
## them to be set*. This is a bit of a compromise necessitated by the fact that this is a
## digital simulation of an analog circuit, but it should be the most natural. Most use
## cases do not involve switching the direction that data flows through the switch
## regularly.
##
## There is no high-impedance state for the pins of this device. When the control pin his
## high, the data pins simply take on the level of whatever circuits they're connected to.
## This is emulated by changing their mode to `INPUT` so that they do not send signals but
## can still track changes on their traces.
##
## There is no consistency across datahsheets for naming the 4066's pins. Many sheets
## simply have some data pins marked "IN/OUT" and others marked "OUT/IN", but those don't
## work well as property names. For consistency with the rest of the logic chips in this
## module, the data pins have been named A and B, while thie control pin is named X. The A
## and B pins are completely interchangeable and do appear in different orders oon many
## datasheets; this particular arrangement (if not the pin names) is taken from the
## datasheet for the Texas Instruments CD4066B.
##
## The chip comes in a 14-pin dual in-line package with the following pin assignments.
## ```
##         +---+--+---+
##      A1 |1  +--+ 14| VDD
##      B1 |2       13| X1
##      B2 |3       12| X4
##      A2 |4  4066 11| A4
##      X2 |5       10| B4
##      X3 |6        9| B3
##     VSS |7        8| A3
##         +----------+
## ```
## VDD and VSS are power supply pins and are not emulated.
##
## This chip is unusual in that it's the only analog chip in the system as emulated (with
## the exception of the filter portion of the 6581). Even so, it works fine for switching
## digital signals as well, and one of the Commodore 64's two 4066's is in fact used as a
## digital switch.
##
## In the Commodore 64, U16 and U28 are 4066's. The former is used as a digital switch to
## control which processor has access to the color RAM's data pins, while the other is used
## as an analog switch to control which game port is providing paddle data to the 6581 SID.

import options
import sequtils
import strformat
import ../components/[chip, link]

const
  A1*  = 1   ## The pin assignment for switch 1's first I/O pin.
  B1*  = 2   ## The pin assignment for switch 1's second I/O pin.
  A2*  = 3   ## The pin assignment for switch 2's first I/O pin.
  B2*  = 4   ## The pin assignment for switch 2's second I/O pin.
  X2*  = 5   ## The pin assignment for switch 2's control pin.
  X3*  = 6   ## The pin assignment for switch 3's control pin.
  GND* = 7   ## The pin assignment for the ground pin.
  B3*  = 8   ## The pin assignment for switch 3's second I/O pin.
  A3*  = 9   ## The pin assignment for switch 3's first I/O pin.
  B4*  = 10  ## The pin assignment for switch 4's second I/O pin.
  A4*  = 11  ## The pin assignment for switch 4's first I/O pin.
  X4*  = 12  ## The pin assignment for switch 4's control pin.
  X1*  = 13  ## The pin assignment for switch 1's control pin.
  VCC* = 14  ## The pin assignment for the +5V power supply pin.

chip Ic4066:
  pins:
    input:
      # Control pins for each of the four switches
      X1: 13
      X2: 5
      X3: 6
      X4: 12

    bidi:
      # I/O pins for each of the four switches
      A1: 1
      B1: 2
      A2: 3
      B2: 4
      A3: 9
      B3: 8
      A4: 11
      B4: 10

    unconnected:
      # Power supply and ground pins, not emulated
      VDD: 14
      GND: 7

  init:
    var last = repeat(none(Pin), 4)

    proc control_listener(gate: int): proc (_: Pin) =
      let xpin = pins[&"X{gate}"]
      let apin = pins[&"A{gate}"]
      let bpin = pins[&"B{gate}"]

      result = proc (_: Pin) =
        if highp(xpin):
          set_mode(apin, Input)
          set_mode(bpin, Input)
        elif lowp(xpin):
          set_mode(apin, Bidi)
          set_mode(bpin, Bidi)

          let last_pin = last[gate - 1]
          if is_some(last_pin):
            let pin = get(last_pin)
            if trip(pin):
              clear(apin)
              clear(bpin)
            elif pin == apin:
              set_level(bpin, level(apin))
            else:
              set_level(apin, level(bpin))
          else:
            clear(apin)
            clear(bpin)

    proc data_listener(gate: int): proc (_: Pin) =
      let xpin = pins[&"X{gate}"]
      let apin = pins[&"A{gate}"]
      let bpin = pins[&"B{gate}"]

      result = proc (pin: Pin) =
        let out_pin = if pin == apin: bpin else: apin
        last[gate - 1] = some(pin)
        if lowp(xpin):
          set_level(out_pin, level(pin))

    for i in 1..4:
      add_listener(pins[&"X{i}"], control_listener(i))
      let listener = data_listener i
      add_listener(pins[&"A{i}"], listener)
      add_listener(pins[&"B{i}"], listener)
