# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

from math import classify, fcNan
import ./components/link

proc isNaN*(n: float): bool {.inline.} =
  ## Utility function to determine whether a float is `NaN`. This is used in place of
  ## comparisons since `NaN != NaN`.
  (classify n) == fcNaN

proc valueToPins*(value: uint, pins: seq[Pin]) =
  for i, pin in pins:
    setLevel pin, float(value shr i and 1)

proc pinsToValue*(pins: seq[Pin]): uint =
  for i, pin in pins:
    result = result or uint(level pin) shl i

proc modeToPins*(mode: Mode, pins: seq[Pin]) =
  for pin in pins:
    setMode pin, mode

proc triPins*(pins: seq[Pin]) =
  for pin in pins:
    tri pin
