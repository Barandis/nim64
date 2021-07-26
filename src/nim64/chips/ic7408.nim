# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

## An emulation of the 7408 quad two-input AND gate.
##
## The 7408 is one of the 7400-series TTL logic circuits, consisting of four dual-input 
## AND gates. An AND gate's output is high as long as all of its outputs are high; 
## otherwise the output is low.
##
## The A and B pins are inputs while the Y pins are the outputs.
## 
## ======  ======  ======
##  An     Bn      Yn    
## ======  ======  ======
##  L      L       **L**
##  L      H       **L**
##  H      L       **L**
##  H      H       **H**
## ======  ======  ======
## 
##
## The chip comes in a 14-pin dual in-line package with the following pin assignments.
## ``` 
##         +---+--+---+
##      A1 |1  +--+ 14| Vcc
##      B1 |2       13| B4
##      Y1 |3       12| A4
##      A2 |4  7408 11| Y4
##      B2 |5       10| B3
##      Y2 |6        9| A3
##     GND |7        8| Y3
##         +----------+
## ```
## GND and Vcc are ground and power supply pins respectively, and they are not emulated.
##
## In the Commodore 64, U27 is a 74LS08 (a lower-power, faster variant whose emulation is
## the same). It's used for combining control signals from various sources, such as the BA
## signal from the 6567 VIC and the DMA signal from the expansion port combining into the
## `RDY` signal for the 6510 CPU.

import strformat
import ../components/[chip, link]

chip Ic7408:
  pins:
    input:
      # Gates 1-4
      A1: 1
      B1: 2

      A2: 4
      B2: 5

      A3: 9
      B3: 10

      A4: 12
      B4: 13

    output:
      Y1: 3
      Y2: 6
      Y3: 8
      Y4: 11
    
    unconnected:
      VCC: 14
      GND: 7
  
  init:
    proc data_listener(gate: int): proc (pin: Pin) =
      let apin = pins[&"A{gate}"]
      let bpin = pins[&"B{gate}"]
      let ypin = pins[&"Y{gate}"]

      result = proc (pin: Pin) =
        if (highp apin) and (highp bpin): set ypin else: clear ypin
    
    for i in 1..4:
      let listener = data_listener i
      add_listener pins[&"A{i}"], listener
      add_listener pins[&"B{i}"], listener
