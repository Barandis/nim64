# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# This subsystem is built primarily to test the multiplexer interaction with the DRAM chips.
# Because this interaction involves RAS and CAS from the VIC, and because CAS goes through
# the PLA to affect CASRAM, we have also instantiated a PLA and included it, but we use it
# in a way that means that CASRAM is always enabled after CAS goes low. Since AEC as a
# signal is inverted for use by the multiplexers and the PLA, we also include a 7406, though
# we only use one gate of it here.
#
# The involved chips are:
#   U9-U12, U21-U24: 4164 DRAM
#   U13, U25: 74257 multiplexer
#   U17: 82S100
#   U8: 7406
#
# External signals are provided for the entire address and memory bus, as well as RAS, CAS,
# AEC, LORAM, HIRAM, and R_W. These are provided by *pins* and not by *traces* because the
# 4164s' D and Q pins being tied together means that we couldn't ever directly set a trace
# value to anything during writes (because Q is the only output pin on the trace and is
# tri-stated during writes, meaning that the level of the trace will always be NaN). Adding
# a second output pin to these traces means we can override Q's mastery of the data traces.
#
# This is accurate conceptually; these traces will always be driven by output pins in the
# real thing. It will not matter in cases that don't involve this D/Q connection, but it
# will become the norm for subsystem tests.

import unittest
import sequtils
import strformat
import tables
import random

import ../../src/nim64/chips/ic4164 as ram
import ../../src/nim64/chips/ic7406 as inv
import ../../src/nim64/chips/ic74257 as mux
import ../../src/nim64/chips/ic82s100 as pla
import ../../src/nim64/components/link
import ../../src/nim64/utils

proc setup: (TableRef[string, Pin], seq[Pin], seq[Pin]) =
  randomize()

  # RAM chips, from D0 to D7
  let u21 = new_ic4164()
  let u9  = new_ic4164()
  let u22 = new_ic4164()
  let u10 = new_ic4164()
  let u23 = new_ic4164()
  let u11 = new_ic4164()
  let u24 = new_ic4164()
  let u12 = new_ic4164()

  # Multiplexers
  let u13 = new_ic74257()
  let u25 = new_ic74257()

  # PLA
  let u17 = new_ic82s100()

  # Inverter (one gate used to invert AEC)
  let u8  = new_ic7406()

  let pins = new_table[string, Pin]()

  # Address bus
  pins["A0"]  = clear(new_pin(0, "A0", Output))
  pins["A1"]  = clear(new_pin(0, "A1", Output))
  pins["A2"]  = clear(new_pin(0, "A2", Output))
  pins["A3"]  = clear(new_pin(0, "A3", Output))
  pins["A4"]  = clear(new_pin(0, "A4", Output))
  pins["A5"]  = clear(new_pin(0, "A5", Output))
  pins["A6"]  = clear(new_pin(0, "A6", Output))
  pins["A7"]  = clear(new_pin(0, "A7", Output))
  pins["A8"]  = clear(new_pin(0, "A8", Output))
  pins["A9"]  = clear(new_pin(0, "A9", Output))
  pins["A10"] = clear(new_pin(0, "A10", Output))
  pins["A11"] = clear(new_pin(0, "A11", Output))
  pins["A12"] = clear(new_pin(0, "A12", Output))
  pins["A13"] = clear(new_pin(0, "A13", Output))
  pins["A14"] = clear(new_pin(0, "A14", Output))
  pins["A15"] = clear(new_pin(0, "A15", Output))

  # Data bus
  pins["D0"] = clear(new_pin(0, "D0", Output))
  pins["D1"] = clear(new_pin(0, "D1", Output))
  pins["D2"] = clear(new_pin(0, "D2", Output))
  pins["D3"] = clear(new_pin(0, "D3", Output))
  pins["D4"] = clear(new_pin(0, "D4", Output))
  pins["D5"] = clear(new_pin(0, "D5", Output))
  pins["D6"] = clear(new_pin(0, "D6", Output))
  pins["D7"] = clear(new_pin(0, "D7", Output))

  # Control signals
  pins["R_W"] = set(new_pin(0, "R_W", Output))
  pins["RAS"] = set(new_pin(0, "RAS", Output))
  pins["CAS"] = set(new_pin(0, "CAS", Output))
  pins["AEC"] = set(new_pin(0, "AEC", Output))
  pins["LORAM"] = set(new_pin(0, "LORAM", Output))
  pins["HIRAM"] = set(new_pin(0, "HIRAM", Output))

  # Traces
  # --------------------------------------

  # Address bus
  discard new_trace(pins["A0"], u25[mux.B4])
  discard new_trace(pins["A1"], u25[mux.B3])
  discard new_trace(pins["A2"], u25[mux.B2])
  discard new_trace(pins["A3"], u25[mux.B1])
  discard new_trace(pins["A4"], u13[mux.B4])
  discard new_trace(pins["A5"], u13[mux.B2])
  discard new_trace(pins["A6"], u13[mux.B1])
  discard new_trace(pins["A7"], u13[mux.B3])
  discard new_trace(pins["A8"], u25[mux.A4])
  discard new_trace(pins["A9"], u25[mux.A3])
  discard new_trace(pins["A10"], u25[mux.A2])
  discard new_trace(pins["A11"], u25[mux.A1])
  discard new_trace(pins["A12"], u13[mux.A4], u17[pla.I8])
  discard new_trace(pins["A13"], u13[mux.A2], u17[pla.I7])
  discard new_trace(pins["A14"], u13[mux.A1], u17[pla.I6])
  discard new_trace(pins["A15"], u13[mux.A3], u17[pla.I5])

  # Data bus
  discard new_trace(pins["D0"], u21[ram.D], u21[ram.Q])
  discard new_trace(pins["D1"],  u9[ram.D],  u9[ram.Q])
  discard new_trace(pins["D2"], u22[ram.D], u22[ram.Q])
  discard new_trace(pins["D3"], u10[ram.D], u10[ram.Q])
  discard new_trace(pins["D4"], u23[ram.D], u23[ram.Q])
  discard new_trace(pins["D5"], u11[ram.D], u11[ram.Q])
  discard new_trace(pins["D6"], u24[ram.D], u24[ram.Q])
  discard new_trace(pins["D7"], u12[ram.D], u12[ram.Q])

  # Control signals
  let we = ram.WE
  discard new_trace(
    pins["R_W"], u21[we], u9[we], u22[we], u10[we], u23[we], u11[we], u24[we], u12[we], u17[pla.I11],
  )
  let ras = ram.RAS
  discard new_trace(
    pins["RAS"], u21[ras], u9[ras], u22[ras], u10[ras], u23[ras], u11[ras], u24[ras], u12[ras],
  )
  discard new_trace(pins["CAS"], u13[mux.SEL], u25[mux.SEL], u17[pla.I0])
  discard new_trace(pins["AEC"], u8[inv.A2])
  discard new_trace(pins["LORAM"], u17[pla.I1])
  discard new_trace(pins["HIRAM"], u17[pla.I2])

  # Multiplexer connections to RAM
  let a0 = ram.A0
  let a1 = ram.A1
  let a2 = ram.A2
  let a3 = ram.A3
  let a4 = ram.A4
  let a5 = ram.A5
  let a6 = ram.A6
  let a7 = ram.A7
  discard new_trace(
    u25[mux.Y4], u9[a0], u10[a0], u11[a0], u12[a0], u21[a0], u22[a0], u23[a0], u24[a0],
  )
  discard new_trace(
    u25[mux.Y3], u9[a1], u10[a1], u11[a1], u12[a1], u21[a1], u22[a1], u23[a1], u24[a1],
  )
  discard new_trace(
    u25[mux.Y2], u9[a2], u10[a2], u11[a2], u12[a2], u21[a2], u22[a2], u23[a2], u24[a2],
  )
  discard new_trace(
    u25[mux.Y1], u9[a3], u10[a3], u11[a3], u12[a3], u21[a3], u22[a3], u23[a3], u24[a3],
  )
  discard new_trace(
    u13[mux.Y4], u9[a4], u10[a4], u11[a4], u12[a4], u21[a4], u22[a4], u23[a4], u24[a4],
  )
  discard new_trace(
    u13[mux.Y2], u9[a5], u10[a5], u11[a5], u12[a5], u21[a5], u22[a5], u23[a5], u24[a5],
  )
  discard new_trace(
    u13[mux.Y1], u9[a6], u10[a6], u11[a6], u12[a6], u21[a6], u22[a6], u23[a6], u24[a6],
  )
  discard new_trace(
    u13[mux.Y3], u9[a7], u10[a7], u11[a7], u12[a7], u21[a7], u22[a7], u23[a7], u24[a7],
  )

  # inverse AEC connections
  discard new_trace(u8[inv.Y2], u13[mux.OE], u25[mux.OE], u17[pla.I10])
  # CASRAM connections
  discard new_trace(
    u17[pla.F0],
    u9[ram.CAS],
    u10[ram.CAS],
    u11[ram.CAS],
    u12[ram.CAS],
    u21[ram.CAS],
    u22[ram.CAS],
    u23[ram.CAS],
    u24[ram.CAS],
  )
  # pre-set PLA inputs
  discard set(new_trace(u17[pla.I3]))
  discard set(new_trace(u17[pla.I4]))
  discard set(new_trace(u17[pla.I9]))
  discard set(new_trace(u17[pla.I12]))
  discard set(new_trace(u17[pla.I13]))
  discard set(new_trace(u17[pla.I14]))
  discard set(new_trace(u17[pla.I15]))

  discard clear(new_trace(u17[pla.OE]))

  let addr_pins = map(to_seq(0..15), proc (i: int): Pin = pins[&"A{i}"])
  let data_pins = map(to_seq(0..7), proc (i: int): Pin = pins[&"D{i}"])

  (pins, addr_pins, data_pins)

proc read_write_full_ram =
  let (pins, addr_pins, data_pins) = setup()

  # makes entire 64k address RAM
  clear(pins["LORAM"])
  clear(pins["HIRAM"])
  set(pins["AEC"])

  for i in 1..256:
    let address = uint(rand(0xffff))
    value_to_pins(address, addr_pins)

    let data = uint(rand(0xff))
    value_to_pins(data, data_pins)

    # write the random value to the random RAM address
    clear(pins["R_W"])
    clear(pins["RAS"])
    clear(pins["CAS"])
    
    set(pins["CAS"])
    set(pins["RAS"])
    set(pins["R_W"])

    # read the value from the same random RAM address, confirm it matches
    mode_to_pins(Input, data_pins)
    clear(pins["RAS"])
    clear(pins["CAS"])
    let value = pins_to_value(data_pins)
    set(pins["CAS"])
    set(pins["RAS"])
    mode_to_pins(Output, data_pins)

    check value == data

proc all_tests* =
  suite "DRAM system":
    test "read/write random locations when entire memory is RAM": read_write_full_ram()

when is_main_module:
  all_tests()
