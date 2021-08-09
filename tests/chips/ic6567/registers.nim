# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import random
import sequtils

include ./common

randomize()

proc read_write_regular =
  setup()

  for i in 0..<BORDER:
    if i notin [RASTER, CTRL1, CTRL2, MEMPTR, IR, IE, MMCOL, MDCOL]:
      let value = uint8(rand(256))
      write_register(uint(i), value)
      check read_register(uint(i)) == value

proc read_write_bottom_four =
  setup()

  for i in concat(@[IE], to_seq(BORDER..<UNUSED1)):
    let value = uint8(rand(256))
    write_register(uint(i), value)
    check read_register(uint(i)) == (value or 0b11110000)

proc read_write_ctrl2 =
  setup()

  for _ in 1..8:
    let value = uint8(rand(256))
    write_register(CTRL2, value)
    check read_register(CTRL2) == (value or 0b11000000)

proc read_write_ir =
  setup()

  for _ in 1..8:
    let value = uint8(rand(256))
    write_register(IR, value)
    check read_register(IR) == (value or 0b01110000)

proc read_write_unused =
  setup()

  for i in UNUSED1..UNUSED17:
    let value = uint8(rand(256))
    write_register(uint(i), value)
    check read_register(uint(i)) == 0xff

proc read_write_read_only =
  for _ in 1..8:
    let value = uint8(rand(256))
    write_register(MMCOL, value)
    write_register(MDCOL, value)
    write_register(RASTER, value)
    check:
      read_register(MMCOL) == 0
      read_register(MDCOL) == 0
      read_register(RASTER) == 0

proc read_write_ctrl1 =
  setup()

  for _ in 1..8:
    let value = uint8(rand(256))
    write_register(CTRL1, value)
    check read_register(CTRL1) == (value and 0b01111111)

proc all_tests* =
  suite "6567 registers":
    test "read from and write to full 8-bit registers": read_write_regular()
    test "read from and write to bottom 4-bit registers": read_write_bottom_four()
    test "read from and write to CTRL2 (bottom 6 bits)": read_write_ctrl2()
    test "read from and write to IR (bits 0-3, 7)": read_write_ir()
    test "read from and write to unused registers": read_write_unused()
    test "collision and raster registers are read-only": read_write_read_only()
    test "bit 7 of CTRL1 is read-onlyy": read_write_ctrl1()

when is_main_module:
  all_tests()
