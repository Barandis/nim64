# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

## An emulation of the 4164 64k x 1 bit dynamic RAM.
##
## The 4164 is a basic DRAM chip that was used in a wide variety of home computers in the
## 1980's: the Apple IIe, IIc, and 128k Macintosh; the Atari 800XL; the Commodore 64 and
## 128; and the Radio Shack Color Computer 2. Later editions of the Apple IIc, Commodore
## 64, Commodore 128, and COCO2 switched to the 41464.
##
## This chip has a memory array of 65,536 bits, each associated with an individual memory
## address. Therefore, to use a 4164 in an 8-bit computer, 8 chips would be required to
## provide 64k of memory (128k Macintosh and Commodore 128 would therefore use 16 of these
## chips). Each chip was used for a single bit in the target address; bit 0 would be stored
## in the first 4164, bit 1 in the second 4164, and so on.
##
## Since the chip has only 8 address pins, an address has to be split into two parts,
## representing a row and a column (presenting the memory array as a physical 256-bit x
## 256-bit array). These row and column addresses are provided to the chip sequentially;
## the row address is put onto the address pins and  the active-low row address strobe pin
## RAS is set low, then the column address is put onto the address pins and the active-low
## column address strobe pin CAS is set low.
##
## The chip has three basic modes of operation, controlled by the active-low write-enable
## (WE) pin with some help from CAS. If WE is high, then the chip is in read mode after the
## address is set. If WE is low, the mode depends on whether WE went low before the address
## was set by putting CAS low; if CAS went low first, (meaning the chip was initially in
## read mode), setting WE low will start read-modify-write mode, where the value at that
## address is still available on the data-out pin (Q) even as the new value is set from the
## data-in pin (D). If WE goes low before CAS, then read mode is never entered and write
## mode is enabled instead. The value of D is still written to memory, but Q is
## disconnected and no data is available there.
##
## The Commodore 64 does not use read-modify-write mode. The WE pin is always set to its
## proper level before the CAS pin goes low.
##
## While WE and CAS control what is read from and/or written to the chip's memory, RAS is
## not needed for anything other than setting the row address. Hence RAS can remain low
## through multiple memory accesses, as long as its address is valid for all of them,
## allowing reads and writes to happen within a single 256-address page of memory without
## incurring the cost of resetting the row address. This doesn't happen in the C64; the
## 6567 VIC cycles the RAS line once every clock cycle.
##
## Unlike most other non-logic chips in the system, there is no dedicated chip-select pin.
## The combination of RAS and CAS can be regarded as such a pin, and it is used that way in
## the Commodore 64.
##
## The chip comes in a 16-pin dual in-line package with the following pin assignments.
## ```
##         +---+--+---+
##      NC |1  +--+ 16| VSS
##       D |2       15| CAS
##      WE |3       14| Q
##     RAS |4       13| A6
##      A0 |5  4164 12| A3
##      A2 |6       11| A4
##      A1 |7       10| A5
##     VCC |8        9| A7
##         +----------+
## ```
## These pin assignments are explained below.
##
## =====  =====  ==========================================================================
## Pin    Name   Description
## =====  =====  ==========================================================================
## 1      NC     No contact. This pin does nothing.
## 2      D      Data input.
## 3      WE     Write enable.
## 4      RAS    Row address strobe.
## 5      A0     Address pin 0.
## 6      A2     Address pin 2.
## 7      A1     Address pin 1.
## 8      VCC    +5V power supply. Not emulated.
## 9      A7     Address pin 7.
## 10     A5     Address pin 5.
## 11     A4     Address pin 4.
## 12     A3     Address pin 3.
## 13     A6     Address pin 6.
## 14     Q      Data output.
## 15     CAS    Column address strobe.
## 16     VSS    0V power supply (ground). Not emulated.
## =====  =====  ==========================================================================
##
## In the Commodore 64, U9, U10, U11, U12, U21, U22, U23, and U24 are 4164s, one for each
## of the 8 bits on the data bus.

import options
import sequtils
import strformat
import sugar
import ../utils
import ../components/[chip, link]

const
  NC*  = 1   ## The pin assignment for the no-contact pin.
  D*   = 2   ## The pin assignment for the data input pin.
  WE*  = 3   ## The pin assignment for the write enable pin.
  RAS* = 4   ## The pin assignment for the row address strobe pin.
  A0*  = 5   ## The pin assignment for address pin 0.
  A2*  = 6   ## The pin assignment for address pin 2.
  A1*  = 7   ## The pin assignment for address pin 1.
  VCC* = 8   ## The pin assignment for the +5V power supply pin.
  A7*  = 9   ## The pin assignment for address pin 7.
  A5*  = 10  ## The pin assignment for address pin 5.
  A4*  = 11  ## The pin assignment for address pin 4.
  A3*  = 12  ## The pin assignment for address pin 3.
  A6*  = 13  ## The pin assignment for address pin 6
  Q*   = 14  ## The pin assignment for the data output pin.
  CAS* = 15  ## The pin assignment for the column address strobe pin.
  VSS* = 16  ## The pin assignment for the ground pin.

chip Ic4164:
  pins:
    input:
      # The row address strobe. Setting this low latches the values of A0-A7, saving them
      # to be part of the address used to access the memory array.
      RAS: 4

      # The column address strobe. Setting this low latches A0-A7 into the second part of
      # the memory address. It also initiates read or write mode, depending on the level of
      # WE.
      CAS: 15

      # The write-enable pin. If this is high, the chip is in read mode; if it and CAS are
      # low, the chip is in either write or read-modify-write mode, depending on which pin
      # went low first.
      WE: 3

      # Address pins 0-7.
      A0: 5
      A1: 7
      A2: 6
      A3: 12
      A4: 11
      A5: 10
      A6: 13
      A7: 9

      # The data input pin. When the chip is in write or read-modify-write mode, the value
      # of this pin will be written to the appropriate bit in the memory array.
      D: 2

    output:
      # The data output pin. This is active in read and read-modify-write mode, set to the
      # value of the bit at the address latched by RAS and CAS. In write mode, it is
      # tri-stated.
      Q: 14

    unconnected:
      # Power supply and no-contact pins. These are not emulated.
      NC: 1
      VCC: 8
      VSS: 16

  init:
    let addr_pins = map(to_seq(0..7), i => pins[&"A{i}"])

    # One byte is used for each bit of memory. This is a waste of space, but memory is
    # cheap and this avoids the need for time-consuming translation and complex indexing.
    # Basically it's a trade of space for time, and time is much more important to us than
    # space.
    var memory: array[65536, uint8]

    # Latches for the row, column, and data values. These are all Option[uint] values that
    # can be set to `none`. Checks are not made for `none` in the procs below because those
    # procs should never be called without these latches having a value, so if there is a
    # failure on that count, it's a bug and the program *should* crash.
    var row = none(uint)
    var col = none(uint)
    var data = none(uint)

    # Reads the row and col and calculates the specific bit in the memory array to which
    # this row/col combination refers. The first element of the return value is the index of
    # the 32-bit number in the memory array where that bit resides; the second element is
    # the index of the bit within that 32-bit number.
    proc resolve: uint =
      result = (get(row) shl 8) or get(col)

    # Retrieves a single bit from the memory array and sets the level of the Q pin to the
    # value of that bit.
    proc read =
      let index = resolve()
      set_level(pins[Q], float(memory[index]))

    # Writes the value of the D pin to a single bit in the memory array. If the Q pin is
    # also connected, the value is also sent to it; this happens only in RMW mode and keeps
    # the input and output data pins synched.
    proc write =
      let index = resolve()
      let value = get(data)
      memory[index] = uint8(value)
      if not trip(pins[Q]): set_level(pins[Q], float(value))

    # Invoked when the RAS pin changes level. When it goes low, the current levels of the
    # A0-A7 pins are latched. The address is released when the RAS pin goes high.
    #
    # Since this is the only thing that RAS is used for, it can be left low for multiple
    # memory accesses if its bits of the address remain the same for those accesses. This
    # can speed up reads and writes within the same page by reducing the amount of setup
    # needed for those reads and writes. (This does not happen in the C64.)
    proc ras_listener(pin: Pin) =
      if lowp(pin): row = some(pins_to_value(addr_pins))
      elif highp(pin): row = none(uint)

    # Invoked when the CAS pin changes level.
    #
    # When CAS goes low, the current levels of the A0-A7 pins are latched in a smiliar way
    # to when RAS goes low. What else happens depends on whether the WE pin is low. If it
    # is, the chip goes into write mode and the value on the D pin is saved to a memory
    # location referred to by the latched row and column values. If WE is not low, read mode
    # is entered, and the value in that memory location is put onto the Q pin. (Setting the
    # WE pin low after CAS goes low sets read-modify-write mode; the read that CAS initiated
    # is still valid.)
    #
    # When CAS goes high, the Q pin is tri-stated and the latched column and data (if there
    # is one) values are cleared.
    proc cas_listener(pin: Pin) =
      if lowp(pin):
        col = some(pins_to_value(addr_pins))
        let we = pins[WE]
        if lowp(we):
          data = some(uint(level(pins[D])))
          write()
        elif highp(we):
          read()
      elif highp(pin):
        tri(pins[Q])
        col = none(uint)
        data = none(uint)

    # Invoked when the WE pin changes level.
    #
    # When WE is high, read mode is enabled (though the actual read will not be available
    # until both RAS and CAS are set low, indicating that the address of the read is valid).
    # The internal latched input data value is cleared.
    #
    # When WE goes low, the write mode that is enabled depends on whether CAS is already
    # low. If it is, the chip must have been in read mode and now moves into
    # read-modify-write mode. The data value on the Q pin remains valid, and the valus on
    # the D pin is latched and stored at the appropriate memory location.
    #
    # If CAS is still high when WE goes low, the Q pin is tri-stated. Nothing further
    # happens until CAS goes low; at that point, the chip goes into write mode (data is
    # written to memory but nothing is available to be read).
    proc write_listener(pin: Pin) =
      if lowp(pin):
        let cas = pins[CAS]
        if lowp(cas):
          data = some(uint(level(pins[D])))
          write()
        elif highp(cas):
          tri(pins[Q])
      elif highp(pin):
        data = none(uint)

    add_listener(pins[RAS], ras_listener)
    add_listener(pins[CAS], cas_listener)
    add_listener(pins[WE], write_listener)
