# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import tables
import sequtils
import strformat
import ../components/chip
import ../components/link

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
    +pins[Y1]
    +pins[Y2]
    +pins[Y3]
    +pins[Y4]
    +pins[Y5]
    +pins[Y6]

    proc dataListener(gate: int): proc (pin: Pin) =
      let ypin = pins[&"Y{gate}"]
      proc listener(pin: Pin) =
        ypin.level = if pin.high: 0 else: 1
      result = listener

    for i in 1..6: pins[&"A{i}"].addListener(dataListener(i))
