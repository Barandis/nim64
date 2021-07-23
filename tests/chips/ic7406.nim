# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ../../src/nim64/chips/ic7406
import ../../src/nim64/components/link

proc getTraces(chip: Ic7406): seq[Trace] =
  result.add(nil)
  for pin in chip:
    let trace = newTrace(pin)
    result.add(trace)

proc lowOnHighIn*() =
  let chip = newIc7406()
  let tr = getTraces(chip)

  tr[A1].set()
  tr[A2].set()
  tr[A3].set()
  tr[A4].set()
  tr[A5].set()
  tr[A6].set()

  check:
    tr[Y1].low
    tr[Y2].low
    tr[Y3].low
    tr[Y4].low
    tr[Y5].low
    tr[Y6].low

proc highOnLowIn*() =
  let chip = newIc7406()
  let tr = getTraces(chip)

  tr[A1].clear()
  tr[A2].clear()
  tr[A3].clear()
  tr[A4].clear()
  tr[A5].clear()
  tr[A6].clear()

  check:
    tr[Y1].high
    tr[Y2].high
    tr[Y3].high
    tr[Y4].high
    tr[Y5].high
    tr[Y6].high