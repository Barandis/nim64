# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import tables
import ../../../src/nim64/chips/ic6581/envelope

# copied from the source file
const RateTargets: array[16, uint] = [
  9u,     #   2ms =     7.81 periods
  32u,    #   8ms =    31.25 periods
  63u,    #  16ms =    62.50 periods
  95u,    #  24ms =    93.75 periods
  149u,   #  38ms =   148.44 periods
  220u,   #  56ms =   218.75 periods
  267u,   #  68ms =   265.63 periods
  313u,   #  80ms =   312.50 periods
  392u,   # 100ms =   390.63 periods
  977u,   # 250ms =   976.56 periods
  1954u,  # 500ms =  1953.13 periods
  3126u,  # 800ms =  3125.00 periods
  3907u,  #    1s =  3906.25 periods
  11720u, #    3s = 11718.75 periods
  19532u, #    5s = 19531.25 periods
  31251u, #    8s = 31250.00 periods
]

let breakpoints = to_table([
  (0xffu, 1), (0x5du, 2), (0x36u, 4), (0x1au, 8), (0x0eu, 16), (0x06u, 30)])

proc setup: Envelope =
  let env = new_envelope()
  env

# Tests that a newly gated envelope takes the correct number of cycles to rise from 0 to
# 255, according to the attack parameter.
proc attack =
  let env = setup()
  surel(env, 0)

  for att in 0u..15u:
    atdcy(env, att shl 4)
    vcreg(env, 1)

    for i in 0u..255u:
      check output(env) == i
      for _ in 1..RateTargets[int(att)]: clock(env)

    vcreg(env, 0)
    while output(env) > 0: clock(env)

# Tests that an envelope, after reaching 255 in the attack, takes the correct number of
# cycles in the right shape to go back down to 0.
proc decay =
  let env = setup()
  surel(env, 0)

  for dec in 0u..15u:
    atdcy(env, dec)
    vcreg(env, 1)

    while output(env) < 255: clock(env)
    
    var falloff = 1
    
    for i in countdown(255u, 0u):
      if i in breakpoints: falloff = breakpoints[i]
      check output(env) == i
      for _ in 1..RateTargets[int(dec)]:
        for _ in 1..falloff: clock(env)
    
    vcreg(env, 0)

# Tests that an envelope, after attacking to 255 and decaying to the sustain level,
# maintains that sustain level until the gate bit is turned off.
proc sustain =
  let env = setup()
  atdcy(env, 0)

  for sus in 0u..15u:
    let sus_val = (sus shl 4) or sus
    surel(env, sus shl 4)
    vcreg(env, 1)

    while output(env) < 255: clock(env)
    while output(env) > sus_val: clock(env)
    
    for _ in 1..1024:
      clock(env)
      check output(env) == sus_val

    vcreg(env, 0)
    while output(env) > 0: clock(env)

# Tests that after the gate bit is turned off on a $F sustain envelope, it takes the correct
# number of cycles in the correct shape to return to 0.
proc release =
  let env = setup()
  atdcy(env, 0)

  for rel in 0u..15u:
    surel(env, 0xf0 or rel)
    vcreg(env, 1)

    while output(env) < 255: clock(env)
    vcreg(env, 0)
    
    var falloff = 1
    
    for i in countdown(255u, 0u):
      if i in breakpoints: falloff = breakpoints[i]
      check output(env) == i
      for _ in 1..RateTargets[int(rel)]:
        for _ in 1..falloff: clock(env)

proc all_tests* =
  suite "6581 envelope generator":
    test "all 15 attack values": attack()
    test "all 15 decay values": decay()
    test "all 15 sustain values": sustain()
    test "all 15 release values": release()

if is_main_module:
  all_tests()
