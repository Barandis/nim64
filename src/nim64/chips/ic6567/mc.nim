# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https:#opensource.org/licenses/MIT

import strformat
import ./access
import ./constants
import ./raster
import ../../utils
import ../../components/registers

type Mc* = ref object
  num: uint
  counter: RasterCounter
  registers: Registers
  mc: uint
  mcbase: uint
  yexp: bool
  dma: bool
  display: bool
  ptr_cycle: uint

proc new_mc*(num: uint, counter: RasterCounter, registers: Registers): Mc =
  Mc(
    num: num,
    counter: counter,
    registers: registers,
    mc: 0,
    mcbase: 0,
    yexp: true,
    dma: false,
    display: false,
    ptr_cycle: MOB_PTR_CYCLES[num],
  )

proc pre_read*(mc: Mc) =
  let raster = raster(mc.counter)
  let cycle = cycle(mc.counter)
  let phase = phase(mc.counter)
  let mobyex = bit_set(mc.registers[MOBYEX], mc.num)
  let moben = bit_set(mc.registers[MOBEN], mc.num)
  let moby = mc.registers[&"MOB{mc.num}Y"]

  # 7. In the first phase of cycle 15, it is checked if the expansion flip flop is set. If
  #    so, MCBASE is incremented by 2.
  if cycle == 15 and phase == 1 and mc.yexp:
    mc.mcbase += 2

  # 8. In the first phase of cycle 16, it is checked if the expansion flip flop is set. If
  #    so, MCBASE is incremented by 1. After that, the VIC checks if MCBASE is equal to 63
  #    and turns of the DMA and the display of the sprite if it is.
  if cycle == 16 and phase == 1:
    if mc.yexp:
      mc.mcbase += 1
    if mc.mcbase == 63:
      mc.dma = false
      mc.display = false

  # 2. If the MxYE bit is set in the first phase of cycle 55, the expansion flip flop is
  #    inverted.
  if cycle == 55 and phase == 1 and mobyex:
    mc.yexp = not mc.yexp

  # 3. In the first phases of cycle 55 and 56, the VIC checks for every sprite if the
  #    corresponding MxE bit in register $d015 is set and the Y coordinate of the sprite
  #    (odd registers $d001-$d00f) match the lower 8 bits of RASTER. If this is the case and
  #    the DMA for the sprite is still off, the DMA is switched on, MCBASE is cleared, and
  #    if the MxYE bit is set the expansion flip flip is reset.
  if (cycle == 55 or cycle == 56) and phase == 1:
    if moben and moby == (raster and 0xff) and not mc.dma:
      mc.dma = true
      mc.mcbase = 0
      if mobyex:
        mc.yexp = false

  # 4. In the first phase of cycle 58, the MC of every sprite is loaded from its belonging
  #    MCBASE (MCBASE->MC) and it is checked if the DMA for the sprite is turned on and the
  #    Y coordinate of the sprite matches the lower 8 bits of RASTER. If this is the case,
  #    the display of the sprite is turned on.
  if cycle == 58 and phase == 1:
    mc.mc = mc.mcbase
    if mc.dma and moby == (raster and 0xff):
      mc.display = true

proc post_read*(mc: Mc, access: AccessType) =
  let cycle = cycle(mc.counter)
  # 5. If the DMA for a sprite is turned on, three s-accesses are done in sequence in the
  #    corresponding cycles assigned to the sprite (see the diagrams in section 3.6.3.). The
  #    p-accesses are always done, even if the sprite is turned off. The read data of the
  #    first access is stored in the upper 8 bits of the shift register, that of the second
  #    one in the middle 8 bits and that of the third one in the lower 8 bits. MC is
  #    incremented by one after each s-access.
  if access == MobData and (cycle == mc.ptr_cycle or cycle == mc.ptr_cycle + 1):
    mc.mc += 1

proc clear_yexp*(mc: Mc) =
  # 1. The expansion flip flip is set as long as the bit in MxYE in register $d017
  #    corresponding to the sprite is cleared.
  #
  # This was not clear to me as I read it. Other literature has indicated that it means that
  # the latch bit (called "flip flip" here and almost certainly actually meaning "flip
  # flop") is set *when* the appropriate bit in the register (SPRYEX in this code) is
  # cleared. The latch bit does not change if the bit in the register is set.
  #
  # This is actually vital because setting that latch bit (but turning off Y-expansion) at a
  # precise cycle/phase and then turning Y-expansion back on without affecting the latch bit
  # is what enables sprite crunching.
  mc.yexp = true

proc mc*(mc: Mc): uint =
  mc.mc

proc dma*(mc: Mc): bool =
  mc.dma

proc display*(mc: Mc): bool =
  mc.display
