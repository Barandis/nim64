# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

## An emulation of the 74139 dual 2-to-4 demultiplexer.
##
## The 74139 is one of the 7400-series TTL logic chips, consisting of a pair of 2-input,
## 4-output demultiplexers. There are four possible binary combinations on two pins (LL,
## HL, LH, and HH), and each of these combinations selects a different one of the output
## pins to activate. Each demultiplexer also has an enable pin.
##
## Most literature names the pins with numbers first. This makes sense since there are
## really two numbers that go into the output's name (the demultiplexer number and the
## output number) and having a letter separate them is quite readable. But since each of
## these pin names becomes the name of a constant, that scheme cannot be used here.
## Therefore each demultiplexer has two inputs starting with A and B, an active-low enable
## pin starting with G, and four inverted outputs whose names start with Y.
## 
## =====  =====  =====  =====  =====  =====  =====
## Gn     An     Bn     Y0n    Y1n    Y2n    Y3n
## =====  =====  =====  =====  =====  =====  =====
## H      X      X      **H**  **H**  **H**  **H**
## L      L      L      **L**  **H**  **H**  **H**
## L      H      L      **H**  **L**  **H**  **H**
## L      L      H      **H**  **H**  **L**  **H**
## L      H      H      **H**  **H**  **H**  **L**
## =====  =====  =====  =====  =====  =====  =====
##
## In the Commodore 64, the two demultiplexers are chained together by connecting one of
## the outputs from demux 1 to the enable pin of demux 2. The inputs are the address lines
## A8-A11, and the enable pin of demux 1 comes directly from the PLA's IO output. Thus the
## demultiplexers only do work when IO is selected, which requires that the address be from
## $D000 - $DFFF, among other things. A more specific table for this setup can thus be
## created.
## 
## =====  =====  =====  =====  =====  ==============  ==============
## IO     A8     A9     A10    A11    Address         Active Output
## =====  =====  =====  =====  =====  ==============  ==============
## H      X      X      X      X      N/A             **None**
## L      X      X      L      L      $D000 - $D3FF   **VIC**
## L      X      X      H      L      $D400 - $D7FF   **SID**
## L      X      X      L      H      $D800 - $DBFF   **Color RAM**
## L      L      L      H      H      $DC00 - $DCFF   **CIA 1**
## L      H      L      H      H      $DD00 - $DDFF   **CIA 2**
## L      L      H      H      H      $DE00 - $DEFF   **I/O 1**
## L      H      H      H      H      $DF00 - $DFFF   **I/O 2**
## =====  =====  =====  =====  =====  ==============  ==============
##
## The decoding resolution is only 2 hexadecimal digits for the VIC, SID, and color RAM and
## 3 hexadecimal digits for the CIAs and I/Os. This means that there will be memory
## locations that repeat. For example, the VIC only uses 64 addressable locations for its
## registers (47 registers and 17 more unused addresses) but gets a 1024-address block. The
## decoding can't tell the difference between $D000, $D040, $D080, and so on because it can
## only resolve the first two digits, so using any of those addresses will access the VIC's
## first register, meaning that it's mirrored 16 times. The same goes for the SID (29
## registers and 3 usused addresses, mirrored in 1024 addresses 32 times) and the CIAs (16
## registers mirrored in 256 addresses 16 times). The color RAM is not mirrored at all
## (though it does use only 1000 of its 1024 addresses) and the I/O blocks are free to be
## managed by cartridges as they like.
##
## The chip comes in a 16-pin dual in-line package with the following pin assignments.
## ```
##          +---+--+---+
##       G1 |1  +--+ 16| VCC
##       A1 |2       15| G2
##       B1 |3       14| A2
##      Y01 |4       13| B2
##      Y11 |5 74139 12| Y02
##      Y21 |6       11| Y12
##      Y31 |7       10| Y22
##      GND |8        9| Y32
##          +----------+
## ```
## GND and VCC are ground and power supply pins respectively, and they are not emulated.
##
## In the Commodore 64, U15 is a 74LS139 (a lower-power, faster variant whose emulation is
## the same). Its two demultiplexers are chained together to provide additional address
## decoding when the PLA's IO output is selected.

import strformat
import ../components/chip
import ../components/link

chip Ic74139:
  pins:
    input:
      # Demux 1 inputs
      G1: 1
      A1: 2
      B1: 3

      # Demux 2 inputs
      G2: 15
      A2: 14
      B2: 13
    
    output:
      # Demux 1 outputs
      Y01: 4
      Y11: 5
      Y21: 6
      Y31: 7

      # Demux 2 outputs
      Y02: 12
      Y12: 11
      Y22: 10
      Y32: 9
    
    unconnected:
      # Power supply and ground pins, not emulated.
      VCC: 16
      GND: 8
  
  init:
    proc dataListener(demux: int): proc (pin: Pin) =
      let gpin = pins[&"G{demux}"]
      let apin = pins[&"A{demux}"]
      let bpin = pins[&"B{demux}"]
      let y0pin = pins[&"Y0{demux}"]
      let y1pin = pins[&"Y1{demux}"]
      let y2pin = pins[&"Y2{demux}"]
      let y3pin = pins[&"Y3{demux}"]

      result = proc (_: Pin) =
        if (lowp gpin) and (lowp apin) and (lowp bpin): clear y0pin else: set y0pin
        if (lowp gpin) and (highp apin) and (lowp bpin): clear y1pin else: set y1pin
        if (lowp gpin) and (lowp apin) and (highp bpin): clear y2pin else: set y2pin
        if (lowp gpin) and (highp apin) and (highp bpin): clear y3pin else: set y3pin
    
    for i in 1..2:
      let listener = dataListener(i)
      pins[&"G{i}"].addListener(listener)
      pins[&"A{i}"].addListener(listener)
      pins[&"B{i}"].addListener(listener)
