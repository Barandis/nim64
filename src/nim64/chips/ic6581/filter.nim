# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https:#opensource.org/licenses/MIT

import math
import ../../utils

include ./constants

# Sample cutoff frequencies for different values of FCHI and FCLO.
#
# Each element is a tuple consisting of the total register value (combining FCHI and FCLO)
# and the actual cutoff frequency in hertz. Each of these comes from measurements of actual
# Commodore 64's made by the folks who created reSID. (I don't have actual hardware to make
# these measurements.)
#
# These are used as control points in a spline interpolation function to come up with the
# cutoff frequency for *any* CUTHI and CUTLO register values. There are repeats for the end
# points so that there are sufficient control points for interpolations at very low and very
# high register values. There are also repeats around a discontinuity in the middle of the
# register range (between 1023 and 1024) for the same reason.
const CutoffSamples = [
  #[
  Register  Cutoff
  Value     Freq (Hz)     CUTHI  CUTLO   Notes
  ]#
  (0,        220),      # $00    $00    (repeated end point)
  (0,        220),      # $00    $00
  (128,      230),      # $10    $00
  (256,      250),      # $20    $00
  (384,      300),      # $30    $00
  (512,      420),      # $40    $00
  (640,      780),      # $50    $00
  (768,      1600),     # $60    $00
  (832,      2300),     # $68    $00
  (896,      3200),     # $70    $00
  (960,      4300),     # $78    $00
  (992,      5000),     # $7C    $00
  (1008,     5400),     # $7E    $00
  (1016,     5700),     # $7F    $00
  (1023,     6000),     # $7F    $07
  (1023,     6000),     # $7F    $07    (discontinuity)
  (1024,     4600),     # $80    $00
  (1024,     4600),     # $80    $00
  (1032,     4800),     # $81    $00
  (1056,     5300),     # $84    $00
  (1088,     6000),     # $88    $00
  (1120,     6600),     # $8C    $00
  (1152,     7200),     # $90    $00
  (1280,     9500),     # $A0    $00
  (1408,     12000),    # $B0    $00
  (1536,     14500),    # $C0    $00
  (1664,     16000),    # $D0    $00
  (1792,     17100),    # $E0    $00
  (1920,     17700),    # $F0    $00
  (2047,     18000),    # $FF    $07
  (2047,     18000),    # $FF    $07    (repeated end point)
]

# The mixer after the filter in the 6581 has a small DC offset. This offset was measured on
# a physical 6581 to be -0.06V, the difference between the output pin voltage with a zero
# sound output at zero volume versus at full volume. This is -1/18 the dynamic range of one
# voice.
const Offset = (-0xfff * (0xff div 18)) shr 7

type Filter* = ref object
  ## An emulation of the analog filter circuit in the 6581 SID. We know quite a lot about
  ## the filter and its parameters, and I learned a lot about it from two sources: the
  ## libsidplay_ library and in particular the forum discussion here_ that analyzes the
  ## circuitry itself; and the reSID_ library. The latter in particular I used for
  ## measurements that I cannot make because I don't have a Commodore 64; that includes the
  ## samples of cutoff frequencies that are used to derive all of the cutoff frequencies,
  ## and the measures of DC offsets that affect the output.
  ##
  ## The 6581 filter is a highly configurable two-integrator-loop biquad filter, as has been
  ## confirmed by Bob Yannes, the 6581's designer. The integrators are not built on op-amps
  ## as normal but instead take advantage of the characteristics of an NMOS inverter if it's
  ## biased just right. This is presumably because of chip-space concerns and doesn't make
  ## any real difference for the emulation.
  ##
  ## This filter consists of a pair of integrators. The output of the first feeds the input
  ## of the second, while the outputs of both feed a summer which produces the input to
  ## the first. The high-pass output of such a filter is the summer output, the band-pass
  ## output is the output of the first integrator, and the low-pass output is the output of
  ## the second integrator.
  ##
  ## Here's an attempt at the circuitry in ASCII, which is ugly at best.
  ## ```
  ##           +-----------R---------------------------+
  ##           |                                       |
  ##           |       +---Rq--+                       |
  ##           |       |       |                       |
  ##           +---R---+---<|--+---R---+               |
  ##           |                       |               |
  ##           |               +---C---+       +---C---+
  ##           |               |       |       |       |
  ##           +---R---+       +---R---+       +---R---+
  ##           |       |       |       |       |       |
  ## IN ---R---+--|>---+--Rc---+--|>---+--Rc---+--|>---+
  ##                   |               |               |
  ##                   HP              BP              LP
  ##
  ## IN - input
  ## HP - high-pass output
  ## BP - band-pass output
  ## LP - low-pass output
  ## |> - op-amp
  ## C  - capacitor
  ## R  - resistor
  ## Rc - variable resistor controlling cutoff frequency (set by CUTHI and CUTLO)
  ## Rq - variable resistor controlling resonance (set by high 4 bits of RESON)
  ## ```
  ## It's actually quite trivial to produce such a filter in code. The filtering itself
  ## takes all of five lines of code. The rest of the code in this module is dedicated
  ## largely either to deriving all of the possible cutoff frequencies by interpolating from
  ## the sample values from reSID and to register handling.
  ##
  ## .. _libsidplay: https://sourceforge.net/p/sidplay-residfp/wiki/SID%20internals/
  ## .. _here: http://forum.6502.org/viewtopic.php?f=8&t=4150
  ## .. _reSID: https://github.com/simonowen/resid

  cut: uint ## The value of the frequency cutoff registers, an 11-bit number.
  res: uint ## The filter resonance from the register, a 4-bit number.
  volume: uint ## The master volume from the register, a 4-bit number.
  filtlp: bool ## Whether or not the low-pass filter is enabled.
  filtbp: bool ## Whether or not the band-pass filter is enabled.
  filthp: bool ## Whether or not the high-pass filter is enabled.
  filtv1: bool ## Whether or not Voice 1 is being filtered.
  filtv2: bool ## Whether or not Voice 2 is being filtered.
  filtv3: bool ## Whether or not Voice 3 is being filtered.
  filtex: bool ## Whether or not the external input is being filtered.
  dscnv3: bool ## Set to `true` if voice 3 is producing no output. This will only happen if
               ## `filtv3` is `false`. It allows Voice 3 to be used purely for
               ## sync/modulation without adding anything to the output.
  lp: int ## The value of the low-pass component of the filter on the current clock cycle.
          ## This is the output of the second integrator in the filter circuit.
  bp: int ## The value of the band-pass component of the filter on the current clock cycle.
          ## This is the output of the first integrator in the filter circuit.
  hp: int ## The value of the high-pass component of the filter on the current clock cycle.
          ## This is the output of the summer in the filter circuit.
  nf: int ## The value of the unfiltered output on the current clock cycle.
  fc: int ## The filter cutoff frequency, in Hertz.
  q: int ## The filter resonance. This is actually stored as 1000 / Q, since that's what's
         ## used in calculations.

# ----------------------------------------------------------------------------------------
# INTERPOLATION
#
# The purpose of the next three functions are to interpolate the cutoff frequency of any
# CUTHI/CUTLO register setting based on the known values in the table above.
#
# The method used here is to use the table values as points (with the register value as x
# and the cutoff frequency as y) and then to calculate piecewise cubic polynomials using
# these points as control points. This will give us an interpolated value of y for *any*
# value of x, not just the ones in the table.
#
# Each curve segment is specified by four control points. (These will be referred to as p0,
# p1, p2, and p3, which are made up of x and y values (x0, y0), (x1, y1), (x2, y2), and (x3,
# y3) respectively.) p0 and p3 are used to determine the "shape" of the curve segment, but
# only the values between p1 and p2 (inclusive) will be calculated for each segment.
#
# The first step is to calculate approximations of the derivatives of the curve segment at
# p1 and p2; these are simply the differences between the two control points surrounding
# them:
#
#     f'(x1) = k1 = (y2 - y0) / (x2 - x0)
#     f'(x2) = k2 = (y3 - y1) / (x3 - x1)
#
# Then, with two points (xi, yi) and (xj, yj), along with their derivatives ki and kj, the
# following set of linear equations can be derived.
#
#     | 1  xi   xi^2   xi^3 | | d |   | yi |
#     |     1  2xi    3xi^2 | | c | = | ki |
#     | 1  xj   xj^2   xj^3 | | b |   | yj |
#     |     1  2xj    3xj^2 | | a |   | kj |
#
# Solving with Gaussian elimination, we get the coefficients for the cubic polynomial
# representing that curve segment. For f(x) = ax^3 + bx^2 + cx + d, and taking dx = xj - xi
# and dy = yj - yi, the coefficients are
#
#     a = (ki + kj - 2 * dy / dx) / (dx * dx)
#     b = ((kj - ki) / dx - 3 * a * (xi + xj)) / 2
#     c = ki - (3 * a * xi + 2 * b) * xi
#     d = yi - ((xi * a + b) * xi + c) * xi
#
# With these coefficients now known, we can solve for y for each x between x1 and x2 with
# any number of methods. We've used forward differencing here just because it's kinda neat.
# This finds the next point by using first, second, and third derivatives to find the next
# point and then the next of each of those derivatives.
#
#     y = ((a * x1 + b) * x1 + c) * x1 + d
#     dy = (3 * a * (x1 + r) + 2 * b) * x1 * r + ((a * r + b) * r + c) * r
#     d2y = (6 * a * (x1 + r) + 2 * b) * r * r
#     d3y = 6 * a * r * r * r
#
# The next y is calculated by adding dy to the previous y, then the next dy is calculated by
# adding d2y to the previous dy, and so on. `r` here is the resolution, or how far there is
# to be between each x. Since we want every x calculated, we use 1 for this value.

proc coefficients(x1, y1, x2, y2: int; k1, k2: float): (float, float, float, float) =
  let dx = float(x2 - x1)
  let dy = float(y2 - y1)
  let xf = float(x1)
  let yf = float(y1)

  let a = (k1 + k2 - (2 * dy) / dx) / (dx * dx)
  let b = ((k2 - k1) / dx - 3 * float(x1 + x2) * a) / 2
  let c = k1 - (3 * xf * a + 2 * b) * xf
  let d = yf - ((xf * a + b) * xf + c) * xf

  (a, b, c, d)

# Calculate each point by summing derivatives. The `r` term from the final set of
# calculations above is always going to be 1 in this application, so it is pre-calculated.
#
# This proc returns nothing. Instead it manipulates the items in `values`.
proc forward_difference(x1, y1, x2, y2: int; k1, k2: float; values: var seq[int]) =
  let (a, b, c, d) = coefficients(x1, y1, x2, y2, k1, k2)
  let xf = float(x1)

  var y = ((a * xf + b) * xf + c) * xf + d
  var dy = (3 * a * (xf + 1) + 2 * b) * xf + (a + b + c)
  var d2y = (6 * a * (xf + 1) + 2 * b)
  var d3y = 6 * a

  for x in x1..x2:
    values[x] = if y < 0: 0 else: int(round(y))
    y += dy
    dy += d2y
    d2y += d3y

proc interpolate: seq[int] =
  new_seq(result, 2048)
  var k1: float
  var k2: float

  for i in 0..(len(CutoffSamples) - 4):
    let (x0, y0) = CutoffSamples[i]
    let (x1, y1) = CutoffSamples[i + 1]
    let (x2, y2) = CutoffSamples[i + 2]
    let (x3, y3) = CutoffSamples[i + 3]

    # Skip if x1 and x2 are equal. This means there's a single point.
    if x1 != x2:
      if x0 == x1 and x2 == x3:
        # Both pairs repeated; straight line.
        k1 = (y2 - y1) / (x2 - x1)
        k2 = k1
      elif x0 == x1:
        # Only x0 and x1 are equal; use f''(x1) = 0.
        k2 = (y3 - y1) / (x3 - x1)
        k1 = ((3 * (y2 - y1)) / (x2 - x1) - k2) / 2
      elif x2 == x3:
        # Only x2 and x3 are equal; use f''(x2) = 0.
        k1 = (y2 - y0) / (x2 - x0)
        k2 = ((3 * (y2 - y1)) / (x2 - x1) - k1) / 2
      else:
        # Nothing equal; generic curve.
        k1 = (y2 - y0) / (x2 - x0)
        k2 = (y3 - y1) / (x3 - x1)

      forward_difference(x1, y1, x2, y2, k1, k2, result)

let CutoffFreqs = interpolate()

# ----------------------------------------------------------------------------------------
# END INTERPOLATION

proc calcluate_fc(filter: Filter) =
  ## Calculates the cutoff frequency based on the value of the `cut` field. This number
  ## allows for a max frequency of 16kHz and also multiples the value by a constant that
  ## will allow division by 1,000,000 (which happens in filter calculations) to instead just
  ## be a right shift of 20 bits.
  filter.fc = int(round(2 * PI * float(min(CutoffFreqs[filter.cut], 16000)) * 1.048576))

proc calculate_q(filter: Filter) =
  ## Calculates 1000 / Q, the resonance value. This value is multiplied by a constant which
  ## turns division by 1000 (which happens in filter calculations) to be done by right
  ## shifting 10 bits.
  filter.q = int(round(1024 / (0.707 + float(filter.res) / 15)))

proc cutlo*(filter: Filter, value: uint) =
  # Sets the lower 3 bits of the filter's cutoff frequency register value.
  filter.cut = (filter.cut and 0x7f8) or (value and 0x007)
  calcluate_fc(filter)

proc cuthi*(filter: Filter, value: uint) =
  # sets the upper 8 bits of the filter's cutoff frequency register value.
  filter.cut = ((value shl 3) and 0x7f8) or (filter.cut and 0x007)
  calcluate_fc(filter)

proc reson*(filter: Filter, value: uint) =
  # Sets the value of the RESON register, which controls the filter's resonance setting and
  # which voices are filtered.
  filter.res = hi4(value)
  calculate_q(filter)

  filter.filtv1 = bit_set(value, FILTV1)
  filter.filtv2 = bit_set(value, FILTV2)
  filter.filtv3 = bit_set(value, FILTV3)
  filter.filtex = bit_set(value, FILTEXT)

proc sigvol*(filter: Filter, value: uint) =
  # Sets the value of the SIGVOL register, which controls the mixer's master volume and
  # which filter modes are enabled.
  filter.volume = lo4(value)

  filter.filtlp = bit_set(value, FILTLP)
  filter.filtbp = bit_set(value, FILTBP)
  filter.filthp = bit_set(value, FILTHP)
  filter.dscnv3 = bit_set(value, DSCNV3)

proc reset*(filter: Filter) =
  ## Resets the filter to its starting state. This is 0 in the cutoff and resonance
  ## registers, no filters enabled, no voices being filtered, and zero volume.
  filter.cut = 0
  filter.res = 0
  filter.volume = 0

  filter.filtlp = false
  filter.filtbp = false
  filter.filthp = false

  filter.filtv1 = false
  filter.filtv2 = false
  filter.filtv3 = false
  filter.filtex = false

  filter.lp = 0
  filter.bp = 0
  filter.hp = 0
  filter.nf = 0

  calcluate_fc(filter)
  calculate_q(filter)

proc clock*(filter: Filter; voice1, voice2, voice3, external: int) =
  ## Runs on each clock cycle. Unlike most `clock` procs, this takes the current values
  ## for each of the voices and for the external input. It then calculates the output
  ## values for each of the filter channels and for the non-filtered output.
  let v1 = voice1 shr 7
  let v2 = voice2 shr 7
  let v3 = if filter.dscnv3 and not filter.filtv3: 0 else: voice3 shr 7
  let ext = external shr 7

  var level = 0
  filter.nf = 0

  # The mixer is simply additive; voice values get added to either the filtered or the
  # unfiltered path, depending on register settings.
  if filter.filtv1: level += v1 else: filter.nf += v1
  if filter.filtv2: level += v2 else: filter.nf += v2
  if filter.filtv3: level += v3 else: filter.nf += v3
  if filter.filtex: level += ext else: filter.nf += ext

  # And here it is...the actual calculations that produce the filtered output. The right
  # shifts take the place of much slower division. A shr 20 is the same as a division by
  # 1,048,576, and a shr 10 is the same as division by 1024. We get division by 1,000,000
  # and by 1000 by having already multiplied the `fc` and `q` values by 1.048576 and 1.024,
  # respectively.
  let dbp = (filter.fc * filter.hp) shr 20
  let dlp = (filter.fc * filter.bp) shr 20
  filter.bp -= dbp
  filter.lp -= dlp
  filter.hp = ((filter.bp * filter.q) shr 10) - filter.lp - level

proc output*(filter: Filter): int =
  ## Returns the current output value of the filter mixer. This simply adds each filter
  ## channel together along with the DC offset, then multiplies that by the volume.
  var level = filter.nf

  if filter.filtlp: level += filter.lp
  if filter.filtbp: level += filter.bp
  if filter.filthp: level += filter.hp

  (level + Offset) * int(filter.volume)

proc new_filter*(): Filter =
  result = Filter(
    cut: 0,
    res: 0,
    volume: 0,
    filtlp: false,
    filtbp: false,
    filthp: false,
    filtv1: false,
    filtv2: false,
    filtv3: false,
    filtex: false,
    lp: 0,
    bp: 0,
    hp: 0,
    nf: 0,
  )
  calcluate_fc(result)
  calculate_q(result)
