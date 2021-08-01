# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Control register bits
const
  GATE {.used.} = 0
  SYNC {.used.} = 1
  RING {.used.} = 2
  TEST {.used.} = 3
  TRIANGLE {.used.} = 4
  SAWTOOTH {.used.} = 5
  PULSE {.used.} = 6
  NOISE {.used.} = 7

# Filter control register bits
const
  FILTV1 {.used.} = 0
  FILTV2 {.used.} = 1
  FILTV3 {.used.} = 2
  FILTEXT {.used.} = 3

# Filter select register bits
const
  FILTLP {.used.} = 4
  FILTBP {.used.} = 5
  FILTHP {.used.} = 6
  DSCNV3 {.used.} = 7
