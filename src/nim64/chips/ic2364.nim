# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

## An emulation of the 2364 8k x 8-bit ROM.
##
## This, along with the similar 2332, is far and away the simplest memory chip in the
## Commodore 64. With its full complement of address pins and full 8 data pins, there is no
## need to use multiple chips or to multiplex addresses.
##
## Timing of the read cycle (there is, of course, no write cycle in a read-only memory
## chip) is based solely on the chip select pin `CS`. When this pin goes low, the chip
## reads its address pins and makes the value at that location available on its data pins.
##
## The chip comes in a 24-pin dual in-line package with the following pin assignments.
## ```
##         +-----+--+-----+
##      A7 |1    +--+   24| Vcc
##      A6 |2           23| A8
##      A5 |3           22| A9
##      A4 |4           21| A12
##      A3 |5           20| CS
##      A2 |6           19| A10
##      A1 |7    2364   18| A11
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
## 20     CS     Chip select.
## 21     A12    Address pin 12.
## 22     A9     Address pin 9.
## 23     A8     Address pin 8.
## 24     VCC    +5V power supply. Not emulated.
## =====  =====  ==========================================================================
##
## In the Commodore 64, U3 and U4 are both 2364A's (a variant with slightly faster data
## access). U3 stores the BASIC interpreter and U4 stores the kernal.

import sequtils
import strformat
import sugar
import ../utils
import ../components/[chip, link]

const
  A7*  = 1   ## The pin assignment for address pin 7.
  A6*  = 2   ## The pin assignment for address pin 6.
  A5*  = 3   ## The pin assignment for address pin 5.
  A4*  = 4   ## The pin assignment for address pin 4.
  A3*  = 5   ## The pin assignment for address pin 3.
  A2*  = 6   ## The pin assignment for address pin 2.
  A1*  = 7   ## The pin assignment for address pin 1.
  A0*  = 8   ## The pin assignment for address pin 0.
  D0*  = 9   ## The pin assignment for data pin 0.
  D1*  = 10  ## The pin assignment for data pin 1.
  D2*  = 11  ## The pin assignment for data pin 2.
  GND* = 12  ## The pin assignment for the ground pin.
  D3*  = 13  ## The pin assignment for data pin 3.
  D4*  = 14  ## The pin assignment for data pin 4.
  D5*  = 15  ## The pin assignment for data pin 5.
  D6*  = 16  ## The pin assignment for data pin 6.
  D7*  = 17  ## The pin assignment for data pin 7.
  A11* = 18  ## The pin assignment for address pin 11.
  A10* = 19  ## The pin assignment for address pin 10.
  CS*  = 20  ## The pin assignment for the chip select pin.
  A12* = 21  ## The pin assignment for address pin 12.
  A9*  = 22  ## The pin assignment for address pin 9.
  A8*  = 23  ## The pin assignment for address pin 8.
  VCC* = 24  ## The pin assignment for the +5V power supply pin.

chip Ic2364(memory: array[8192, uint8]):
  pins:
    input:
      # Address pins A0 - A12.
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
      A12: 21

      # Chip select pins. When these is low, a read cycle is executed based on the
      # address on pins A0-A12. When it's high, the data pins are tri-stated.
      CS: 20

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
    let addr_pins = map(to_seq(0..12), i => pins[&"A{i}"])
    let data_pins = map(to_seq(0..7), i => pins[&"D{i}"])

    # Reads the 8-bit value at the location indicated by the address pins and puts that value
    # on the data pins.
    proc read = value_to_pins(memory[pins_to_value(addr_pins)], data_pins)

    proc enable_listener(pin: Pin) =
      if lowp(pin):
        read()
      elif highp(pin):
        tri_pins(data_pins)

    add_listener(pins[CS], enable_listener)
