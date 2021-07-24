# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ../utils
import ../../src/nim64/chips/ic4066
import ../../src/nim64/components/link

proc setup: (Ic4066, Traces) =
  let chip = newIc4066()
  let traces = deviceTraces(chip)
  result = (chip, traces)

proc passAtoB* =
  let (_, traces) = setup()

  clear traces[X1]
  setLevel traces[A1], 0.5
  check (level traces[B1]) == 0.5

  clear traces[X2]
  setLevel traces[A2], 0.75
  check (level traces[B2]) == 0.75

  clear traces[X3]
  setLevel traces[A3], 0.25
  check (level traces[B3]) == 0.25

  clear traces[X4]
  setLevel traces[A4], 1
  check (level traces[B4]) == 1

proc passBtoA* =
  let (_, traces) = setup()

  clear traces[X1]
  setLevel traces[B1], 0.5
  check (level traces[A1]) == 0.5

  clear traces[X2]
  setLevel traces[B2], 0.75
  check (level traces[A2]) == 0.75

  clear traces[X3]
  setLevel traces[B3], 0.25
  check (level traces[A3]) == 0.25

  clear traces[X4]
  setLevel traces[B4], 1
  check (level traces[A4]) == 1

proc disconOnHighX* =
  let (_, traces) = setup()

  set traces[X1]
  check:
    trip traces[A1]
    trip traces[B1]
  
  set traces[X2]
  check:
    trip traces[A2]
    trip traces[B2]
  
  set traces[X3]
  check:
    trip traces[A3]
    trip traces[B3]
  
  set traces[X4]
  check:
    trip traces[A4]
    trip traces[B4]

proc noPassAtoBOnHighX* =
  let (_, traces) = setup()

  set traces[X1]
  setLevel traces[A1], 0.5
  check trip traces[B1]

  set traces[X2]
  setLevel traces[A2], 0.75
  check trip traces[B2]

  set traces[X3]
  setLevel traces[A3], 0.25
  check trip traces[B3]

  set traces[X4]
  setLevel traces[A4], 1
  check trip traces[B4]

proc noPassBtoAOnHighX* =
  let (_, traces) = setup()

  set traces[X1]
  setLevel traces[B1], 0.5
  check trip traces[A1]

  set traces[X2]
  setLevel traces[B2], 0.75
  check trip traces[A2]

  set traces[X3]
  setLevel traces[B3], 0.25
  check trip traces[A3]

  set traces[X4]
  setLevel traces[B4], 1
  check trip traces[A4]

proc lastSetA* =
  let (_, traces) = setup()

  set traces[X1]
  setLevel traces[B1], 1.5
  setLevel traces[A1], 0.5
  clear traces[X1]
  check (level traces[B1]) == 0.5

  set traces[X2]
  setLevel traces[B2], 1.5
  setLevel traces[A2], 0.75
  clear traces[X2]
  check (level traces[B2]) == 0.75

  set traces[X3]
  setLevel traces[B3], 1.5
  setLevel traces[A3], 0.25
  clear traces[X3]
  check (level traces[B3]) == 0.25

  set traces[X4]
  setLevel traces[B4], 1.5
  setLevel traces[A4], 1
  clear traces[X4]
  check (level traces[B4]) == 1

proc lastSetB* =
  let (_, traces) = setup()

  set traces[X1]
  setLevel traces[A1], 1.5
  setLevel traces[B1], 0.5
  clear traces[X1]
  check (level traces[A1]) == 0.5

  set traces[X2]
  setLevel traces[A2], 1.5
  setLevel traces[B2], 0.75
  clear traces[X2]
  check (level traces[A2]) == 0.75

  set traces[X3]
  setLevel traces[A3], 1.5
  setLevel traces[B3], 0.25
  clear traces[X3]
  check (level traces[A3]) == 0.25

  set traces[X4]
  setLevel traces[A4], 1.5
  setLevel traces[B4], 1
  clear traces[X4]
  check (level traces[A4]) == 1

proc lastSetNone* =
  let (_, traces) = setup()

  set traces[X1]
  clear traces[X1]
  check:
    (level traces[A1]) == 0
    (level traces[B1]) == 0

  set traces[X2]
  clear traces[X2]
  check:
    lowp traces[A2]
    lowp traces[B2]

  set traces[X3]
  clear traces[X3]
  check:
    lowp traces[A3]
    lowp traces[B3]

  set traces[X4]
  clear traces[X4]
  check:
    lowp traces[A4]
    lowp traces[B4]
