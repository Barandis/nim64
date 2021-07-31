# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ../utils
import ../../src/nim64/chips/ic74139
import ../../src/nim64/components/link

proc setup: (Ic74139, Traces) =
  let chip = new_ic74139()
  result = (chip, device_traces(chip))

proc demux_1_high_g =
  let (_, traces) = setup()

  set(traces[G1])
  clear(traces[A1])
  clear(traces[B1])
  check:
    highp(traces[Y01])
    highp(traces[Y11])
    highp(traces[Y21])
    highp(traces[Y31])
  
  set(traces[A1])
  check:
    highp(traces[Y01])
    highp(traces[Y11])
    highp(traces[Y21])
    highp(traces[Y31])
  
  set(traces[B1])
  check:
    highp(traces[Y01])
    highp(traces[Y11])
    highp(traces[Y21])
    highp(traces[Y31])
  
  clear(traces[A1])
  check:
    highp(traces[Y01])
    highp(traces[Y11])
    highp(traces[Y21])
    highp(traces[Y31])

proc demux_1_ll =
  let (_, traces) = setup()

  clear(traces[G1])
  clear(traces[A1])
  clear(traces[B1])
  check:
    lowp(traces[Y01])
    highp(traces[Y11])
    highp(traces[Y21])
    highp(traces[Y31])

proc demux_1_hl =
  let (_, traces) = setup()

  clear(traces[G1])
  set(traces[A1])
  clear(traces[B1])
  check:
    highp(traces[Y01])
    lowp(traces[Y11])
    highp(traces[Y21])
    highp(traces[Y31])

proc demux_1_lh =
  let (_, traces) = setup()

  clear(traces[G1])
  clear(traces[A1])
  set(traces[B1])
  check:
    highp(traces[Y01])
    highp(traces[Y11])
    lowp(traces[Y21])
    highp(traces[Y31])

proc demux_1_hh =
  let (_, traces) = setup()

  clear(traces[G1])
  set(traces[A1])
  set(traces[B1])
  check:
    highp(traces[Y01])
    highp(traces[Y11])
    highp(traces[Y21])
    lowp(traces[Y31])

proc demux_2_high_g =
  let (_, traces) = setup()

  set(traces[G2])
  clear(traces[A2])
  clear(traces[B2])
  check:
    highp(traces[Y02])
    highp(traces[Y12])
    highp(traces[Y22])
    highp(traces[Y32])
  
  set(traces[A1])
  check:
    highp(traces[Y02])
    highp(traces[Y12])
    highp(traces[Y22])
    highp(traces[Y32])
  
  set(traces[B2])
  check:
    highp(traces[Y02])
    highp(traces[Y12])
    highp(traces[Y22])
    highp(traces[Y32])
  
  clear(traces[A2])
  check:
    highp(traces[Y02])
    highp(traces[Y12])
    highp(traces[Y22])
    highp(traces[Y32])

proc demux_2_ll =
  let (_, traces) = setup()

  clear(traces[G2])
  clear(traces[A2])
  clear(traces[B2])
  check:
    lowp(traces[Y02])
    highp(traces[Y12])
    highp(traces[Y22])
    highp(traces[Y32])

proc demux_2_hl =
  let (_, traces) = setup()

  clear(traces[G2])
  set(traces[A2])
  clear(traces[B2])
  check:
    highp(traces[Y02])
    lowp(traces[Y12])
    highp(traces[Y22])
    highp(traces[Y32])

proc demux_2_lh =
  let (_, traces) = setup()

  clear(traces[G2])
  clear(traces[A2])
  set(traces[B2])
  check:
    highp(traces[Y02])
    highp(traces[Y12])
    lowp(traces[Y22])
    highp(traces[Y32])

proc demux_2_hh =
  let (_, traces) = setup()

  clear(traces[G2])
  set(traces[A2])
  set(traces[B2])
  check:
    highp(traces[Y02])
    highp(traces[Y12])
    highp(traces[Y22])
    lowp(traces[Y32])

proc all_tests* =
  suite "74139 dual 2-to-4 demultiplexer":
    test "sets all demux 1 outputs high when G1 is high": demux_1_high_g()
    test "sets Y01 low when A1 is low and B1 is low": demux_1_ll()
    test "sets Y11 low when A1 is high and B1 is low": demux_1_hl()
    test "sets Y21 low when A1 is low and B1 is high": demux_1_lh()
    test "sets Y31 low when A1 is high and B1 is high": demux_1_hh()
    test "sets all demux 2 outputs high when G2 is high": demux_2_high_g()
    test "sets Y02 low when A2 is low and B2 is low": demux_2_ll()
    test "sets Y12 low when A2 is high and B2 is low": demux_2_hl()
    test "sets Y22 low when A2 is low and B2 is high": demux_2_lh()
    test "sets Y32 low when A2 is high and B2 is high": demux_2_hh()

when is_main_module:
  all_tests()
