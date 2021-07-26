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

import ../components/chip

from sequtils import map, toSeq
from strformat import `&`
from ../utils import modeToPins, pinsToValue, valueToPins
from ../components/link import Input, Output, Pin, addListener, lowp, highp

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
    let addrPins = map(toSeq 0..9, proc (i: int): Pin = pins[&"A{i}"])
    let dataPins = map(toSeq 0..3, proc (i: int): Pin = pins[&"D{i}"])

    var memory: array[512, uint16]

    proc resolve(address: uint): (uint, uint) =
      result = (address shr 1, (address and 1) * 4)

    proc read =
      modeToPins Output, dataPins
      let address = pinsToValue addrPins
      let (index, shift) = resolve address
      let value = (memory[index] and (0b1111u shl shift)) shr shift
      valueToPins value, dataPins
    
    proc write =
      modeToPins Input, dataPins
      let address = pinsToValue addrPins
      let (index, shift) = resolve address
      let value = pinsToValue dataPins
      let current = memory[index] and not (0b1111u shl shift)
      memory[index] = uint16 (current or (value shl shift))
    
    proc enableListener(pin: Pin) =
      if highp pin: modeToPins Input, dataPins
      elif lowp pin:
        if highp pins[WE]: read()
        else: write()
    
    proc writeListener(pin: Pin) =
      if lowp pins[CS]:
        if highp pin: read()
        else: write()
    
    proc addressListener(_: Pin) =
      if lowp pins[CS]:
        if highp pins[WE]: read()
        else: write()

    addListener pins[CS], enableListener
    addListener pins[WE], writeListener
    for pin in addrPins: addListener pin, addressListener
