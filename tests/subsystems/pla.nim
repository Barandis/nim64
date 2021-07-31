# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Tests for the PLA subsystem, including the PLA and its associated demultiplexer. These
# test that the correct chip select signals are produced for a wide variety of combinations
# of addresses, VIC addresses, bank selectors (both from the CPU and the expansion port),
# and other various signals.
#
# In addition to the PLA and the demux, two other chips are involved to handle AEC. AEC as
# it comes from the VIC is an active-high signal. It is ANDed with the demux output for
# COLOR to produce the actual color RAM chip select signal. It is also inverted before being
# sent to the PLA. So a 7408 is included to do the ANDing, and a 7406 is here to do the
# inverting.
#
# For the moment this includes only tests of the 32 banking modes made possible by the 5
# banking control signals: LORAM, HIRAM, CHAREN, EXROM, and GAME. This notably does not
# test any level of GR_W, anything where R_W is set low (write), or anything where the VIC
# is in control. Those tests will be added later.

import unittest

import ../../src/nim64/chips/ic7406 as inv
import ../../src/nim64/chips/ic7408 as ndg
import ../../src/nim64/chips/ic74139 as dmx
import ../../src/nim64/chips/ic82s100 as pla
import ../../src/nim64/components/link
import ../../src/nim64/utils

const
  CAS    = 0
  LORAM  = 1
  HIRAM  = 2
  CHAREN = 3
  VA14   = 4
  A15    = 5
  A14    = 6
  A13    = 7
  A12    = 8
  BA     = 9
  AEC    = 10
  R_W    = 11
  EXROM  = 12
  GAME   = 13
  VA13   = 14
  VA12   = 15
  A11    = 16
  A10    = 17
  A9     = 18
  A8     = 19
  CASRAM = 0
  BASIC  = 1
  KERNAL = 2
  CHAROM = 3
  GR_W   = 4
  ROML   = 5
  ROMH   = 6
  VIC    = 7
  SID    = 8
  COLOR  = 9
  CIA1   = 10
  CIA2   = 11
  IO1    = 12
  IO2    = 13

const
  Bank0 = 0x0fffu
  Bank1 = 0x7fffu
  Bank2 = 0x9fffu
  Bank3 = 0xbfffu
  Bank4 = 0xcfffu
  Bank5 = 0xdfffu
  Bank6 = 0xffffu
  IoBank0 = 0xd3ffu
  IoBank1 = 0xd7ffu
  IoBank2 = 0xdbffu
  IoBank3 = 0xdcffu
  IoBank4 = 0xddffu
  IoBank5 = 0xdeffu
  IoBank6 = 0xdfffu

proc setup: (seq[Pin], seq[Pin], Ic82S100) =
  let u17 = new_ic82s100()
  let u15 = new_ic74139()
  # these two are just for special handling of AEC
  let u27 = new_ic7408()
  let u8 = new_ic7406()

  # inputs
  var inputs: seq[Pin] = @[]
  add(inputs, set(new_pin(0, "CAS", Output)))
  add(inputs, set(new_pin(0, "LORAM", Output)))
  add(inputs, set(new_pin(0, "HIRAM", Output)))
  add(inputs, set(new_pin(0, "CHAREN", Output)))
  add(inputs, set(new_pin(0, "VA14", Output)))
  add(inputs, clear(new_pin(0, "A15", Output)))
  add(inputs, clear(new_pin(0, "A14", Output)))
  add(inputs, clear(new_pin(0, "A13", Output)))
  add(inputs, clear(new_pin(0, "A12", Output)))
  add(inputs, clear(new_pin(0, "BA", Output)))
  add(inputs, set(new_pin(0, "AEC", Output)))
  add(inputs, set(new_pin(0, "R_W", Output)))
  add(inputs, set(new_pin(0, "EXROM", Output)))
  add(inputs, set(new_pin(0, "GAME", Output)))
  add(inputs, clear(new_pin(0, "VA13", Output)))
  add(inputs, clear(new_pin(0, "VA12", Output)))
  add(inputs, clear(new_pin(0, "A11", Output)))
  add(inputs, clear(new_pin(0, "A10", Output)))
  add(inputs, clear(new_pin(0, "A9", Output)))
  add(inputs, clear(new_pin(0, "A8", Output)))

  var outputs: seq[Pin] = @[]
  add(outputs, new_pin(0, "CASRAM", Input))
  add(outputs, new_pin(0, "BASIC", Input))
  add(outputs, new_pin(0, "KERNAL", Input))
  add(outputs, new_pin(0, "CHAROM", Input))
  add(outputs, new_pin(0, "GR_W", Input))
  add(outputs, new_pin(0, "ROML", Input))
  add(outputs, new_pin(0, "ROMH", Input))
  add(outputs, new_pin(0, "VIC", Input))
  add(outputs, new_pin(0, "SID", Input))
  add(outputs, new_pin(0, "COLOR", Input))
  add(outputs, new_pin(0, "CIA1", Input))
  add(outputs, new_pin(0, "CIA2", Input))
  add(outputs, new_pin(0, "IO1", Input))
  add(outputs, new_pin(0, "IO2", Input))

  # traces connected to external pins
  discard new_trace(inputs[CAS], u17[pla.I0])
  discard new_trace(inputs[LORAM], u17[pla.I1])
  discard new_trace(inputs[HIRAM], u17[pla.I2])
  discard new_trace(inputs[CHAREN], u17[pla.I3])
  discard new_trace(inputs[VA14], u17[pla.I4])
  discard new_trace(inputs[A15], u17[pla.I5])
  discard new_trace(inputs[A14], u17[pla.I6])
  discard new_trace(inputs[A13], u17[pla.I7])
  discard new_trace(inputs[A12], u17[pla.I8])
  discard new_trace(inputs[BA], u17[pla.I9])
  # AEC not connected directly to input; see below
  discard new_trace(inputs[R_W], u17[pla.I11])
  discard new_trace(inputs[EXROM], u17[pla.I12])
  discard new_trace(inputs[GAME], u17[pla.I13])
  discard new_trace(inputs[VA13], u17[pla.I14])
  discard new_trace(inputs[VA12], u17[pla.I15])
  discard new_trace(inputs[A11], u15[dmx.B1])
  discard new_trace(inputs[A10], u15[dmx.A1])
  discard new_trace(inputs[A9], u15[dmx.B2])
  discard new_trace(inputs[A8], u15[dmx.A2])

  discard new_trace(outputs[CASRAM], u17[pla.F0])
  discard new_trace(outputs[BASIC], u17[pla.F1])
  discard new_trace(outputs[KERNAL], u17[pla.F2])
  discard new_trace(outputs[CHAROM], u17[pla.F3])
  discard new_trace(outputs[GR_W], u17[pla.F4])
  discard new_trace(outputs[ROML], u17[pla.F6])
  discard new_trace(outputs[ROMH], u17[pla.F7])
  discard new_trace(outputs[VIC], u15[dmx.Y01])
  discard new_trace(outputs[SID], u15[dmx.Y11])
  # COLOR not connected directly to output; see the AEC business below
  discard new_trace(outputs[CIA1], u15[dmx.Y02])
  discard new_trace(outputs[CIA2], u15[dmx.Y12])
  discard new_trace(outputs[IO1], u15[dmx.Y22])
  discard new_trace(outputs[IO2], u15[dmx.Y32])

  # AEC specialness. AEC is ANDed with the COLOR output from U15 to produce the *actual*
  # COLOR output (this ensures that color RAM is *always* available when AEC is low, meaning
  # when the VIC has control of the busses, without having to add a bunch of logic cases to
  # the PLA to handle that). AEC is also inverted before being sent to the PLA (this is
  # probably a matter of convenience; AEC has to be inverted anyway to control the
  # multiplexers U13 and U25, and likely that inverted signal was easier to get to the PLA).
  discard new_trace(inputs[AEC], u27[ndg.B3], u8[inv.A2])
  discard new_trace(u8[inv.Y2], u17[pla.I10])
  discard new_trace(u15[dmx.Y21], u27[ndg.A3])
  discard new_trace(u27[ndg.Y3], outputs[COLOR])

  # connections between the two chips
  discard new_trace(u17[pla.F5], u15[dmx.G1])
  discard new_trace(u15[dmx.Y31], u15[dmx.G2])

  # PLA output enable is tied to ground
  discard clear new_trace(u17[pla.OE])

  clear(inputs[CAS])
  set(inputs[BA])
  set(inputs[AEC])
  set(inputs[R_W])

  (inputs, outputs, u17)

# This implements the 32 modes possible from manipulation of the bank-switching signals
# LORAM, HIRAM, CHAREN, GAME, and EXROM, taken from the table at
# https://www.c64-wiki.com/wiki/Bank_Switching#Mode_Table.
proc set_mode(pins: seq[Pin], mode: uint) =
  set_level(pins[LORAM], float(bit_value(mode, 0)))
  set_level(pins[HIRAM], float bit_value(mode, 1))
  set_level(pins[CHAREN], float(bit_value(mode, 2)))
  set_level(pins[GAME], float(bit_value(mode, 3)))
  set_level(pins[EXROM], float(bit_value(mode, 4)))

proc set_addr(pins: seq[Pin], address: uint) =
  set_level(pins[A15], float(bit_value(address, 15)))
  set_level(pins[A14], float(bit_value(address, 14)))
  set_level(pins[A13], float(bit_value(address, 13)))
  set_level(pins[A12], float(bit_value(address, 12)))
  set_level(pins[A11], float(bit_value(address, 11)))
  set_level(pins[A10], float(bit_value(address, 10)))
  set_level(pins[A9], float(bit_value(address, 9)))
  set_level(pins[A8], float(bit_value(address, 8)))

proc check_addr(inputs: seq[Pin], outputs: seq[Pin], address: uint, expected: int) =
  set_addr(inputs, address)

  for i in 0..13:
    if i == expected:
      check lowp(outputs[i])
    else:
      check highp(outputs[i])

proc check_io(inputs: seq[Pin], outputs: seq[Pin]) =
  check_addr(inputs, outputs, IoBank0, VIC)
  check_addr(inputs, outputs, IoBank1, SID)
  check_addr(inputs, outputs, IoBank2, COLOR)
  check_addr(inputs, outputs, IoBank3, CIA1)
  check_addr(inputs, outputs, IoBank4, CIA2)
  check_addr(inputs, outputs, IoBank5, IO1)
  check_addr(inputs, outputs, IoBank6, IO2)

proc check_none(inputs: seq[Pin], outputs: seq[Pin], address: uint) =
  set_addr(inputs, address)
  for i in 0..13:
    check highp(outputs[i])

# BANK SWITCHING
# These test the 32 different bank switching modes available in the C64. Some of these are
# duplicates of one another (there are only 14 actual different modes), but all are tested
# separately anyway.

proc mode_0 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 0)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, CASRAM)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_addr(inputs, outputs, Bank5, CASRAM)
  check_addr(inputs, outputs, Bank6, CASRAM)

proc mode_1 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 1)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, CASRAM)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_addr(inputs, outputs, Bank5, CASRAM)
  check_addr(inputs, outputs, Bank6, CASRAM)

proc mode_2 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 2)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, ROMH)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_addr(inputs, outputs, Bank5, CHAROM)
  check_addr(inputs, outputs, Bank6, KERNAL)

proc mode_3 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 3)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, ROML)
  check_addr(inputs, outputs, Bank3, ROMH)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_addr(inputs, outputs, Bank5, CHAROM)
  check_addr(inputs, outputs, Bank6, KERNAL)

proc mode_4 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 4)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, CASRAM)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_addr(inputs, outputs, Bank5, CASRAM)
  check_addr(inputs, outputs, Bank6, CASRAM)

proc mode_5 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 5)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, CASRAM)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_io(inputs, outputs)
  check_addr(inputs, outputs, Bank6, CASRAM)

proc mode_6 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 6)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, ROMH)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_io(inputs, outputs)
  check_addr(inputs, outputs, Bank6, KERNAL)

proc mode_7 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 7)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, ROML)
  check_addr(inputs, outputs, Bank3, ROMH)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_io(inputs, outputs)
  check_addr(inputs, outputs, Bank6, KERNAL)

proc mode_8 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 8)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, CASRAM)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_addr(inputs, outputs, Bank5, CASRAM)
  check_addr(inputs, outputs, Bank6, CASRAM)

proc mode_9 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 9)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, CASRAM)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_addr(inputs, outputs, Bank5, CHAROM)
  check_addr(inputs, outputs, Bank6, CASRAM)

proc mode_10 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 10)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, CASRAM)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_addr(inputs, outputs, Bank5, CHAROM)
  check_addr(inputs, outputs, Bank6, KERNAL)

proc mode_11 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 11)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, ROML)
  check_addr(inputs, outputs, Bank3, BASIC)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_addr(inputs, outputs, Bank5, CHAROM)
  check_addr(inputs, outputs, Bank6, KERNAL)

proc mode_12 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 12)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, CASRAM)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_addr(inputs, outputs, Bank5, CASRAM)
  check_addr(inputs, outputs, Bank6, CASRAM)

proc mode_13 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 13)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, CASRAM)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_io(inputs, outputs)
  check_addr(inputs, outputs, Bank6, CASRAM)

proc mode_14 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 14)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, CASRAM)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_io(inputs, outputs)
  check_addr(inputs, outputs, Bank6, KERNAL)

proc mode_15 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 15)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, ROML)
  check_addr(inputs, outputs, Bank3, BASIC)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_io(inputs, outputs)
  check_addr(inputs, outputs, Bank6, KERNAL)

proc mode_16 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 16)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_none(inputs, outputs, Bank1)
  check_addr(inputs, outputs, Bank2, ROML)
  check_none(inputs, outputs, Bank3)
  check_none(inputs, outputs, Bank4)
  check_io(inputs, outputs)
  check_addr(inputs, outputs, Bank6, ROMH)

proc mode_17 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 17)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_none(inputs, outputs, Bank1)
  check_addr(inputs, outputs, Bank2, ROML)
  check_none(inputs, outputs, Bank3)
  check_none(inputs, outputs, Bank4)
  check_io(inputs, outputs)
  check_addr(inputs, outputs, Bank6, ROMH)

proc mode_18 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 18)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_none(inputs, outputs, Bank1)
  check_addr(inputs, outputs, Bank2, ROML)
  check_none(inputs, outputs, Bank3)
  check_none(inputs, outputs, Bank4)
  check_io(inputs, outputs)
  check_addr(inputs, outputs, Bank6, ROMH)

proc mode_19 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 19)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_none(inputs, outputs, Bank1)
  check_addr(inputs, outputs, Bank2, ROML)
  check_none(inputs, outputs, Bank3)
  check_none(inputs, outputs, Bank4)
  check_io(inputs, outputs)
  check_addr(inputs, outputs, Bank6, ROMH)

proc mode_20 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 20)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_none(inputs, outputs, Bank1)
  check_addr(inputs, outputs, Bank2, ROML)
  check_none(inputs, outputs, Bank3)
  check_none(inputs, outputs, Bank4)
  check_io(inputs, outputs)
  check_addr(inputs, outputs, Bank6, ROMH)

proc mode_21 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 21)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_none(inputs, outputs, Bank1)
  check_addr(inputs, outputs, Bank2, ROML)
  check_none(inputs, outputs, Bank3)
  check_none(inputs, outputs, Bank4)
  check_io(inputs, outputs)
  check_addr(inputs, outputs, Bank6, ROMH)

proc mode_22 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 22)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_none(inputs, outputs, Bank1)
  check_addr(inputs, outputs, Bank2, ROML)
  check_none(inputs, outputs, Bank3)
  check_none(inputs, outputs, Bank4)
  check_io(inputs, outputs)
  check_addr(inputs, outputs, Bank6, ROMH)

proc mode_23 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 23)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_none(inputs, outputs, Bank1)
  check_addr(inputs, outputs, Bank2, ROML)
  check_none(inputs, outputs, Bank3)
  check_none(inputs, outputs, Bank4)
  check_io(inputs, outputs)
  check_addr(inputs, outputs, Bank6, ROMH)

proc mode_24 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 24)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, CASRAM)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_addr(inputs, outputs, Bank5, CASRAM)
  check_addr(inputs, outputs, Bank6, CASRAM)

proc mode_25 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 25)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, CASRAM)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_addr(inputs, outputs, Bank5, CHAROM)
  check_addr(inputs, outputs, Bank6, CASRAM)

proc mode_26 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 26)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, CASRAM)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_addr(inputs, outputs, Bank5, CHAROM)
  check_addr(inputs, outputs, Bank6, KERNAL)

proc mode_27 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 27)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, BASIC)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_addr(inputs, outputs, Bank5, CHAROM)
  check_addr(inputs, outputs, Bank6, KERNAL)

proc mode_28 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 28)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, CASRAM)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_addr(inputs, outputs, Bank5, CASRAM)
  check_addr(inputs, outputs, Bank6, CASRAM)

proc mode_29 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 29)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, CASRAM)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_io(inputs, outputs)
  check_addr(inputs, outputs, Bank6, CASRAM)

proc mode_30 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 30)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, CASRAM)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_io(inputs, outputs)
  check_addr(inputs, outputs, Bank6, KERNAL)

proc mode_31 =
  let (inputs, outputs, _) = setup()
  set_mode(inputs, 31)

  check_addr(inputs, outputs, Bank0, CASRAM)
  check_addr(inputs, outputs, Bank1, CASRAM)
  check_addr(inputs, outputs, Bank2, CASRAM)
  check_addr(inputs, outputs, Bank3, BASIC)
  check_addr(inputs, outputs, Bank4, CASRAM)
  check_io(inputs, outputs)
  check_addr(inputs, outputs, Bank6, KERNAL)

proc all_tests* =
  suite "PLA system":
    test "Mode 0": mode_0()
    test "Mode 1": mode_1()
    test "Mode 2": mode_2()
    test "Mode 3": mode_3()
    test "Mode 4": mode_4()
    test "Mode 5": mode_5()
    test "Mode 6": mode_6()
    test "Mode 7": mode_7()
    test "Mode 8": mode_8()
    test "Mode 9": mode_9()
    test "Mode 10": mode_10()
    test "Mode 11": mode_11()
    test "Mode 12": mode_12()
    test "Mode 13": mode_13()
    test "Mode 14": mode_14()
    test "Mode 15": mode_15()
    test "Mode 16": mode_16()
    test "Mode 17": mode_17()
    test "Mode 18": mode_18()
    test "Mode 19": mode_19()
    test "Mode 20": mode_20()
    test "Mode 21": mode_21()
    test "Mode 22": mode_22()
    test "Mode 23": mode_23()
    test "Mode 24": mode_24()
    test "Mode 25": mode_25()
    test "Mode 26": mode_26()
    test "Mode 27": mode_27()
    test "Mode 28": mode_28()
    test "Mode 29": mode_29()
    test "Mode 30": mode_30()
    test "Mode 31": mode_31()

if is_main_module:
  all_tests()
