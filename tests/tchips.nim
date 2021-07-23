# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import ./chips/ic7406
import ./chips/ic7408
import ./chips/ic74139

proc ic7406Tests() =
  suite "7406 hex inverter":
    test "initial levels": initial7406()
    test "output low when input high": lowOnHighIn()
    test "output high when input low": highOnLowIn()

proc ic7408Tests() =
  suite "7408 quad 2-input AND gate":
    test "initial levels": initial7408()
    test "proper outputs on gate 1 inputs": gate1()
    test "proper outputs on gate 2 inputs": gate2()
    test "proper outputs on gate 3 inputs": gate3()
    test "proper outputs on gate 4 inputs": gate4()

proc ic74139Tests() =
  suite "74139 dual 2-to-4 demultiplexer":
    test "demux 1 initial levels": demux1Initial()
    test "demux 1 with high G1": demux1HighG()
    test "demux 1 with L/L inputs": demux1LL()
    test "demux 1 with H/L inputs": demux1HL()
    test "demux 1 with L/H inputs": demux1LH()
    test "demux 1 with H/H inputs": demux1HH()
    test "demux 2 initial levels": demux2Initial()
    test "demux 2 with high G1": demux2HighG()
    test "demux 2 with L/L inputs": demux2LL()
    test "demux 2 with H/L inputs": demux2HL()
    test "demux 2 with L/H inputs": demux2LH()
    test "demux 2 with H/H inputs": demux2HH()

proc chipTests*() =
  ic7406Tests()
  ic7408Tests()
  ic74139Tests()

when isMainModule:
  chipTests()
