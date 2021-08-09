# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https:#opensource.org/licenses/MIT

import sequtils
import strformat
import sugar
import ../components/[chip, link]
import ../utils
import ./ic6567/memory
import ./ic6567/raster

import ./ic6567/constants
export constants except
  CYCLES_PER_LINE,
  RASTER_LINES_PER_FRAME,
  RASTER_MAX_VISIBLE,
  RASTER_MIN_VISIBLE,
  MOB_PTR_CYCLES

# Assumed frequency of the clock pulses coming in through the PHIIN pin, in MHz. This is
# divided by the appropriate number to produce a 1Mhz clock for PHI0. The physical C64 uses
# values of 8.181816 MHz (NTSC, used in North America and most of South America) or 7.881984
# MHz (PAL, used in most of Europe and Asia) on this pin; these are the frequencies
# necessary to produce video sync signals that would work on all TVs. This frequency was
# divided by 8 to get the CPU clock frequency (which is why PAL C64s were slightly slower
# than NTSC C64s).
#
# Since this emulation does not produce RF video signals, and since nothing in the system
# needs to be clocked faster than the CPU, this can just be 1.
const PHIDOT_FREQ = 1

chip Ic6567:
  pins:
    input:
      # Address pins. The VIC can address 16k of memory, though the lower and upper 6 bits
      # of the address bus are multiplexed. There are duplicates here; A8, for example, is
      # multiplexed with A0 on pin 24, but it's also available on its own on pin 32.
      #
      # The VIC makes reads from memory as a co-processor, so the address pins are outputs.
      # However, the VIC is also a device with registers that the CPU can read from and
      # write to, and for that reason the bottom 6 address lines are bidirectional (there
      # are 48 registers, so 6 bits is required to address them). The direction of A0-A5
      # therefore is controlled by the CS, AEC, and R_W pins.
      A0_A8: 24
      A1_A9: 25
      A2_A10: 26
      A3_A11: 27
      A4_A12: 28
      A5_A13: 29
      A6: 30
      A7: 31
      A8: 32
      A9: 33
      A10: 34
      A11: 23

      # Data bus pins. There are 12 of these because the upper 4 are used to access the
      # 4-bit-wide color RAM. This means that, since the VIC does not write to memory and
      # since only D0-D7 are needed to output data from registers, that D8-D11 are
      # input-only. The others are bidirectional as normal, with the direction controlled by
      # R_W.
      D0: 7
      D1: 6
      D2: 5
      D3: 4
      D4: 3
      D5: 2
      D6: 1
      D7: 39
      D8: 38
      D9: 37
      D10: 36
      D11: 35

      # Clock signal inputs. These are clocks for video purposes: the color clock pin
      # (PHICLR) is clocked at 14.31818 MHz and the dot clock pin (PHIDOT) at 8.18 MHz. The
      # latter is divided by 8 to create the system clock that is made available on output
      # pin PHI0.
      PHICLR: 21
      PHIDOT: 22

      # Light pen pin. A transition to low on this pin indicates that a light pen is
      # connected and has activated.
      LP: 9

      # Chip select. A low signal on this indicates that the VIC should be available for
      # reading and writing of its registers. This pin has no effect during the PHI0 low
      # cycle (when the VIC has control of the busses).
      CS: 10

      # Read/write control. A high on this indicates that the registers are to be read,
      # while a low indicates they are to be written. Has no effect during the PHI0 low
      # cycle.
      R_W: 11

    output:
      # Video outputs. These are analog signals, one for sync/luminance and one for color.
      S_LUM: 15
      COLOR: 14

      # DRAM control pins. These control the multiplexing of address bus lines into rows
      # (Row Address Strobe) and columns (Column Address Strobe).
      RAS: 18
      CAS: 19

      # Clock output. This is where the divided-by-8 dot clock is made available to the rest
      # of the system.
      PHI0: 17

      # The bus access pin. This is normally high but can be set low when the VIC needs
      # exclusive access to the address and data bus to perform tasks that take more time
      # than it normally has with the PHI0 low cycle. After three clock cycles, the AEC pin
      # can then be held low to take bus control.
      BA: 12

      # Address Enable Control. When this is high, thye CPU has control of the address and
      # data busses. When it is low, the VIC does instead. It normally follows the φ0 output
      # except when using it along with BA.
      AEC: 16

      # Interrupt request. The VIC can request interrupts for four reasons: the end of a
      # raster line, a lightpen activation, a sprite-to-sprite collision, or a
      # sprite-to-background collision. When these events occur this pin will go low.
      IRQ: 8

    unconnected:
      # Power supply and ground pins. These are not emulated.
      VCC: 40
      VDD: 13
      GND: 20

  registers:
    MOB0X: 0   # Mob 0 X coordinate
    MOB0Y: 1   # Mob 0 Y coordinate
    MOB1X: 2   # Mob 1 X coordinate
    MOB1Y: 3   # Mob 1 Y coordinate
    MOB2X: 4   # Mob 2 X coordinate
    MOB2Y: 5   # Mob 2 Y coordinate
    MOB3X: 6   # Mob 3 X coordinate
    MOB3Y: 7   # Mob 3 Y coordinate
    MOB4X: 8   # Mob 4 X coordinate
    MOB4Y: 9   # Mob 4 Y coordinate
    MOB5X: 10  # Mob 5 X coordinate
    MOB5Y: 11  # Mob 5 Y coordinate
    MOB6X: 12  # Mob 6 X coordinate
    MOB6Y: 13  # Mob 6 Y coordinate
    MOB7X: 14  # Mob 7 X coordinate
    MOB7Y: 15  # Mob 7 Y coordinate
    MOBMSX: 16 # Mob X coordinate MSBs
    CTRL1: 17  # Control register 1
    RASTER: 18 # Raster counter
    LPX: 19    # Light pen X coordinate
    LPY: 20    # Light pen Y coordinate
    MOBEN: 21  # Mob enable
    CTRL2: 22  # Control register 2
    MOBYEX: 23 # Mob Y expansion
    MEMPTR: 24 # Memory pointers
    IR: 25     # Interrupt register
    IE: 26     # Interrupt enable
    MOBDP: 27  # Mob data priority
    MOBMC: 28  # Mob multicolor
    MOBXEX: 29 # Mob X expansion
    MMCOL: 30  # Mob-to-mob collision
    MDCOL: 31  # Mob-to-data collision
    BORDER: 32 # Border color
    BG0: 33    # Background color 0
    BG1: 34    # Background color 1
    BG2: 35    # Background color 2
    BG3: 36    # Background color 3
    MOBMC0: 37 # Mob multicolor 0
    MOBMC1: 38 # Mob multicolor 1
    MOB0C: 39  # Mob 0 color
    MOB1C: 40  # Mob 1 color
    MOB2C: 41  # Mob 2 color
    MOB3C: 42  # Mob 3 color
    MOB4C: 43  # Mob 4 color
    MOB5C: 44  # Mob 5 color
    MOB6C: 45  # Mob 6 color
    MOB7C: 46  # Mob 7 color
    # 17 unused registers, named UNUSED1 to UNUSED17, are not actually created. Their
    # contents are always read as 0xff, and writes to them have no effect. This is handled
    # by the read_register/write_register procs without needing actual registers.

  debug_properties:
    counter: RasterCounter

  debug_procs:
    proc counter*(chip: Ic6567): RasterCounter =
      ## Returns the chip's raster counter. **This proc, along with the counter property,
      ## are only available in non-release mode.**
      chip.counter

  init:
    set(pins[RAS])
    set(pins[CAS])
    set(pins[BA])
    clear(pins[AEC])
    clear(pins[PHI0])

    var phi = 0.0
    var divider = 0

    let counter = new_raster_counter(pins, registers)
    let memory = new_memory_controller(counter, pins, registers)

    when not defined(release): result.counter = counter

    update(counter)

    let addr_reg_pins = map(to_seq(24..29), pin => pins[pin])
    let data_reg_pins = map(to_seq(0..7), pin => pins[&"D{pin}"])  # defines var `clock`

    # Some registers have unused bits. These bits are not connected (i.e., are not written
    # on writes) and return 1 on reads. This array has a 1 for each unused bit; these masks
    # are bitwise ORed with the register value on read, and the stored register value on
    # write is the provided value bitwise ORed with the same mask.
    #
    # The seventeen unused registers operate this way on all bits, but that behavior is hard
    # coded into read_register and write_register.
    let register_masks = map(to_seq(0..46), proc (i: int): uint8 =
      if i == CTRL2: result = 0b11000000
      elif i == MEMPTR: result = 0b00000001
      elif i == IR: result = 0b01110000
      elif i == IE or i >= BORDER: result = 0b11110000
      else: result = 0b00000000)

    proc read_register(index: int): uint8 =
      # Reads a value from a register, accounting for unused bits. This function will also
      # handle things that happen aside from pure reading, like the sprite collision
      # registers resetting on each read.

      # Unusued registers return all 1's.
      if index >= UNUSED1: result = 0xff
      else:
        result = registers[index] or register_masks[index]
        # Sprite collision data is reset each time it's read.
        if index == MMCOL or index == MDCOL: registers[index] = 0

    proc write_register(index: int, value: uint8) =
      # Reading any of the raster bits (the RASTER register and/or the RST8 bit of the CTRL1
      # register) returns the actual raster line number at the time. This is not changeable
      # by writing to these bits. Instead, if any raster bit is written, the value will be
      # stored internally and used to determine upon which line number a raster interrupt
      # should be generated.
      if index == RASTER:
        # RASTER isn't written to at all.
        set_raster_latch_low8(counter, value)
      elif index == CTRL1:
        # CTRL1's RST8 bit isn't writable, but the rest are.
        set_raster_latch_msb(counter, bit_value(value, RST8))
        registers[CTRL1] = (registers[CTRL1] and 0x80) or (value and 0x7f)
      elif index < UNUSED1 and index != MMCOL and index != MDCOL:
        registers[index] = value or register_masks[index]

      # Reset the IRQ pin if the IR register is zeroed
      if index == IR and (value and 0b10001111) == 0: tri(pins[IRQ])

    proc enable_listener(pin: Pin) =
      if highp(pin):
        mode_to_pins(Output, data_reg_pins)
        tri_pins(data_reg_pins)
      elif lowp(pin):
        let index = pins_to_value(addr_reg_pins)
        if highp(pins[R_W]):
          value_to_pins(read_register(int(index)), data_reg_pins)
        elif lowp(pins[R_W]):
          mode_to_pins(Input, data_reg_pins)
          write_register(int(index), uint8(pins_to_value(data_reg_pins)))

    add_listener(pins[CS], enable_listener)

    proc clock_listener(pin: Pin) =
      divider += 1
      if divider >= PHIDOT_FREQ:
        divider = 0
        phi = 1.0 - phi
        # Reset RAS and CAS before lowering them for this cycle
        set(pins[RAS])
        set(pins[CAS])

        #  -- Do PHI0 things here --
        update(counter)
        pre_read(memory)

        set_level(pins[PHI0], phi)

        let (access, address) = generate_address(memory)

        # -- Do RAS things here --
        low_to_pins(memory, address)
        clear(pins[RAS])

        # -- Do CAS things here --
        high_to_pins(memory, address)
        clear(pins[CAS])

        discard read(memory, access)

    add_listener(pins[PHIDOT], clock_listener)
