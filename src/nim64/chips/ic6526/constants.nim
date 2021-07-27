# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Interrupt Control Register bits
const 
  TA {.used.} = 0
  TB {.used.} = 1
  ALRM {.used.} = 2
  SPT {.used.} = 3
  FLG {.used.} = 4
  IR {.used.} = 7
  SC {.used.} = 7

# Control Register bits
const 
  START {.used.} = 0
  PBON {.used.} = 1
  OUTMODE {.used.} = 2
  RUNMODE {.used.} = 3
  LOAD {.used.} = 4
  INMODE {.used.} = 5
  INMODE0 {.used.} = 5
  SPMODE {.used.} = 6
  INMODE1 {.used.} = 6
  TODIN {.used.} = 7
  ALARM {.used.} = 7

# Other register bits
const PM {.used.} = 7