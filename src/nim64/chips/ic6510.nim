# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https:#opensource.org/licenses/MIT

import ../components/[chip, link]

chip Ic6510:
  pins:
    input:
      # Input clock pin.
      PHI1: 1

      # Address enable control. When this is low, the CPU tri-states its busses to allow
      # other chips (namely, the VIC) to control them.
      AEC: 5

      # Interrupts. IRQ is a normal interrupt that can be masked (disabled) by setting the I
      # flag in the P register to 1. NMI is a non-maskable interrupt that will fire even if
      # the I flag is set.
      IRQ: 3
      NMI: 4

      # Ready signal. This is normally high. When it goes low, the CPU will complete its
      # remaining write instructions (there can be up to three in a row). It will then go
      # inactive until this pin goes high again.
      RDY: 2

      # Reset signal. When this goes low, the CPU will reset itself.
      RES: 40

    output:
      # Address pins A0-A15.
      A0: 7
      A1: 8
      A2: 9
      A3: 10
      A4: 11
      A5: 12
      A6: 13
      A7: 14
      A8: 15
      A9: 16
      A10: 17
      A11: 18
      A12: 19
      A13: 20
      A14: 22
      A15: 23

      # Data bus pins D0-D7. These are bidirectional, the direction depending on the R_W
      # pin.
      D0: 37
      D1: 36
      D2: 35
      D3: 34
      D4: 33
      D5: 32
      D6: 31
      D7: 30

      # I/O Port pins P0-P5. These are bidrectional, the direction depending on the settings
      # in the virtual register in memory address $0001. These pins constitute the major
      # difference between a 6502 and a 6510 and are vital to the C64's memory banking
      # mechanism.
      P0: 29
      P1: 28
      P2: 27
      P3: 26
      P4: 25
      P5: 24

      # Clock output. This simply passes on the signal from PHI1 to the rest of the system.
      PHI2: 39

      # Read/write control. This pin is used to inform memory devices whether the CPU
      # intends to read from them or write to them.
      R_W: 38

    unconnected:
      # Power supply and ground pins. These are not emulated.
      VCC: 6
      VSS: 21

  registers:
    # The numbering on registers is completely arbitrary. They are not addressable (at least
    # directly) from outside the chip, so numbers do not need to be given for addressing.
    # These are simply used to create the constants that can be used to refer to the
    # registers.
    A: 0     # Accumulator
    X: 1     # X index register
    Y: 2     # Y index register
    PCL: 3   # Program counter, lower 8 bits
    PCH: 4   # Program counter, upper 8 bits
    S: 5     # Stack pointer
    P: 6     # Processor status register
