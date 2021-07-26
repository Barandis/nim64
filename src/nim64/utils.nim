# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

from math import classify, fcNan
import ./components/link

proc nanp*(n: float): bool {.inline.} =
  ## Utility function to determine whether a float is `NaN`. This is used in place of
  ## comparisons since `NaN != NaN`.
  (classify n) == fcNaN

proc value_to_pins*(value: uint, pins: seq[Pin]) =
  ## Translates a value into binary and puts that binary value on the pins provided. The
  ## first pin in the sequence receives bit 0, the second one bit 1, and so on.
  for i, pin in pins:
    set_level pin, float(value shr i and 1)

proc pins_to_value*(pins: seq[Pin]): uint =
  ## Turns the bits on the provided sequence of pins into an unsigned integer, which is then
  ## returned. The first pin in the sequence provides bit 0, the second bit 1, and so on.
  for i, pin in pins:
    result = result or uint(level pin) shl i

proc mode_to_pins*(mode: Mode, pins: seq[Pin]) =
  ## A batch assignment of a mode to each pin within the provided sequence.
  for pin in pins:
    set_mode pin, mode

proc tri_pins*(pins: seq[Pin]) =
  ## A batch assignment of tri-state value (`NaN`) to each pin within the provided sequence.
  for pin in pins:
    tri pin
