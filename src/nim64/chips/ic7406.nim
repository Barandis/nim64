# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https:##opensource.org/licenses/MIT

## An emulation of the 7406 hex inverter.
##
## The 7406 is one of the 7400-series TTL logic chips, consisting of six single-input
## inverters. An inverter is the simplest of logic gates: if the input is low, the output
## is high, and vice versa.
##
## ======  ======
##  An     Yn    
## ======  ======
##  L      **H**
##  H      **L**
## ======  ======
##
## The chip comes in a 14-pin dual in-line package with the following pin assignments.
## ```
##         +---+--+---+
##      A1 |1  +--+ 14| Vcc
##      Y1 |2       13| A6
##      A2 |3       12| Y6
##      Y2 |4  7406 11| A5
##      A3 |5       10| Y5
##      Y3 |6        9| A4
##     GND |7        8| Y4
##         +----------+
## ```
## GND and Vcc are ground and power supply pins respectively, and they are not emulated.
##
## In the Commodore 64, U8 is a 7406. It's responsible for inverting logic signals that 
## are expected in the inverse they're given, such as the 6567's AEC signal being turned 
## into the inverse AEC signal for the 82S100.

import strformat
import ../components/[chip, link]

chip Ic7406:
  pins:
    input:
      # Input pins. In the TI data sheet, these are named "1A", "2A", etc., and the C64
      # schematic does not suggest names for them. Since these names are not legal
      # identifier names, I've switched the letter and number.
      A1: 1
      A2: 3
      A3: 5
      A4: 9
      A5: 11
      A6: 13
    
    output:
      # Output pins. Similarly, the TI data sheet refers to these as "1Y", "2Y", etc.
      Y1: 2
      Y2: 4
      Y3: 6
      Y4: 8
      Y5: 10
      Y6: 12
    
    unconnected:
      # Power supply and ground pins, not emulated
      VCC: 14
      GND: 7
  
  init:
    proc data_listener(gate: int): proc (pin: Pin) =
      let ypin = pins[&"Y{gate}"]
      result = proc (pin: Pin) =
        if highp(pin): clear(ypin) elif lowp(pin): set(ypin)

    for i in 1..6: add_listener(pins[&"A{i}"], data_listener(i))
