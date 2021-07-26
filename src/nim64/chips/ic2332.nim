# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

## An emulation of the 2332 4k x 8-bit ROM.
##
## This, along with the similar 2364, is far and away the simplest memory chip in the
## Commodore 64. With its full complement of address pins and full 8 data pins, there is no
## need to use multiple chips or to multiplex addresses.
##
## Timing of the read cycle (there is, of course, no write cycle in a read-only memory
## chip) is done with a pair of active-low chip select pins, CS1 and CS2. When both are
## low, the chip reads its address pins and makes the value at that location available on
## its data pins. In the C64, CS2 is tied to ground, meaning CS1 is the only pin that needs
## to be manipulated.
##
## The chip comes in a 24-pin dual in-line package with the following pin assignments.
## ```
##         +-----+--+-----+
##      A7 |1    +--+   24| Vcc
##      A6 |2           23| A8
##      A5 |3           22| A9
##      A4 |4           21| CS2
##      A3 |5           20| CS1
##      A2 |6           19| A10
##      A1 |7    2332   18| A11
##      A0 |8           17| D7
##      D0 |9           16| D6
##      D1 |10          15| D5
##      D2 |11          14| D4
##     GND |12          13| D3
##         +--------------+
## ```
## These pin assignments are explained below.
## 
## =====  =====  ==========================================================================
## Pin    Name   Description
## =====  =====  ==========================================================================
## 1      A7     Address pin 7.
## 2      A6     Address pin 6.
## 3      A5     Address pin 5.
## 4      A4     Address pin 4.
## 5      A3     Address pin 3.
## 6      A2     Address pin 2.
## 7      A1     Address pin 1.
## 8      A0     Address pin 0.
## 9      D0     Data pin 0.
## 10     D1     Data pin 1.
## 11     D2     Data pin 2.
## 12     GND    Electrical ground. Not emulated.
## 13     D3     Data pin 3.
## 14     D4     Data pin 4.
## 15     D5     Data pin 5.
## 16     D6     Data pin 6.
## 17     D7     Data pin 7.
## 18     A11    Address pin 11.
## 19     A10    Address pin 10.
## 20     CS1    Chip select pin 1.
## 21     CS2    Chip select pin 2.
## 22     A9     Address pin 9.
## 23     A8     Address pin 8.
## 24     VCC    +5V power supply. Not emulated.
## =====  =====  ==========================================================================
##
## In the Commodore 64, U5 is a 2332A (a variant with slightly faster data access). It's
## used to store information on how to display characters to the screen.

import sequtils
import strformat
import ../utils
import ../components/[chip, link]

chip Ic2332(memory: array[4096, uint8]):
  pins:
    input:
      # Address pins A0 - A11.
      A0: 8
      A1: 7
      A2: 6
      A3: 5
      A4: 4
      A5: 3
      A6: 2
      A7: 1
      A8: 23
      A9: 22
      A10: 19
      A11: 18

      # Chip select pins. When these are both low, a read cycle is executed based on the
      # address on pins A0-A11. When they're high, the data pins are tri-stated.
      CS1: 20
      CS2: 21

    output:
      # Data pins. Unlike other memory chips, these never change from being Output. No
      # writes are done to a ROM chip.
      D0: 9
      D1: 10
      D2: 11
      D3: 13
      D4: 14
      D5: 15
      D6: 16
      D7: 17
    
    unconnected:
      # Power supply and ground pins, not emulated
      VCC: 24
      GND: 12
  
  init:
    let addr_pins = map(to_seq 0..11, proc (i: int): Pin = pins[&"A{i}"])
    let data_pins = map(to_seq 0..7, proc (i: int): Pin = pins[&"D{i}"])

    # Reads the 8-bit value at the location indicated by the address pins and puts that value
    # on the data pins.
    proc read =
      value_to_pins memory[pins_to_value addr_pins], data_pins
    
    proc enable_listener(_: Pin) =
      if (lowp pins[CS1]) and (lowp pins[CS2]):
        read()
      elif (highp pins[CS1]) or (highp pins[CS2]):
        tri_pins data_pins
    
    add_listener pins[CS1], enable_listener
    add_listener pins[CS2], enable_listener
