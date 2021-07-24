# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ./chips/ic7406
import ./chips/ic7408
import ./chips/ic74139
import ./chips/ic74257
import ./chips/ic74258
import ./chips/ic74373

proc ic7406Tests =
  suite "7406 hex inverter":
    test "output low when input high": lowOnHighIn()
    test "output high when input low": highOnLowIn()

proc ic7408Tests =
  suite "7408 quad 2-input AND gate":
    test "proper outputs on gate 1 inputs": gate1()
    test "proper outputs on gate 2 inputs": gate2()
    test "proper outputs on gate 3 inputs": gate3()
    test "proper outputs on gate 4 inputs": gate4()

proc ic74139Tests =
  suite "74139 dual 2-to-4 demultiplexer":
    suite "demux 1":
      test "with high G1": demux1HighG()
      test "with L/L inputs": demux1LL()
      test "with H/L inputs": demux1HL()
      test "with L/H inputs": demux1LH()
      test "with H/H inputs": demux1HH()
    suite "demux 2":
      test "with high G1": demux2HighG()
      test "with L/L inputs": demux2LL()
      test "with H/L inputs": demux2HL()
      test "with L/H inputs": demux2LH()
      test "with H/H inputs": demux2HH()

proc ic74257Tests =
  suite "74257 quad 2-to-1 multiplexer":
    suite "mux 1":
      test "low SEL selects A": mux1SelectA()
      test "high SEL selects B": mux1SelectB()
      test "high OE disables output": mux1HighOe()
    suite "mux 2":
      test "low SEL selects A": mux2SelectA()
      test "high SEL selects B": mux2SelectB()
      test "high OE disables output": mux2HighOe()
    suite "mux 3":
      test "low SEL selects A": mux3SelectA()
      test "high SEL selects B": mux3SelectB()
      test "high OE disables output": mux3HighOe()
    suite "mux 4":
      test "low SEL selects A": mux4SelectA()
      test "high SEL selects B": mux4SelectB()
      test "high OE disables output": mux4HighOe()

proc ic74258Tests =
  suite "74258 quad 2-to-1 multiplexer":
    suite "mux 1":
      test "low SEL selects A": inv1SelectA()
      test "high SEL selects B": inv1SelectB()
      test "high OE disables output": inv1HighOe()
    suite "mux 2":
      test "low SEL selects A": inv2SelectA()
      test "high SEL selects B": inv2SelectB()
      test "high OE disables output": inv2HighOe()
    suite "mux 3":
      test "low SEL selects A": inv3SelectA()
      test "high SEL selects B": inv3SelectB()
      test "high OE disables output": inv3HighOe()
    suite "mux 4":
      test "low SEL selects A": inv4SelectA()
      test "high SEL selects B": inv4SelectB()
      test "high OE disables output": inv4HighOe()

proc chipTests* =
  ic7406Tests()
  ic7408Tests()
  ic74139Tests()
  ic74257Tests()
  ic74258Tests()

when isMainModule:
  chipTests()
