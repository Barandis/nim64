# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

## An emulation of the 74373 octal D-type transparent latch.
##
## The 74373 is one of the 7400-series TTL logic chips, consisting of eight transparent
## latches. These latches normally allow data to flow freely from input to output, but when
## the latch enable pin `LE` is set to low, the output is latched. That means it retains
## its current state, no matter what the input pins do in the meantime. Once `LE` goes high
## again, the outputs once more reflect their inputs.
##
## Since this chip is most often used in bus-type applications, the pins are named using
## more of a bus-type convention. The inputs are D and the outputs are Q, and the latches
## are numbered from 0 rather than from 1.
##
## The chip has an active-low output enable pin, OE. When this is high, all outputs are set
## to a high impedance state.
## 
## =====  =====  =====  ======
## OE     LE     Dn     Qn
## =====  =====  =====  ======
## H      X      X      **Z**
## L      H      L      **L**
## L      H      H      **H**
## L      L      X      **Q₀**
## =====  =====  =====  ======
##
## Q₀ means whatever level the pin was in the previous state. If the pin was high, then it
## remains high. If it was low, it remains low.
##
## The chip comes in a 20-pin dual in-line package with the following pin assignments.
## ```text
##         +---+--+---+
##      OE |1  +--+ 20| VCC
##      Q0 |2       19| Q7
##      D0 |3       18| D7
##      D1 |4       17| D6
##      Q1 |5       16| Q6
##      Q2 |6 74373 15| Q5
##      D2 |7       14| D5
##      D3 |8       13| D4
##      Q3 |9       12| Q4
##     GND |10      11| LE
##         +----------+
## ```
## GND and VCC are ground and power supply pins respectively, and they are not emulated.
##
## In the Commodore 64, U26 is a 74LS373 (a lower-power, faster variant whose emulation is
## the same). It's used to connect the multiplexed address bus to the lower 8 bits of the
## main address bus. It latches the low 8 bits of the multiplexed bus so that, when the
## lines are switched to the high 8 bits, those bits do not leak onto the low 8 bits of the
## main bus.

import options
import sequtils
import strformat
import ../components/[chip, link]

chip Ic74373:
  pins:
    input:
      # Output enable. When this is high, the outputs function normally according to their
      # inputs and LE. When this is low, the outputs are all hi-Z.
      OE: 1

      # Latch enable. When set high, data flows transparently through the device, with
      # output pins matching their input pins. When it goes low, the output pins remain in
      # their current state for as long as LE is low, no matter what the inputs do.
      LE: 11

      # Data input pins.
      D0: 3
      D1: 4
      D2: 7
      D3: 8
      D4: 13
      D5: 14
      D6: 17
      D7: 18

    output:
      # Data output pins.
      Q0: 2
      Q1: 5
      Q2: 6
      Q3: 9
      Q4: 12
      Q5: 15
      Q6: 16
      Q7: 19
    
    unconnected:
      # Power supply and ground pins, not emulated.
      VCC: 20
      GND: 10
  
  init:
    var latches = repeat(none(bool), 8)

    proc data_listener(latch: int): proc (_: Pin) =
      let qpin = pins[&"Q{latch}"]
      result = proc (pin: Pin) =
        if (highp pins[LE]) and (lowp pins[OE]):
          if highp pin: set qpin elif lowp pin: clear qpin
    
    proc latch_listener(pin: Pin) =
      if highp pin:
        for i in 0..7:
          let dpin = pins[&"D{i}"]
          let qpin = pins[&"Q{i}"]
          if highp dpin: set qpin elif lowp dpin: clear qpin
          latches[i] = none bool
      elif lowp pin:
        for i in 0..7:
          latches[i] = some highp pins[&"D{i}"]
    
    proc enable_listener(pin: Pin) =
      if highp pin:
        for i in 0..7:
          tri pins[&"Q{i}"]
      elif lowp pin:
        let latched = lowp pins[LE]

        for i in 0..7:
          let qpin = pins[&"Q{i}"]
          if latched:
            if (is_some latches[i]) and (get latches[i]): set qpin else: clear qpin
          else:
            if highp pins[&"D{i}"]: set qpin elif lowp pins[&"D{i}"]: clear qpin
    
    for i in 0..7: add_listener pins[&"D{i}"], data_listener i
    add_listener pins[LE], latch_listener
    add_listener pins[OE], enable_listener
