# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import strformat
import strutils
import ../../../../src/nim64/chips/ic6581/envelope

const Path = "./docs/graphs/envelope"

proc write_to_file(name: string; values: seq[uint]) =
  let str = join(values, ",")
  let text = &"const {name} = [{str}]"
  let path = &"{Path}/{name}.js"
  write_file(path, text)
  echo(&"Wrote file {path}")

proc produce(env: Envelope, release = 0.5, iterations = 25000): seq[uint] =
  let pre = int(float(iterations) * release)
  let post = iterations - pre

  vcreg(env, 0x01)

  for _ in 1..pre:
    clock(env)
    add(result, output(env))

  vcreg(env, 0x00)

  for _ in 1..post:
    clock(env)
    add(result, output(env))

proc graph_adsr_0080 =
  let env = new_envelope()
  atdcy(env, 0x00)
  surel(env, 0x80)

  let values = produce(env)

  write_to_file("adsr0080", values)

proc graph_adsr_0000 =
  let env = new_envelope()
  atdcy(env, 0x00)
  surel(env, 0x00)

  let values = produce(env)

  write_to_file("adsr0000", values)

proc graph_adsr_00f0 =
  let env = new_envelope()
  atdcy(env, 0x00)
  surel(env, 0xf0)

  let values = produce(env)

  write_to_file("adsr00f0", values)

proc graph_adsr_1080 =
  let env = new_envelope()
  atdcy(env, 0x10)
  surel(env, 0x80)

  let values = produce(env)

  write_to_file("adsr1080", values)

proc graph_adsr_0180 =
  let env = new_envelope()
  atdcy(env, 0x01)
  surel(env, 0x80)

  let values = produce(env)

  write_to_file("adsr0180", values)

proc graph_adsr_0081 =
  let env = new_envelope()
  atdcy(env, 0x00)
  surel(env, 0x81)

  let values = produce(env)

  write_to_file("adsr0081", values)

proc graph_adsr_2080 =
  let env = new_envelope()
  atdcy(env, 0x20)
  surel(env, 0x80)

  let values = produce(env)

  write_to_file("adsr2080", values)

proc graph_wrapbug =
  let env = new_envelope()
  atdcy(env, 0xf0)
  surel(env, 0x80)

  let values = produce(env, 0.001)

  write_to_file("wrapbug", values)

proc all_graphs* =
  graph_adsr_0080()
  graph_adsr_0000()
  graph_adsr_00f0()
  graph_adsr_1080()
  graph_adsr_0180()
  graph_adsr_0081()
  graph_adsr_2080()
  graph_wrapbug()

if is_main_module:
  all_graphs()
