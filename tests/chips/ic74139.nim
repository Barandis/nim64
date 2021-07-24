# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ../utils
import ../../src/nim64/chips/ic74139
import ../../src/nim64/components/link

proc setup: (Ic74139, Traces) =
  let chip = newIc74139()
  result = (chip, deviceTraces(chip))

proc demux1Initial* =
  let (_, traces) = setup()

  check:
    lowp traces[Y01]
    highp traces[Y11]
    highp traces[Y21]
    highp traces[Y31]

proc demux1HighG* =
  let (_, traces) = setup()

  set traces[G1]
  clear traces[A1]
  clear traces[B1]
  check:
    highp traces[Y01]
    highp traces[Y11]
    highp traces[Y21]
    highp traces[Y31]
  
  set traces[A1]
  check:
    highp traces[Y01]
    highp traces[Y11]
    highp traces[Y21]
    highp traces[Y31]
  
  set traces[B1]
  check:
    highp traces[Y01]
    highp traces[Y11]
    highp traces[Y21]
    highp traces[Y31]
  
  clear traces[A1]
  check:
    highp traces[Y01]
    highp traces[Y11]
    highp traces[Y21]
    highp traces[Y31]

proc demux1LL* =
  let (_, traces) = setup()

  clear traces[G1]
  clear traces[A1]
  clear traces[B1]
  check:
    lowp traces[Y01]
    highp traces[Y11]
    highp traces[Y21]
    highp traces[Y31]

proc demux1HL* =
  let (_, traces) = setup()

  clear traces[G1]
  set traces[A1]
  clear traces[B1]
  check:
    highp traces[Y01]
    lowp traces[Y11]
    highp traces[Y21]
    highp traces[Y31]

proc demux1LH* =
  let (_, traces) = setup()

  clear traces[G1]
  clear traces[A1]
  set traces[B1]
  check:
    highp traces[Y01]
    highp traces[Y11]
    lowp traces[Y21]
    highp traces[Y31]

proc demux1HH* =
  let (_, traces) = setup()

  clear traces[G1]
  set traces[A1]
  set traces[B1]
  check:
    highp traces[Y01]
    highp traces[Y11]
    highp traces[Y21]
    lowp traces[Y31]

proc demux2Initial* =
  let (_, traces) = setup()

  check:
    lowp traces[Y02]
    highp traces[Y12]
    highp traces[Y22]
    highp traces[Y32]

proc demux2HighG* =
  let (_, traces) = setup()

  set traces[G2]
  clear traces[A2]
  clear traces[B2]
  check:
    highp traces[Y02]
    highp traces[Y12]
    highp traces[Y22]
    highp traces[Y32]
  
  set traces[A1]
  check:
    highp traces[Y02]
    highp traces[Y12]
    highp traces[Y22]
    highp traces[Y32]
  
  set traces[B2]
  check:
    highp traces[Y02]
    highp traces[Y12]
    highp traces[Y22]
    highp traces[Y32]
  
  clear traces[A2]
  check:
    highp traces[Y02]
    highp traces[Y12]
    highp traces[Y22]
    highp traces[Y32]

proc demux2LL* =
  let (_, traces) = setup()

  clear traces[G2]
  clear traces[A2]
  clear traces[B2]
  check:
    lowp traces[Y02]
    highp traces[Y12]
    highp traces[Y22]
    highp traces[Y32]

proc demux2HL* =
  let (_, traces) = setup()

  clear traces[G2]
  set traces[A2]
  clear traces[B2]
  check:
    highp traces[Y02]
    lowp traces[Y12]
    highp traces[Y22]
    highp traces[Y32]

proc demux2LH* =
  let (_, traces) = setup()

  clear traces[G2]
  clear traces[A2]
  set traces[B2]
  check:
    highp traces[Y02]
    highp traces[Y12]
    lowp traces[Y22]
    highp traces[Y32]

proc demux2HH* =
  let (_, traces) = setup()

  clear traces[G2]
  set traces[A2]
  set traces[B2]
  check:
    highp traces[Y02]
    highp traces[Y12]
    highp traces[Y22]
    lowp traces[Y32]
