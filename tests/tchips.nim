# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ./chips/ic2114
import ./chips/ic2332
import ./chips/ic2364
import ./chips/ic4066
import ./chips/ic7406
import ./chips/ic7408
import ./chips/ic74139
import ./chips/ic74257
import ./chips/ic74258
import ./chips/ic74373

proc ic2332Tests =
  suite "2332 4k x 8 ROM":
    test "reads all CHAROM memory locations": readAll()

proc ic2364Tests =
  suite "2364 8k x 8 ROM":
    test "reads all BASIC memory locations": readBasic()
    test "reads all KERNAL memory locations": readKernal()

proc ic4066Tests =
  suite "4066 quad analog switch":
    test "pass signals from A to B": passAtoB()
    test "pass signals from B to A": passBtoA()
    test "disconnect I/O on high X": disconOnHighX()
    test "does not pass signals from A to B on high X": noPassAtoBOnHighX()
    test "does not pass signals from B to A on high X": noPassBtoAOnHighX()
    test "sets B to A if A was last set": lastSetA()
    test "sets A to B if B was last set": lastSetB()
    test "clears A and B if neither was last set": lastSetNone()

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

proc ic74373Tests =
  suite "74373 octal transparent latch":
    test "data passes through on LE high": passOnLeHigh()
    test "data latches on LE low": latchOnLeLow()
    test "data returns to pass through when LE goes high": returnToPass()
    test "outputs tri-state on OE high": triOnOeHigh()
    test "latching still happens when OE is high": latchOnOeHigh()

proc chipTests* =
  ic2114.allTests()
  ic2332Tests()
  ic2364Tests()
  ic4066Tests()
  ic7406Tests()
  ic7408Tests()
  ic74139Tests()
  ic74257Tests()
  ic74258Tests()
  ic74373Tests()

when isMainModule:
  chipTests()
