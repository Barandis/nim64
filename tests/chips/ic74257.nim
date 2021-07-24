# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ../utils
import ../../src/nim64/chips/ic74257
import ../../src/nim64/components/link

proc setup: (Ic74257, Traces) =
  let chip = newIc74257()
  let traces = deviceTraces(chip)
  result = (chip, traces)

proc mux1Setup: (Ic74257, Traces) =
  result = setup()
  let (_, traces) = result
  clear traces[A1]
  set traces[B1]

proc initial74257* =
  let (_, traces) = setup()

  check:
    lowp traces[Y1]
    lowp traces[Y2]
    lowp traces[Y3]
    lowp traces[Y4]

proc mux1SelectA* =
  let (_, traces) = mux1Setup()

  clear traces[SEL]
  check lowp traces[Y1]

  set traces[A1]
  check highp traces[Y1]

proc mux1SelectB* =
  let (_, traces) = mux1Setup()

  set traces[SEL]
  check highp traces[Y1]

  clear traces[B1]
  check lowp traces[Y1]

proc mux1HighOe* =
  let (_, traces) = mux1Setup()

  set traces[SEL]
  check highp traces[Y1]

  set traces[OE]
  check floatp traces[Y1]

  clear traces[SEL]
  check floatp traces[Y1]

proc mux2Setup: (Ic74257, Traces) =
  result = setup()
  let (_, traces) = result
  clear traces[A2]
  set traces[B2]

proc mux2SelectA* =
  let (_, traces) = mux2Setup()

  clear traces[SEL]
  check lowp traces[Y2]
  set traces[A2]
  check highp traces[Y2]

proc mux2SelectB* =
  let (_, traces) = mux2Setup()

  set traces[SEL]
  check highp traces[Y2]

  clear traces[B2]
  check lowp traces[Y2]

proc mux2HighOe* =
  let (_, traces) = mux2Setup()

  set traces[SEL]
  check highp traces[Y2]

  set traces[OE]
  check floatp traces[Y2]

  clear traces[SEL]
  check floatp traces[Y2]

proc mux3Setup: (Ic74257, Traces) =
  result = setup()
  let (_, traces) = result
  clear traces[A3]
  set traces[B3]

proc mux3SelectA* =
  let (_, traces) = mux3Setup()

  clear traces[SEL]
  check lowp traces[Y3]

  set traces[A3]
  check highp traces[Y3]

proc mux3SelectB* =
  let (_, traces) = mux3Setup()

  set traces[SEL]
  check highp traces[Y3]

  clear traces[B3]
  check lowp traces[Y3]

proc mux3HighOe* =
  let (_, traces) = mux3Setup()

  set traces[SEL]
  check highp traces[Y3]

  set traces[OE]
  check floatp traces[Y3]

  clear traces[SEL]
  check floatp traces[Y3]

proc mux4Setup: (Ic74257, Traces) =
  result = setup()
  let (_, traces) = result
  clear traces[A4]
  set traces[B4]

proc mux4SelectA* =
  let (_, traces) = mux4Setup()

  clear traces[SEL]
  check lowp traces[Y4]

  set traces[A4]
  check highp traces[Y4]

proc mux4SelectB* =
  let (_, traces) = mux4Setup()

  set traces[SEL]
  check highp traces[Y4]

  clear traces[B4]
  check lowp traces[Y4]

proc mux4HighOe* =
  let (_, traces) = mux4Setup()

  set traces[SEL]
  check highp traces[Y4]

  set traces[OE]
  check floatp traces[Y4]

  clear traces[SEL]
  check floatp traces[Y4]
