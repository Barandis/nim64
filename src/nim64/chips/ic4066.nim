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
import ../components/chip
import ../components/link

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
    var last = repeat(none Pin, 4)

    proc controlListener(gate: int): proc (_: Pin) =
      let xpin = pins[&"X{gate}"]
      let apin = pins[&"A{gate}"]
      let bpin = pins[&"B{gate}"]

      result = proc (_: Pin) =
        if highp xpin:
          setMode apin, Input
          setMode bpin, Input
        else:
          setMode apin, Bidi
          setMode bpin, Bidi

          let lastPin = last[gate - 1]
          if isSome lastPin:
            let pin = get lastPin
            if trip pin:
              clear apin
              clear bpin
            elif pin == apin:
              setLevel bpin, level apin
            else:
              setLevel apin, level bpin
          else:
            clear apin
            clear bpin
    
    proc dataListener(gate: int): proc (_: Pin) =
      let xpin = pins[&"X{gate}"]
      let apin = pins[&"A{gate}"]
      let bpin = pins[&"B{gate}"]

      result = proc (pin: Pin) =
        let outpin = if pin == apin: bpin else: apin
        last[gate - 1] = some pin
        if lowp xpin:
          setLevel outpin, level pin
    
    for i in 1..4:
      addListener pins[&"X{i}"], controlListener i
      let listener = dataListener i
      addListener pins[&"A{i}"], listener
      addListener pins[&"B{i}"], listener
