# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://#opensource.org/licenses/MIT

import math
import sequtils
import strformat
import ../../utils
import ../../components/[link, pins, registers]
import ./access
import ./constants
import ./mc
import ./raster
import ./vcrc

type MemoryController* = ref object
  pins: Pins
  addr_mux_pins: seq[Pin]
  addr_pins: seq[Pin]
  data_12_pins: seq[Pin]
  data_8_pins: seq[Pin]
  registers: Registers
  counter: RasterCounter
  char_ptrs: seq[uint]
  mob_ptr: uint
  refresh: uint
  vcrc: VcRc
  mcs: seq[Mc]

proc new_memory_controller*(
  counter: RasterCounter,
  pins: Pins,
  registers: Registers
): MemoryController =
  # These pin subsets are included directly in the type because that's how we make sure this
  # code doesn't need to be run more than once.
  let addr_mux_pins = map(to_seq(24..29), proc (i: int): Pin = pins[i])
  let addr_pins = concat(addr_mux_pins, map(to_seq(6..11), proc (i: int): Pin = pins[&"A{i}"]))
  let data_12_pins = map(to_seq(0..11), proc (i: int): Pin = pins[&"D{i}"])
  let data_8_pins = map(to_seq(0..7), proc (i: int): Pin = pins[&"D{i}"])

  MemoryController(
    pins: pins,
    addr_mux_pins: addr_mux_pins,
    addr_pins: addr_pins,
    data_12_pins: data_12_pins,
    data_8_pins: data_8_pins,
    registers: registers,
    counter: counter,
    char_ptrs: new_seq[uint](40),
    mob_ptr: 0,
    refresh: 0xff,
    vcrc: new_vc_rc(),
    mcs: map(to_seq(0u..7u), proc(x: uint): Mc = new_mc(x, counter, registers)),
  )

proc access_type(memory: MemoryController): AccessType =
  ## Determines the access type of the next memory read. The access type determines how an
  ## address for that read is generated and what happens to the data after its read.
  ##
  ## There are seven types of access here:
  ##
  ##   `VmColor` (c-access): read the video matrix and color memory
  ##   `BmChar` (g-access): read bitmap/character data
  ##   `MobPtr` (p-access): read mob pointers
  ##   `MobData` (s-access): read mob data
  ##   `Refresh` (r-access): read DRAM for refresh purposes
  ##   `Idle` (i-access): do nothing (reads a fixed address and discards the data)
  ##   `Cpu` (x-access): do nothing because the CPU controls the address bus
  ##
  ## There must be a memory access in every phase. If the CPU has bus control, it can read
  ## or write as it chooses. If the VIC has bus control, it will make one read every phase,
  ## whether it needs the data or not.
  let phase = phase(memory.counter)
  let cycle = cycle(memory.counter)
  let bad_line = bad_line(memory.counter)
  let mcs = memory.mcs

  if phase == 1:
    if cycle in MOB_PTR_CYCLES: MobPtr
    elif cycle == 2 and bad_line and dma(mcs[3]): MobData
    elif cycle == 4 and bad_line and dma(mcs[4]): MobData
    elif cycle == 6 and bad_line and dma(mcs[5]): MobData
    elif cycle == 8 and bad_line and dma(mcs[6]): MobData
    elif cycle == 10 and bad_line and dma(mcs[7]): MobData
    elif cycle >= 11 and cycle <= 15: Refresh
    elif cycle >= 16 and cycle <= 55: BmChar
    elif cycle == 61 and bad_line and dma(mcs[0]): MobData
    elif cycle == 63 and bad_line and dma(mcs[1]): MobData
    elif cycle == 65 and bad_line and dma(mcs[2]): MobData
    else: Idle
  else:
    if (cycle == 1 or cycle == 2) and bad_line and dma(mcs[3]): MobData
    elif (cycle == 3 or cycle == 4) and bad_line and dma(mcs[4]): MobData
    elif (cycle == 5 or cycle == 6) and bad_line and dma(mcs[5]): MobData
    elif (cycle == 7 or cycle == 8) and bad_line and dma(mcs[6]): MobData
    elif (cycle == 9 or cycle == 10) and bad_line and dma(mcs[7]): MobData
    elif cycle >= 15 and cycle <= 54 and bad_line: VmColor
    elif (cycle == 60 or cycle == 61) and bad_line and dma(mcs[0]): MobData
    elif (cycle == 62 or cycle == 63) and bad_line and dma(mcs[1]): MobData
    elif (cycle == 64 or cycle == 65) and bad_line and dma(mcs[2]): MobData
    else: Cpu

proc i_address(memory: MemoryController): uint =
  ## Return an address for making an i-access. This is an idle access in display mode, not
  ## an idle-mode access (which are g-accesses that occur before the first visible raster
  ## line and after the last visible raster line). The address of an i-access is fixed.
  0x3fff

proc r_address(memory: MemoryController): uint =
  ## Return an address for making an r-access. This is a DRAM address that decrements with
  ## each read. The read data is discarded, as the sole purpose of this access is to refresh
  ## the dynamic RAM.
  result = 0x3f00 or memory.refresh
  memory.refresh = (memory.refresh - 1) and 0xff

proc c_address(memory: MemoryController): uint =
  ## Determines the address for reading in a c-access. This is used during bad lines to
  ## fetch either color data and character poitners (in text modes) or bitmap data (in
  ## bitmap modes).

  #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
  #  | 13 | 12 | 11 | 10 |  9 |  8 |  7 |  6 |  5 |  4 |  3 |  2 |  1 |  0 |
  #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
  #  |VM13|VM12|VM11|VM10| VC9| VC8| VC7| VC6| VC5| VC4| VC3| VC2| VC1| VC0|
  #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
  let matrix = uint(hi4(memory.registers[MEMPTR]))
  (matrix shl 10) or memory.vcrc.vc

proc g_address(memory: MemoryController): uint =
  ## Calculates the memory address to be read during a g-access. The address read depends on
  ## the graphics mode. Only five of the modes are actually valid; the other three produce
  ## only black pixels, but the address is still read and it is possible to still have
  ## mob/data collisions with that otherwise-invisible data.
  let registers = memory.registers

  # In idle mode (which is before the first visible line and after the last), the address is
  # set based solely on the value of ECM.
  if idle(memory.vcrc):
    if bit_set(registers[CTRL1], ECM): 0x39ffu else: 0x3fffu
  else:
    # Representing the mode as a 3-bit number made up of the ECM, BMM, and MCM flags
    # because it makes it a lot easier to use `case` from
    let mode = (bit_value(registers[CTRL1], ECM) shl 2) or
      (bit_value(registers[CTRL1], BMM) shl 1) or
      bit_value(registers[CTRL1], MCM)

    case mode:
      of 0, 1:
        # Standard text mode
        # Multicolor text mode
        #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
        #  | 13 | 12 | 11 | 10 |  9 |  8 |  7 |  6 |  5 |  4 |  3 |  2 |  1 |  0 |
        #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
        #  |CB13|CB12|CB11| D7 | D6 | D5 | D4 | D3 | D2 | D1 | D0 | RC2| RC1| RC0|
        #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
        let cb = uint(lo4(registers[MEMPTR])) shr 1
        let data = memory.char_ptrs[cycle(memory.counter) - 16]
        (cb shl 11) or (data shl 3) or memory.vcrc.rc

      of 2, 3:
        # Standard bitmap mode
        # Multicolor bitmap mode
        #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
        #  | 13 | 12 | 11 | 10 |  9 |  8 |  7 |  6 |  5 |  4 |  3 |  2 |  1 |  0 |
        #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
        #  |CB13| VC9| VC8| VC7| VC6| VC5| VC4| VC3| VC2| VC1| VC0| RC2| RC1| RC0|
        #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
        let cb = uint(bit_value(registers[MEMPTR], CB13))
        let data = memory.vcrc.vc
        (cb shl 13) or (data shl 3) or memory.vcrc.rc

      of 4, 5:
        # Extended color text mode
        # Invalid text mode
        #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
        #  | 13 | 12 | 11 | 10 |  9 |  8 |  7 |  6 |  5 |  4 |  3 |  2 |  1 |  0 |
        #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
        #  |CB13|CB12|CB11|  0 |  0 | D5 | D4 | D3 | D2 | D1 | D0 | RC2| RC1| RC0|
        #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
        let cb = uint(lo4(registers[MEMPTR])) shr 1
        let data = memory.char_ptrs[cycle(memory.counter) - 16] and 0x3f
        (cb shl 11) or (data shl 3) or memory.vcrc.rc

      of 6, 7:
        # Invalid bitmap mode 1
        # Invalid bitmap mode 2
        #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
        #  | 13 | 12 | 11 | 10 |  9 |  8 |  7 |  6 |  5 |  4 |  3 |  2 |  1 |  0 |
        #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
        #  |CB13| VC9| VC8|  0 |  0 | VC5| VC4| VC3| VC2| VC1| VC0| RC2| RC1| RC0|
        #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
        let cb = uint(bit_value(registers[MEMPTR], CB13))
        let data = memory.vcrc.vc and 0b1100111111
        (cb shl 13) or (data shl 3) or memory.vcrc.rc

      else:
        # Put here to keep the compiler happy, all 8 possible cases are already handled and
        # this code is never reached
        0

proc p_address(memory: MemoryController, num: uint): uint =
  ## Calculates an address at which to make a p-access. The addresses here are at the end of
  ## the 1024-byte block of video matrix data (the first 1000 bytes are used for character
  ## pointers or bitmap data). The data returned from these addresses are pointers to sprite
  ## data.

  #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+r
  #  | 13 | 12 | 11 | 10 |  9 |  8 |  7 |  6 |  5 |  4 |  3 |  2 |  1 |  0 |
  #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
  #  |VM13|VM12|VM11|VM10|  1 |  1 |  1 |  1 |  1 |  1 |  1 |  Mob number  |
  #  +----+----+----+----+----+----+----+----+----+----+----+--------------+
  let vm = uint(hi4(memory.registers[MEMPTR]))
  (vm shl 10) or 0b1111111000 or num

proc s_address(memory: MemoryController, num: int): uint =
  ## Calculates an address for making an s-access. The address depends on the value that
  ## came from the preceding p-access, and the data at the provided address will be raw
  ## sprite data.

  #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
  #  | 13 | 12 | 11 | 10 |  9 |  8 |  7 |  6 |  5 |  4 |  3 |  2 |  1 |  0 |
  #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
  #  | MP7| MP6| MP5| MP4| MP3| MP2| MP1| MP0| MC5| MC4| MC3| MC2| MC1| MC0|
  #  +----+----+----+----+----+----+----+----+----+----+----+----+----+----+
  (memory.mob_ptr shl 6) or mc(memory.mcs[num])

proc generate_address*(memory: MemoryController): (AccessType, uint) =
  ## Generates the next read address. Which is used depends on the current state of the
  ## raster counter (the current raster line and clock phase and cycle).
  let
    cycle = cycle(memory.counter)
    access = access_type(memory)

  (access, case access:
    of VmColor: c_address(memory)
    of BmChar: g_address(memory)
    of MobPtr:
      p_address(memory, if cycle >= 60: (cycle - 60) div 2 else: (cycle + 5) div 2)
    of MobData:
      s_address(memory,
        int(floor(if cycle >= 60: float(cycle - 60) / 2 else: float(cycle + 5) / 2))
      )
    of Refresh: r_address(memory)
    of Idle: i_address(memory)
    else: 0u)

proc ba_level(memory: MemoryController): float =
  ## Determines the level of the BA pin for this clock cycle and phase. BA is high by
  ## default but is pulled low three cycles before a sprite data access or a video matrix
  ## access and remains low until that access is complete. This gives the CPU three cycles
  ## to complete write accesses before the bus is claimed by the VIC.
  let
    cycle = cycle(memory.counter)
    bad_line = bad_line(memory.counter)

  # (Graphics)
  # 3. If there is a Bad Line Condition in cycles 12-54, BA is set low and the c-accesses
  #    are started. Once started, one c-access is done in the second phase of every clock
  #    cycle in the range 15-54. The read data is stored in the video matrix/color line at
  #    the position specified by VMLI. These data is internally read from the position
  #    specified by VMLI as well on each g-access in display state.
  if bad_line and cycle >= 12 and cycle <= 54:
    return 0.0

  # (Mobs)
  # 5. If the DMA for a sprite is turned on, three s-accesses are done in sequence in the
  #    corresponding cycles assigned to the sprite (see the diagrams in section 3.6.3.). The
  #    p-accesses are always done, even if the sprite is turned off. The read data of the
  #    first access is stored in the upper 8 bits of the shift register, that of the second
  #    one in the middle 8 bits and that of the third one in the lower 8 bits. MC is
  #    incremented by one after each s-access.
  #
  # Not mentioned here is that BA needs to go low three cycles before the p-access is done.
  for num, ba_cycles in MOB_BA_CYCLES:
    if dma(memory.mcs[num]) and cycle in ba_cycles:
      return 0.0

  return 1.0

proc aec_level(memory: MemoryController): float =
  ## Determines the level of the AEC pin. This is generally low during phase 1 and high
  ## during phase 2, but it will remain low while the VIC needs to access memory on phase 2
  ## (for pulling character pointers or sprite data). A low value means the VIC has control
  ## of the bus, while a high value means the CPU does.
  let
    phase = phase(memory.counter)
    cycle = cycle(memory.counter)
    bad_line = bad_line(memory.counter)

  # (Graphics)
  # 3. If there is a Bad Line Condition in cycles 12-54, BA is set low and the c-accesses
  #    are started. Once started, one c-access is done in the second phase of every clock
  #    cycle in the range 15-54. The read data is stored in the video matrix/color line at
  #    the position specified by VMLI. These data is internally read from the position
  #    specified by VMLI as well on each g-access in display state.
  if bad_line and cycle >= 15 and cycle <= 54:
    return 0.0

  # (Mobs)
  # 5. If the DMA for a sprite is turned on, three s-accesses are done in sequence in the
  #    corresponding cycles assigned to the sprite (see the diagrams in section 3.6.3.). The
  #    p-accesses are always done, even if the sprite is turned off. The read data of the
  #    first access is stored in the upper 8 bits of the shift register, that of the second
  #    one in the middle 8 bits and that of the third one in the lower 8 bits. MC is
  #    incremented by one after each s-access.
  for num, ptr_cycle in MOB_PTR_CYCLES:
    if dma(memory.mcs[num]) and (cycle == ptr_cycle or cycle == ptr_cycle + 1):
      return 0.0

  return float(phase - 1)

proc pre_read*(memory: MemoryController) =
  let counter = memory.counter
  ## Performs functions that need to happen before a memory read. This is largely updating
  ## the internal graphics registers, though it also includes setting the levels of BA and
  ## AEC and ensuring that all address pins are set to output mode.
  if raster(counter) == 0 and cycle(counter) == 1 and phase(counter) == 1:
    memory.refresh = 0xffu

  pre_read(memory.vcrc, counter)
  for mc in memory.mcs: pre_read(mc)

  set_level(memory.pins[BA], ba_level(memory))
  set_level(memory.pins[AEC], aec_level(memory))

  mode_to_pins(Output, memory.addr_mux_pins)

proc low_to_pins*(memory: MemoryController, address: uint) =
  ## Sets the levels of the address pins to the next address to be read. This actually sets
  ## *all* address pins; it's called `low_to_pins` because the multiplexed pins take on the
  ## value of the low address bits.
  let low = address and 0xfff
  value_to_pins(low, memory.addr_pins)

proc high_to_pins*(memory: MemoryController, address: uint) =
  ## Sets the levels of the multiplexed pins to the high address values. This does not
  ## change the levels of any unmultiplexed pins.
  let high = (address shr 8) and 0x3f
  value_to_pins(high, memory.addr_mux_pins)

proc read*(memory: MemoryController, access: AccessType): uint =
  ## Performs an actual memory read, which in the end is the entire point of this module.
  ## The number of bits in the read value depends on the type of access; this type is also
  ## used to determine which read values to remember for future reads. Cleanup is done after
  ## the read. This includes setting multiplexed address pins back to input mode,
  ## tri-stating other address pins, and updating some of the graphics and mob registers.

  # D8 to D11 are always Input anyway, so we don't set them again
  mode_to_pins(Input, memory.data_8_pins)

  if access == VmColor:
    result = pins_to_value(memory.data_12_pins)
  else:
    result = pins_to_value(memory.data_8_pins)

  mode_to_pins(Output, memory.data_8_pins)
  tri_pins(memory.data_8_pins)

  if access == VmColor:
    memory.char_ptrs[cycle(memory.counter) - 15] = result
  elif access == MobPtr:
    memory.mob_ptr = result
  # Don't do anything for other accesses; we care only about persisting pointer information

  mode_to_pins(Input, memory.addr_mux_pins)
  # While we're setting all address pins here to Z, input pins cannot be set directly and so
  # those pins are ignored by this statement.
  tri_pins(memory.addr_pins)

  post_read(memory.vcrc, access)
  for mc in memory.mcs: post_read(mc, access)

proc clear_yexp*(memory: MemoryController, cleared: uint) =
  ## Responsible for setting the sprite Y-expansion latches corresponding to 1-bits in the
  ## argument. The VIC immediately sets these latches when the corresponding Y-expansion
  ## register bit is cleared; it does nothing when that bit is *set*. This is what makes
  ## sprite crunching possible.
  ##
  ## This function just delegates to the sprite registers affected.
  for i in 0..7:
    if bit_set(cleared, i):
      clear_yexp(memory.mcs[i])
