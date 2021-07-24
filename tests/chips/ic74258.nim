# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ../utils
import ../../src/nim64/chips/ic74258
import ../../src/nim64/components/link

proc setup: (Ic74258, Traces) =
  let chip = newIc74258()
  let traces = deviceTraces(chip)
  result = (chip, traces)

proc inv1Setup: (Ic74258, Traces) =
  result = setup()
  let (_, traces) = result
  clear traces[A1]
  set traces[B1]

proc inv1SelectA* =
  let (_, traces) = inv1Setup()

  clear traces[SEL]
  check highp traces[Y1]

  set traces[A1]
  check lowp traces[Y1]

proc inv1SelectB* =
  let (_, traces) = inv1Setup()

  set traces[SEL]
  check lowp traces[Y1]

  clear traces[B1]
  check highp traces[Y1]

proc inv1HighOe* =
  let (_, traces) = inv1Setup()

  set traces[SEL]
  check lowp traces[Y1]

  set traces[OE]
  check trip traces[Y1]

  clear traces[SEL]
  check trip traces[Y1]

proc inv2Setup: (Ic74258, Traces) =
  result = setup()
  let (_, traces) = result
  clear traces[A2]
  set traces[B2]

proc inv2SelectA* =
  let (_, traces) = inv2Setup()

  clear traces[SEL]
  check highp traces[Y2]
  set traces[A2]
  check lowp traces[Y2]

proc inv2SelectB* =
  let (_, traces) = inv2Setup()

  set traces[SEL]
  check lowp traces[Y2]

  clear traces[B2]
  check highp traces[Y2]

proc inv2HighOe* =
  let (_, traces) = inv2Setup()

  set traces[SEL]
  check lowp traces[Y2]

  set traces[OE]
  check trip traces[Y2]

  clear traces[SEL]
  check trip traces[Y2]

proc inv3Setup: (Ic74258, Traces) =
  result = setup()
  let (_, traces) = result
  clear traces[A3]
  set traces[B3]

proc inv3SelectA* =
  let (_, traces) = inv3Setup()

  clear traces[SEL]
  check highp traces[Y3]

  set traces[A3]
  check lowp traces[Y3]

proc inv3SelectB* =
  let (_, traces) = inv3Setup()

  set traces[SEL]
  check lowp traces[Y3]

  clear traces[B3]
  check highp traces[Y3]

proc inv3HighOe* =
  let (_, traces) = inv3Setup()

  set traces[SEL]
  check lowp traces[Y3]

  set traces[OE]
  check trip traces[Y3]

  clear traces[SEL]
  check trip traces[Y3]

proc inv4Setup: (Ic74258, Traces) =
  result = setup()
  let (_, traces) = result
  clear traces[A4]
  set traces[B4]

proc inv4SelectA* =
  let (_, traces) = inv4Setup()

  clear traces[SEL]
  check highp traces[Y4]

  set traces[A4]
  check lowp traces[Y4]

proc inv4SelectB* =
  let (_, traces) = inv4Setup()

  set traces[SEL]
  check lowp traces[Y4]

  clear traces[B4]
  check highp traces[Y4]

proc inv4HighOe* =
  let (_, traces) = inv4Setup()

  set traces[SEL]
  check lowp traces[Y4]

  set traces[OE]
  check trip traces[Y4]

  clear traces[SEL]
  check trip traces[Y4]
