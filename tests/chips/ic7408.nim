# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import strformat
import ../utils
import ../../src/nim64/chips/ic7408
import ../../src/nim64/components/link

proc setup(): (Ic7408, Traces) =
  let chip = newIc7408()
  result = (chip, deviceTraces(chip))

proc initial7408*() =
  let(_, traces) = setup()

  for i in 1..4:
    check traces[&"Y{i}"].low

proc gate1*() =
  let (_, traces) = setup()

  traces[A1].clear()
  traces[B1].clear()
  check traces[Y1].low

  traces[A1].clear()
  traces[B1].set()
  check traces[Y1].low

  traces[A1].set()
  traces[B1].clear()
  check traces[Y1].low

  traces[A1].set()
  traces[B1].set()
  check traces[Y1].high

proc gate2*() =
  let (_, traces) = setup()

  traces[A2].clear()
  traces[B2].clear()
  check traces[Y2].low

  traces[A2].clear()
  traces[B2].set()
  check traces[Y2].low

  traces[A2].set()
  traces[B2].clear()
  check traces[Y2].low

  traces[A2].set()
  traces[B2].set()
  check traces[Y2].high

proc gate3*() =
  let (_, traces) = setup()

  traces[A3].clear()
  traces[B3].clear()
  check traces[Y3].low

  traces[A3].clear()
  traces[B3].set()
  check traces[Y3].low

  traces[A3].set()
  traces[B3].clear()
  check traces[Y3].low

  traces[A3].set()
  traces[B3].set()
  check traces[Y3].high

proc gate4*() =
  let (_, traces) = setup()

  traces[A4].clear()
  traces[B4].clear()
  check traces[Y4].low

  traces[A4].clear()
  traces[B4].set()
  check traces[Y4].low

  traces[A4].set()
  traces[B4].clear()
  check traces[Y4].low

  traces[A4].set()
  traces[B4].set()
  check traces[Y4].high
