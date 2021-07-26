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

proc mux1Setup: (Ic74258, Traces) =
  result = setup()
  let (_, traces) = result
  clear traces[A1]
  set traces[B1]

proc mux1SelectA =
  let (_, traces) = mux1Setup()

  clear traces[SEL]
  check highp traces[Y1]

  set traces[A1]
  check lowp traces[Y1]

proc mux1SelectB =
  let (_, traces) = mux1Setup()

  set traces[SEL]
  check lowp traces[Y1]

  clear traces[B1]
  check highp traces[Y1]

proc mux1HighOe =
  let (_, traces) = mux1Setup()

  set traces[SEL]
  check lowp traces[Y1]

  set traces[OE]
  check trip traces[Y1]

  clear traces[SEL]
  check trip traces[Y1]

proc mux2Setup: (Ic74258, Traces) =
  result = setup()
  let (_, traces) = result
  clear traces[A2]
  set traces[B2]

proc mux2SelectA =
  let (_, traces) = mux2Setup()

  clear traces[SEL]
  check highp traces[Y2]
  set traces[A2]
  check lowp traces[Y2]

proc mux2SelectB =
  let (_, traces) = mux2Setup()

  set traces[SEL]
  check lowp traces[Y2]

  clear traces[B2]
  check highp traces[Y2]

proc mux2HighOe =
  let (_, traces) = mux2Setup()

  set traces[SEL]
  check lowp traces[Y2]

  set traces[OE]
  check trip traces[Y2]

  clear traces[SEL]
  check trip traces[Y2]

proc mux3Setup: (Ic74258, Traces) =
  result = setup()
  let (_, traces) = result
  clear traces[A3]
  set traces[B3]

proc mux3SelectA =
  let (_, traces) = mux3Setup()

  clear traces[SEL]
  check highp traces[Y3]

  set traces[A3]
  check lowp traces[Y3]

proc mux3SelectB =
  let (_, traces) = mux3Setup()

  set traces[SEL]
  check lowp traces[Y3]

  clear traces[B3]
  check highp traces[Y3]

proc mux3HighOe =
  let (_, traces) = mux3Setup()

  set traces[SEL]
  check lowp traces[Y3]

  set traces[OE]
  check trip traces[Y3]

  clear traces[SEL]
  check trip traces[Y3]

proc mux4Setup: (Ic74258, Traces) =
  result = setup()
  let (_, traces) = result
  clear traces[A4]
  set traces[B4]

proc mux4SelectA =
  let (_, traces) = mux4Setup()

  clear traces[SEL]
  check highp traces[Y4]

  set traces[A4]
  check lowp traces[Y4]

proc mux4SelectB =
  let (_, traces) = mux4Setup()

  set traces[SEL]
  check lowp traces[Y4]

  clear traces[B4]
  check highp traces[Y4]

proc mux4HighOe =
  let (_, traces) = mux4Setup()

  set traces[SEL]
  check lowp traces[Y4]

  set traces[OE]
  check trip traces[Y4]

  clear traces[SEL]
  check trip traces[Y4]

proc allTests* =
  suite "74258 quad 2-to-1 multiplexer":
    test "low SEL selects A1": mux1SelectA()
    test "high SEL selects B1": mux1SelectB()
    test "high OE tri-states A1 and B1": mux1HighOe()
    test "low SEL selects A2": mux2SelectA()
    test "high SEL selects B2": mux2SelectB()
    test "high OE tri-states A1 and B1": mux2HighOe()
    test "low SEL selects A3": mux3SelectA()
    test "high SEL selects B3": mux3SelectB()
    test "high OE tri-states A1 and B1": mux3HighOe()
    test "low SEL selects A4": mux4SelectA()
    test "high SEL selects B4": mux4SelectB()
    test "high OE tri-states A1 and B1": mux4HighOe()

when isMainModule:
  allTests()
