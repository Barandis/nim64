# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

## An emulation of the 74258 quad 2-to-1 multiplexer.
##
## The 74258 is one of the 7400-series TTL logic chips, consisting of four 2-to-1
## multiplexers. Each multiplexer is essentially a switch which uses a single, shared
## select signal to choose which of its two inputs to reflect on its output. Each output is
## tri-state.
##
## This chip is exactly the same as the 74257 except that this one has inverted outputs and
## this other doesn't.
##
## The inputs to each multiplexer are the A and B pins, and the Y pins are their outputs.
## The SEL pin selects between the A inputs (when SEL is low) and the B inputs (when SEL is
## high). This single pin selects the outputs for all four multiplexers simultaneously. The
## active low output-enable pin, OE, tri-states all four outputs when it's set high.
##
## =====  =====  =====  =====  =====
## OE     SEL    An     Bn     Yn
## =====  =====  =====  =====  =====
## H      X      X      X      **Z**
## L      L      L      X      **H**
## L      L      H      X      **L**
## L      H      X      L      **H**
## L      H      X      H      **L**
## =====  =====  =====  =====  =====
##
## The chip comes in a 16-pin dual in-line package with the following pin assignments.
## ```
##         +---+--+---+
##     SEL |1  +--+ 16| VCC
##      A1 |2       15| OE
##      B1 |3       14| A4
##      Y1 |4       13| B4
##      A2 |5 74258 12| Y4
##      B2 |6       11| A3
##      Y2 |7       10| B3
##     GND |8        9| Y3
##         +----------+
## ```
## GND and VCC are ground and power supply pins respectively, and they are not emulated.
##
## In the Commodore 64, U14 is a 74LS258 (a lower-power, faster variant whose emulation is
## the same). It's used to multiplex the upper two lines of the multiplexed address bus
## from the A6 and A7 lines from the 6567 VIC and the VA14 and VA15 lines from one of the
## 6526 CIAs.

import sequtils
import strformat
import ../components/[chip, link]

chip Ic74258:
  pins:
    input:
      # Select. When this is low, the Y output pins will take on the inverse of the value of
      # their A input pins. When this is high, the Y output pins will instead take on the
      # inverse of the value of their B input pins.
      SEL: 1

      # Output enable. When this is high, all of the Y output pins will be forced into
      # hi-z, whatever the values of their input pins.
      OE: 15

      # Multiplexer 1 inputs.
      A1: 2
      B1: 3

      # Multiplexer 2 inputs.
      A2: 5
      B2: 6

      # Multiplexer 3 inputs.
      A3: 11
      B3: 10

      # Multiplexer 4 inputs.
      A4: 14
      B4: 13

    output:
      # Outputs for multiplexers 1-4.
      Y1: 4
      Y2: 7
      Y3: 9
      Y4: 12
    
    unconnected:
      # Power supply and ground pins, not emulated.
      VCC: 16
      GND: 8
  
  init:
    proc data_listener(mux: int): proc (_: Pin) =
      let apin = pins[&"A{mux}"]
      let bpin = pins[&"B{mux}"]
      let ypin = pins[&"Y{mux}"]

      result = proc (_: Pin) =
        if highp(pins[OE]):
          tri(ypin)
        elif lowp(pins[OE]):
          if highp(pins[SEL]):
            if highp(bpin): clear(ypin) elif lowp(bpin): set(ypin)
          elif lowp(pins[SEL]):
            if highp(apin): clear(ypin) elif lowp(apin): set(ypin)
    
    proc control_listener(): proc (_: Pin) =
      let listeners = map(@[1, 2, 3, 4], proc (i: int): proc (_: Pin) = data_listener(i))
      result = proc (pin: Pin) =
        for listener in listeners: listener(pin)
    
    let listener = control_listener()
    add_listener(pins[SEL], listener)
    add_listener(pins[OE], listener)

    for i in 1..4:
      let listener = data_listener i
      add_listener(pins[&"A{i}"], listener)
      add_listener(pins[&"B{i}"], listener)
