# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ../utils
import ../../src/nim64/chips/ic74139
import ../../src/nim64/components/link

proc setup(): (Ic74139, Traces) =
  let chip = newIc74139()
  result = (chip, deviceTraces(chip))

proc demux1Initial*() =
  let (_, traces) = setup()

  check:
    traces[Y01].low
    traces[Y11].high
    traces[Y21].high
    traces[Y31].high

proc demux1HighG*() =
  let (_, traces) = setup()

  +traces[G1]
  -traces[A1]
  -traces[B1]
  check:
    traces[Y01].high
    traces[Y11].high
    traces[Y21].high
    traces[Y31].high
  
  +traces[A1]
  check:
    traces[Y01].high
    traces[Y11].high
    traces[Y21].high
    traces[Y31].high
  
  +traces[B1]
  check:
    traces[Y01].high
    traces[Y11].high
    traces[Y21].high
    traces[Y31].high
  
  -traces[A1]
  check:
    traces[Y01].high
    traces[Y11].high
    traces[Y21].high
    traces[Y31].high

proc demux1LL*() =
  let (_, traces) = setup()

  -traces[G1]
  -traces[A1]
  -traces[B1]
  check:
    traces[Y01].low
    traces[Y11].high
    traces[Y21].high
    traces[Y31].high

proc demux1HL*() =
  let (_, traces) = setup()

  -traces[G1]
  +traces[A1]
  -traces[B1]
  check:
    traces[Y01].high
    traces[Y11].low
    traces[Y21].high
    traces[Y31].high

proc demux1LH*() =
  let (_, traces) = setup()

  -traces[G1]
  -traces[A1]
  +traces[B1]
  check:
    traces[Y01].high
    traces[Y11].high
    traces[Y21].low
    traces[Y31].high

proc demux1HH*() =
  let (_, traces) = setup()

  -traces[G1]
  +traces[A1]
  +traces[B1]
  check:
    traces[Y01].high
    traces[Y11].high
    traces[Y21].high
    traces[Y31].low

proc demux2Initial*() =
  let (_, traces) = setup()

  check:
    traces[Y02].low
    traces[Y12].high
    traces[Y22].high
    traces[Y32].high

proc demux2HighG*() =
  let (_, traces) = setup()

  +traces[G2]
  -traces[A2]
  -traces[B2]
  check:
    traces[Y02].high
    traces[Y12].high
    traces[Y22].high
    traces[Y32].high
  
  +traces[A1]
  check:
    traces[Y02].high
    traces[Y12].high
    traces[Y22].high
    traces[Y32].high
  
  +traces[B2]
  check:
    traces[Y02].high
    traces[Y12].high
    traces[Y22].high
    traces[Y32].high
  
  -traces[A2]
  check:
    traces[Y02].high
    traces[Y12].high
    traces[Y22].high
    traces[Y32].high

proc demux2LL*() =
  let (_, traces) = setup()

  -traces[G2]
  -traces[A2]
  -traces[B2]
  check:
    traces[Y02].low
    traces[Y12].high
    traces[Y22].high
    traces[Y32].high

proc demux2HL*() =
  let (_, traces) = setup()

  -traces[G2]
  +traces[A2]
  -traces[B2]
  check:
    traces[Y02].high
    traces[Y12].low
    traces[Y22].high
    traces[Y32].high

proc demux2LH*() =
  let (_, traces) = setup()

  -traces[G2]
  -traces[A2]
  +traces[B2]
  check:
    traces[Y02].high
    traces[Y12].high
    traces[Y22].low
    traces[Y32].high

proc demux2HH*() =
  let (_, traces) = setup()

  -traces[G2]
  +traces[A2]
  +traces[B2]
  check:
    traces[Y02].high
    traces[Y12].high
    traces[Y22].high
    traces[Y32].low
