# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import strformat
import ../utils
import ../../src/nim64/chips/ic7408
import ../../src/nim64/components/link

proc setup: (Ic7408, Traces) =
  let chip = newIc7408()
  result = (chip, deviceTraces(chip))

proc gate1* =
  let (_, traces) = setup()

  clear traces[A1]
  clear traces[B1]
  check lowp traces[Y1]

  clear traces[A1]
  set traces[B1]
  check lowp traces[Y1]

  set traces[A1]
  clear traces[B1]
  check lowp traces[Y1]

  set traces[A1]
  set traces[B1]
  check highp traces[Y1]

proc gate2* =
  let (_, traces) = setup()

  clear traces[A2]
  clear traces[B2]
  check lowp traces[Y2]

  clear traces[A2]
  set traces[B2]
  check lowp traces[Y2]

  set traces[A2]
  clear traces[B2]
  check lowp traces[Y2]

  set traces[A2]
  set traces[B2]
  check highp traces[Y2]

proc gate3* =
  let (_, traces) = setup()

  clear traces[A3]
  clear traces[B3]
  check lowp traces[Y3]

  clear traces[A3]
  set traces[B3]
  check lowp traces[Y3]

  set traces[A3]
  clear traces[B3]
  check lowp traces[Y3]

  set traces[A3]
  set traces[B3]
  check highp traces[Y3]

proc gate4* =
  let (_, traces) = setup()

  clear traces[A4]
  clear traces[B4]
  check lowp traces[Y4]

  clear traces[A4]
  set traces[B4]
  check lowp traces[Y4]

  set traces[A4]
  clear traces[B4]
  check lowp traces[Y4]

  set traces[A4]
  set traces[B4]
  check highp traces[Y4]
