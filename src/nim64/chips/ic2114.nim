# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

## An emulation of the 2114 1k x 4 bit static RAM.
##
## Static RAM differs from dynamic RAM (the RAM generally used for computer memory) in that
## it doesn't require periodic refresh cycles in order to retain data. Since no reads or
## writes have to wait for these refresh cycles, static RAM is considerably faster than
## dynamic RAM.
##
## However, it's also considerably more expensive. For this reason, static RAM is generally
## only in use in particularly speed-sensitive applications and in relatively small
## amounts. For instance, modern CPU on-board cache RAM is static. The Commodore 64 uses it
## for color RAM, which is accessed by the VIC at a much higher speed than the DRAM is
## accessed by the CPU.
##
## The 2114 has 1024 addressable locations that hold 4 bits each. Since the Commodore 64
## has a fixed palette of 16 colors, 4 bits is all it needs. Therefore a single 2114 could
## store 1k of colors and it isn't necessary to use it with a second 2114 to store full
## 8-bit bytes.
##
## The timing of reads and writes is particularly simple. If the chip select pin CS is low,
## the 4 bits stored at the location given on its address pins is put onto the 4 data pins.
## If the write enable pin WE is also low, then the value on the 4 data pins is stored at
## the location given on its address pins. The CS pin can stay low for several cycles of
## reads and writes; it does not require CS to return to high to start the next cycle.
##
## The downside of this simple scheme is that care has to be taken to avoid unwanted
## writes. Address changes should not take place while both CS and WE are low; since
## address lines do not change simultaneously, changing addresses while both pins are low
## can and will cause data to be written to multiple addresses, potentially overwriting
## legitimate data. This is naturally emulated here for the same reason: the chip responds
## to address line changes, and those changes do not happen simultaneously.
##
## Aside from the active-low CS and WE pins, this simple memory device only has the
## necessary address pins to address 1k of memory and the four necessary bidirectional data
## pins. It's packaged in an 18-pin dual-inline package with the following pin assignments.
## ```
##         +---+--+---+
##      A6 |1  +--+ 18| Vcc
##      A5 |2       17| A7
##      A4 |3       16| A8
##      A3 |4       15| A9
##      A0 |5  2114 14| D0
##      A1 |6       13| D1
##      A2 |7       12| D2
##      CS |8       11| D3
##     GND |9       10| WE
##         +----------+
## ```
## These pin assignments are explained below.
##
## =====  =====  ==========================================================================
## Pin    Name   Description
## =====  =====  ==========================================================================
## 1      A6     Address pin 6.
## 2      A5     Address pin 5.
## 3      A4     Address pin 4.
## 4      A3     Address pin 3.
## 5      A0     Address pin 0.
## 6      A1     Address pin 1.
## 7      A2     Address pin 2.
## 8      CS     Chip select.
## 9      GND    Electrical ground. Not emulated.
## 10     WE     Write enable.
## 11     D3     Data pin 3.
## 12     D2     Data pin 2.
## 13     D1     Data pin 1.
## 14     D0     Data pin 0.
## 15     A9     Address pin 9.
## 16     A8     Address pin 8.
## 17     A7     Address pin 7.
## 18     VCC    +5V power supply. Not emulated.
## =====  =====  ==========================================================================                                      |
##
## In the Commodore 64, U6 is a 2114. As explained above, it was used strictly as RAM for
## storing graphics colors.

import sequtils
import strformat
import sugar
import ../utils
import ../components/[chip, link]

const
  A6*  = 1   ## The pin assignment for address pin 6.
  A5*  = 2   ## The pin assignment for address pin 5.
  A4*  = 3   ## The pin assignment for address pin 4.
  A3*  = 4   ## The pin assignment for address pin 3.
  A0*  = 5   ## The pin assignment for address pin 0.
  A1*  = 6   ## The pin assignment for address pin 1.
  A2*  = 7   ## The pin assignment for address pin 2.
  CS*  = 8   ## The pin assignment for the chip select pin.
  GND* = 9   ## The pin assignment for the ground pin.
  WE*  = 10  ## The pin assignment for the write enable pin.
  D3*  = 11  ## The pin assignment for data pin 3.
  D2*  = 12  ## The pin assignment for data pin 2.
  D1*  = 13  ## The pin assignment for data pin 1.
  D0*  = 14  ## The pin assignment for data pin 0.
  A9*  = 15  ## The pin assignment for address pin 9.
  A8*  = 16  ## The pin assignment for address pin 8.
  A7*  = 17  ## The pin assignment for address pin 7.
  VCC* = 18  ## The pin assignment for the +5V power supply pin.

chip Ic2114:
  pins:
    input:
      # Address pins A0 - A9.
      A0: 5
      A1: 6
      A2: 7
      A3: 4
      A4: 3
      A5: 2
      A6: 1
      A7: 17
      A8: 16
      A9: 15

      # Data pins. These change to Output mode when reads are being performed.
      D0: 14
      D1: 13
      D2: 12
      D3: 11

      # Chip select pin. Setting this to low is what begins a read or write cycle.
      CS: 8

      # Write enable pin. If this is low when CS goes low, then the cycle is a write cycle,
      # otherwise it's a read cycle.
      WE: 10

    unconnected:
      # Power suppply and ground pins. Not emulated.
      VCC: 18
      GND: 9

  init:
    let addr_pins = map(to_seq(0..9), i => pins[&"A{i}"])
    let data_pins = map(to_seq(0..3), i => pins[&"D{i}"])

    # Memory locations are all 4-bit, and we don't have a uint4, so we choose the smallest
    # size we *do* have. This wastes a bit of space but is addressable without using
    # conversions and complex indexing.
    var memory: array[1024, uint8]

    # Resolves the address on the address pins and then puts the value from that memory
    # location onto the data pins.
    proc read =
      mode_to_pins(Output, data_pins)
      let address = pins_to_value(addr_pins)
      let value = memory[address]
      value_to_pins(value, dataPins)

    # Resolves the address on the address pins and then puts the value from the data pins
    # into that memory location.
    proc write =
      mode_to_pins(Input, data_pins)
      let address = pins_to_value(addr_pins)
      let value = pins_to_value(data_pins)
      memory[address] = uint8(value)

    proc enable_listener(pin: Pin) =
      if highp(pin): mode_to_pins(Input, data_pins)
      elif lowp(pin):
        if highp(pins[WE]): read()
        elif lowp(pins[WE]): write()

    proc write_listener(pin: Pin) =
      if lowp(pins[CS]):
        if highp(pin): read()
        elif lowp(pin): write()

    proc address_listener(_: Pin) =
      if lowp(pins[CS]):
        if highp(pins[WE]): read()
        elif lowp(pins[WE]): write()

    add_listener(pins[CS], enable_listener)
    add_listener(pins[WE], write_listener)
    for pin in addr_pins: add_listener(pin, address_listener)
