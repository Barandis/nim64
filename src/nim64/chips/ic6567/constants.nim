# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https:#opensource.org/licenses/MIT

# Pin names and numbers
const
  D6*       = 1   ## The pin assignment for data pin 6.
  D5*       = 2   ## The pin assignment for data pin 5.
  D4*       = 3   ## The pin assignment for data pin 4.
  D3*       = 4   ## The pin assignment for data pin 3.
  D2*       = 5   ## The pin assignment for data pin 2.
  D1*       = 6   ## The pin assignment for data pin 1.
  D0*       = 7   ## The pin assignment for data pin 0.
  IRQ*      = 8   ## The pin assignment for the interrupt request pin.
  LP*       = 9   ## The pin assignment for the light pen input pin.
  CS*       = 10  ## The pin assignment for the chip select pin.
  R_W*      = 11  ## The pin assignment for the read/write control pin.
  BA*       = 12  ## The pin assignment for the bus access pin.
  VDD*      = 13  ## The pin assignment for the +12V power supply pin.
  COLOR*    = 14  ## The pin assignment for the video color output pin.
  S_LUM*    = 15  ## The pin assignment for the video sync/luminance output pin.
  AEC*      = 16  ## The pin assignment for the address enable control pin.
  PHI0*     = 17  ## The pin assignment for the system clock output pin.
  RAS*      = 18  ## The pin assignment for the row address strobe pin.
  CAS*      = 19  ## The pin assignment for the column address strobe pin.
  GND*      = 20  ## The pin assignment for the ground pin.
  PHICLR*   = 21  ## The pin assignment for the color clock input pin.
  PHIDOT*   = 22  ## The pin assignment for the dot clock input pin.
  A11*      = 23  ## The pin assignment for address pin 11.
  A0_A8*    = 24  ## The pin assignment for address pin 0/8.
  A1_A9*    = 25  ## The pin assignment for address pin 1/9.
  A2_A10*   = 26  ## The pin assignment for address pin 2/10.
  A3_A11*   = 27  ## The pin assignment for address pin 3/11.
  A4_A12*   = 28  ## The pin assignment for address pin 4/12.
  A5_A13*   = 29  ## The pin assignment for address pin 5/13.
  A6*       = 30  ## The pin assignment for address pin 6.
  A7*       = 31  ## The pin assignment for address pin 7.
  A8*       = 32  ## The pin assignment for address pin 8.
  A9*       = 33  ## The pin assignment for address pin 9.
  A10*      = 34  ## The pin assignment for address pin 10.
  D11*      = 35  ## The pin assignment for data pin 11.
  D10*      = 36  ## The pin assignment for data pin 10.
  D9*       = 37  ## The pin assignment for data pin 9.
  D8*       = 38  ## The pin assignment for data pin 8.
  D7*       = 39  ## The pin assignment for data pin 7.
  VCC*      = 40  ## The pin assignment for the +5V power supply pin.

# Register names
const
  MOB0X*    = 0   ## Mob 0 X coordinate register.
  MOB0Y*    = 1   ## Mob 0 Y coordinate register.
  MOB1X*    = 2   ## Mob 1 X coordinate register.
  MOB1Y*    = 3   ## Mob 1 Y coordinate register.
  MOB2X*    = 4   ## Mob 2 X coordinate register.
  MOB2Y*    = 5   ## Mob 2 Y coordinate register.
  MOB3X*    = 6   ## Mob 3 X coordinate register.
  MOB3Y*    = 7   ## Mob 3 Y coordinate register.
  MOB4X*    = 8   ## Mob 4 X coordinate register.
  MOB4Y*    = 9   ## Mob 4 Y coordinate register.
  MOB5X*    = 10  ## Mob 5 X coordinate register.
  MOB5Y*    = 11  ## Mob 5 Y coordinate register.
  MOB6X*    = 12  ## Mob 6 X coordinate register.
  MOB6Y*    = 13  ## Mob 6 Y coordinate register.
  MOB7X*    = 14  ## Mob 7 X coordinate register.
  MOB7Y*    = 15  ## Mob 7 Y coordinate register.
  MOBMSX*   = 16  ## Mob X coordinate MSBs register.
  CTRL1*    = 17  ## Control register 1.
  RASTER*   = 18  ## Raster counter register.
  LPX*      = 19  ## Light pen X coordinate register.
  LPY*      = 20  ## Light pen Y coordinate register.
  MOBEN*    = 21  ## Mob enable register.
  CTRL2*    = 22  ## Control register 2.
  MOBYEX*   = 23  ## Mob Y expansion register.
  MEMPTR*   = 24  ## Memory pointers register.
  IR*       = 25  ## Interrupt register.
  IE*       = 26  ## Interrupt enable register.
  SPRDP*    = 27  ## Mob data priority register.
  MOBMC*    = 28  ## Mob multicolor register.
  MOBXEX*   = 29  ## Mob X expansion register.
  MMCOL*    = 30  ## Mob-to-mob collision register.
  MDCOL*    = 31  ## Mob-to-data collision register.
  BORDER*   = 32  ## Border color register.
  BG0*      = 33  ## Background color 0 register.
  BG1*      = 34  ## Background color 1 register.
  BG2*      = 35  ## Background color 2 register.
  BG3*      = 36  ## Background color 3 register.
  MOBMC0*   = 37  ## Mob multicolor 0 register.
  MOBMC1*   = 38  ## Mob multicolor 1 register.
  MOB0C*    = 39  ## Mob 0 color register.
  MOB1C*    = 40  ## Mob 1 color register.
  MOB2C*    = 41  ## Mob 2 color register.
  MOB3C*    = 42  ## Mob 3 color register.
  MOB4C*    = 43  ## Mob 4 color register.
  MOB5C*    = 44  ## Mob 5 color register.
  MOB6C*    = 45  ## Mob 6 color register.
  MOB7C*    = 46  ## Mob 7 color register.
  UNUSED1*  = 47  ## Unused register 1.
  UNUSED2*  = 48  ## Unused register 2.
  UNUSED3*  = 49  ## Unused register 3.
  UNUSED4*  = 50  ## Unused register 4.
  UNUSED5*  = 51  ## Unused register 5.
  UNUSED6*  = 52  ## Unused register 6.
  UNUSED7*  = 53  ## Unused register 7.
  UNUSED8*  = 54  ## Unused register 8.
  UNUSED9*  = 55  ## Unused register 9.
  UNUSED10* = 56  ## Unused register 10.
  UNUSED11* = 57  ## Unused register 11.
  UNUSED12* = 58  ## Unused register 12.
  UNUSED13* = 59  ## Unused register 13.
  UNUSED14* = 60  ## Unused register 14.
  UNUSED15* = 61  ## Unused register 15.
  UNUSED16* = 62  ## Unused register 16.
  UNUSED17* = 63  ## Unused register 17.

# Control register 1 bits
const
  Y0*       = 0u  ## Y scroll bit 0.
  Y1*       = 1u  ## Y scroll bit 1.
  Y2*       = 2u  ## Y scroll bit 2.
  RSEL*     = 3u  ## Row select bit (1 = 25 rows, 0 = 24 rows).
  DEN*      = 4u  ## Display enable bit.
  BMM*      = 5u  ## Bitmap mode bit.
  ECM*      = 6u  ## Extended color mode bit.
  RST8*     = 7u  ## Bit 8 of the raster counter.

# Control register 2 bits
const
  X0*       = 0u  ## X scroll bit 0.
  X1*       = 1u  ## X scroll bit 1.
  X2*       = 2u  ## X scroll bit 2.
  CSEL*     = 3u  ## Column select bit (1 = 40 columns, 0 = 38 columns).
  MCM*      = 4u  ## Multicolor mode bit.
  RES*      = 5u  ## Non-functional bit in the 6567 (stops the VIC in the 6566).

# Memory pointer bits
const
  CB11*     = 1u  ## Character base address bit 11.
  CB12*     = 2u  ## Character base address bit 12.
  CB13*     = 3u  ## Character base address bit 13.
  VM10*     = 4u  ## Video matrix address bit 10.
  VM11*     = 5u  ## Video matrix address bit 11.
  VM12*     = 6u  ## Video matrix address bit 12.
  VM13*     = 7u  ## Video matrix address bit 13.

# Interrupt register bits
const
  IRST*     = 0u  ## Raster interrupt latch bit.
  IMDC*     = 1u  ## Mob-data collision interrupt latch bit.
  IMMC*     = 2u  ## Mob-mob collision interrupt latch bit.
  ILP*      = 3u  ## Light pen interrupt latch bit.
  IIRQ*     = 7u  ## Interrupt requested latch bit.

# Interrupt enable bits
const
  ERST*     = 0u  ## Enable raster interrupt bit.
  EMDC*     = 1u  ## Enable mob-data collision interrupt bit.
  EMMC*     = 2u  ## Enable mob-mob collision interrupt bit.
  ELP*      = 3u  ## Enable light pen interrupt bit.

# Raster-related constants
const
  # The number of clock cycles in a raster line. This is different between different VIC
  # versions and even revisions; the 6569 (the PAL equivalent) has 63 cycles per line, while
  # the 6567R56A has 64 cycles per line. The particular one emulated here is the 6567R8,
  # which uses 65 cycles per line.
  CYCLES_PER_LINE* = 65u  ## Number of clock cycles in a single raster line.

  # The number of raster lines in a single frame. This again is different between different
  # versions of the VIC; the 6567R56A has 262 while the 6569 has 312.
  RASTER_LINES_PER_FRAME* = 263u  ## Number of raster lines in a single frame.

  # The minimum and maximum raster lines that produce visible graphic output. This does not
  # include the border. Bad line conditions can only happen on a line in the visible range.
  RASTER_MIN_VISIBLE* = 48u  ## Index of the first visible raster line.
  RASTER_MAX_VISIBLE* = 247u  ## Index of the last visible raster line.

  # The cycle on a raster line in which each mob has its pointer read.
  MOB_PTR_CYCLES* =
    [60u, 62u, 64u, 1u, 3u, 5u, 7u, 9u]  ## Cycle number when each mob reads its pointer.

  # The cycles on a raster line where a mob being enabled means BA needs to be low for that
  # cycle. It's precalculated because this is checked very cycle.
  MOB_BA_CYCLES* = [
    [57u, 58u, 59u, 60u, 61u],
    [59u, 60u, 61u, 62u, 63u],
    [61u, 62u, 63u, 64u, 65u],
    [63u, 64u, 65u, 1u, 2u],
    [65u, 1u, 2u, 3u, 4u],
    [2u, 3u, 4u, 5u, 6u],
    [4u, 5u, 6u, 7u, 8u],
    [6u, 7u, 8u, 9u, 10u],
  ]
