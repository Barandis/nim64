# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://#opensource.org/licenses/MIT

# A single tone oscillator/waveform generator used in the 6581 SID.
#
# The oscillator consists of a phase accumulator followed by logic to turn the output of
# that oscillator into a waveform of a particular shape.
#
# A phase accumulator is simply a 23-bit value to which a certain number is added on every
# clock cycle (each time the `PHI2` pin transitions high). The accumulator is allowed to
# overflow and lose the most significant bit, which has the result of "resetting" it to
# near zero on a regular basis. This produces a sawtooth-shaped waveform.
#
# The number that is added to the PAO on each clock cycle is the value in the `FREHI` and
# `FRELO` registers. A higher number will cause the oscillator to overflow more frequently,
# producing a waveform of a higher frequency.
#
# This is known as a "phase accumulator" because the normal *next* step in waveform
# generation is to consult a lookup table with the values of sines for the accumulator
# value. Thus, the PA is actually determining the phase of the sine wave so produced. The
# 6581 does not produce sine waves because there was not enough room on the chip to add
# such a sine lookup table (the PA waveform itself is output as a sawtooth wave), but it is
# still referred to as a phase accumulator.
#
# The PA result is then fed into four waveform generators, one each for triangle, sawtooth,
# pulse, and noise waveforms. Which if these is enabled is controlled by the `VCREG`
# register. Multiple waveform generators can be enabled at once; while the documentation
# claims that this results in logically ANDing all of the waveforms, the reality is more
# difficult to model and has been done with static wavetables instead.

import options
import ../../utils


const ACC_MSB = 23 ## The position of the most significant bit of the accumulator. The SID
                   ## uses a 24-bit accumulator.

const LFSR_CLOCK = 19 ## The position of the accumulator bit used to provide the clock to
                      ## the shift register. When this bit changes state (`0` to `1` or `1`
                      ## to `0`), the shift register calculates its next generation.

const
  ## The positions of the shift register bits that are fed back to the beginning of the
  ## shift register on clock. If either the `RES` pin is low or the `TEST` bit of `VCREG` is
  ## set, then the inverse of the bit value at `LFSR_TAP_1` becomes the new value pushed
  ## into bit 0 of the shift register. Otherwise, these two bit values are xored, and that
  ## value is pushed to bit 0.
  LFSR_TAP_1 = 17
  LFSR_TAP_2 = 22

const
  ## The positions of the shift register bits that are used as output for the noise
  ## waveform. Eight bits are used and then shifted four bits to the left to create a 12-bit
  ## value with 0's in the lower four bits.
  LFSR_OUT_0 = 0
  LFSR_OUT_1 = 2
  LFSR_OUT_2 = 5
  LFSR_OUT_3 = 9
  LFSR_OUT_4 = 11
  LFSR_OUT_5 = 14
  LFSR_OUT_6 = 18
  LFSR_OUT_7 = 20

# Inclusions of wave tables for combination waveforms
include ./wavetable_ps
include ./wavetable_pt
include ./wavetable_st
include ./wavetable_pst

type Waveform* = ref object
  ## A single tone oscillator/waveform generator used in the 6581 SID.
  ##
  ## The oscillator consists of a phase accumulator followed by logic to turn the output of
  ## that oscillator into a waveform of a particular shape.
  ##
  ## A phase accumulator is simply a 23-bit value to which a certain number is added on
  ## every clock cycle (each time the `PHI2` pin transitions high). The accumulator is
  ## allowed to overflow and lose the most significant bit, which has the result of
  ## "resetting" it to near zero on a regular basis. This produces a sawtooth-shaped
  ## waveform.
  ##
  ## The number that is added to the PAO on each clock cycle is the value in the `FREHI` and
  ## `FRELO` registers. A higher number will cause the oscillator to overflow more
  ## frequently, producing a waveform of a higher frequency.
  ##
  ## This is known as a "phase accumulator" because the normal *next* step in waveform
  ## generation is to consult a lookup table with the values of sines for the accumulator
  ## value. Thus, the PA is actually determining the phase of the sine wave so produced. The
  ## 6581 does not produce sine waves because there was not enough room on the chip to add
  ## such a sine lookup table (the PA waveform itself is output as a sawtooth wave), but it
  ## is still referred to as a phase accumulator.
  ##
  ## The PA result is then fed into four waveform generators, one each for triangle,
  ## sawtooth, pulse, and noise waveforms. Which if these is enabled is controlled by the
  ## `VCREG` register. Multiple waveform generators can be enabled at once; when this is
  ## done, the output value at each clock cycle is the values of all enabled waveform
  ## generators, logically ANDed together.

  acc: uint ## The current value of the phase accumulator used to determine the oscillator
            ## output.
  lfsr: uint  ## The current value of the linear feedback shift register  used to produce
              ## pseudo-random noise. The LFSR is  constructed like this:
              ## ```
              ##       +---XOR------------------+
              ##       |    |                   |
              ## BIT:  2221111111111            |
              ##       21098765432109876543210<-+
              ##         | |   |  | |   |  | |
              ## OUTPUT: 7 6   5  4 3   2  1 0
              ## ```
              ## The eight output bits are the values on any given read of bits 0, 2, 5, 9,
              ## 11, 14, 18, and 20 of the shift register. On shift, each bit value is moved
              ## one to the left, and then the values of bits 17 and 22 are exclusive-ored
              ## and used for the new value of bit 0 (unless the `TEST` bit of `VCREG` is
              ## high, or the `RES` pin is low, in which case bit 0 will always take the
              ## value of `1`).
              ##
              ## A shift will occur each time the value of bit 19 of the accumulator
              ## transitions from `0` to `1`. Since that frequency is determined by the
              ## values of `FREHI` and `FRELO`, the "pitch" of the noise can be tuned just
              ## like the pitch of any of the other waveforms.
  prev_msb: bool ## Tracks the previous value of the most significant bit of the oscillator
                 ## to which this oscillator is synched. If sync is enabled, this oscillator
                 ## will be forcibly reset each time the synched oscillator's MSB changes.
  last_clock: bool ## Tracks the previous value of the 19th bit of the phase accumulator.
                   ## This bit is used as a clock by the LFSR. Each time this bit
                   ## transitions high, the LFSR shifts once.
  freq: uint ## The value of the SID's frequency registers. This is the number that is
             ## added to the accumulator on each clock cycle.
  pw: uint ## The value of the SID's pulse width registers. This is a 12-bit number that
           ## determines when a pulse waveform's value shifts from zero to max.
  test: bool ## The value of the `TEST` bit of the control register, as a boolean. If this
             ## is `true`, the accumulator value will always be `0`, `1`s will be shifted
             ## into the noise LFSR, and the pulse waveform output will be all `1`s.
  ring: bool ## The value of the `RING` bit of the control register, as a boolean. If this
             ## is `true`, the frequency of the synched oscillator will be used to
             ## ring-modulate this oscillator, as long as the triangle waveform is selected.
  sync: bool ## The value of the `SYNC` bit of the control register, as a boolean. If this
             ## is `true`, the accumulator will be reset to `0` each time the MSB of the
             ## synched oscillator's accumulator transitions from `0` to `1`.
  waveform: uint ## The top four bits of the control register, which determine the
                 ## waveform(s) produced. This is stored as a combined number (rather than
                 ## as a series of `bool`s) because it makes the output selection a bit
                 ## easier.
  resetting: bool ## Indicates whether the generator is in the process of resetting. This
                  ## corresponds to the time when the chip's `RES` pin is held low. The LFSR
                  ## acts differently during this time.
  sync_target: Option[Waveform] ## The generator to which this generator is synched. This is
                                ## predetermined on the 6581; generator 1 is synched to
                                ## generator 3, 2 to 1, and 3 to 2. This value will be set
                                ## by the Ic6581 code itself after all three generators are
                                ## created, so it should never be `none` during actual
                                ## operation.

proc accumulate(wv: Waveform) =
  ## Advances the accumulator by adding the word comprised of the values of `FREHI` and
  ## `FRELO`. This method handles the `TEST` bit (which sets the output of the oscillator to
  ## 0 as long as it is set) and the `SYNC` bit (which causes the synched oscillator to
  ## reset the accumulator when its MSB changes) of the `VCREG` control register. Any bits
  ## beyond the 24 that make up the accumulator are discarded, meaning that when the
  ## accumulator overflows, it returns to a value near zero.
  let curr_msb = if is_some(wv.sync_target):
    bit_set(get(wv.sync_target).acc, ACC_MSB)
  else:
    false
  let reset = wv.test or (wv.sync and curr_msb and not wv.prev_msb)
  wv.prev_msb = curr_msb

  wv.acc = if reset: 0u else: (wv.acc + wv.freq) and 0xffffff

proc shift(wv: Waveform) =
  ## Potentially advances the pseudo-random noise shift register one generation. This shift
  ## only occurs if bit 19 of the phase accumulator has transitioned high since the last
  ## time this method was called, meaning that bit 19 of the PA acts as the LFSR's clock.
  ##
  ## Bit 0 of a linear feedback shift register (LFSR) is determined by the shift register's
  ## previous state. In this case, the values of bit positions 17 and 22 are exclusive-ored
  ## to produce the value that is fed back into bit 0. This means that the value of the
  ## shift register at any given time is completely deterministic and not random at all, but
  ## it does a fine job of producing pseudo-random noise.
  let clock = bit_set(wv.acc, LFSR_CLOCK)
  if clock and not wv.last_clock:
    wv.lfsr = wv.lfsr shl 1
    # This is a little weird on the physical 6581 chip.
    #
    # The code here replicates the result by ORing three values, written in this order:
    #
    # 1. The XORed result of the values of the two taps (at bit positions 17 and 22)
    # 2. An internal signal that is effectively the inverse of the RES pin
    # 3. The value of the TEST bit of the VCREG register
    #
    # This ensures that the value being fed back into bit 0 of the shift register is always
    # a 1 if either RES is pulled low or TEST is set high. Otherwise, the value being fed
    # back is the xored values of the bits at the tap positions.
    #
    # An analysis of the silicon of a 6581 suggests that the second tap value is first ORed
    # with the inverse of RES and the value of TEST, and that result is then XORed with the
    # first tap value. This would not ensure that only 1's are injected if RES is held low
    # or TEST is set high, yet only 1's are injected. The mechanism that causes this to
    # happen on the chip is unknown.
    #
    # http:#forum.6502.org/viewtopic.php?f=8&t=4150&start=30 near the bottom
    wv.lfsr = wv.lfsr or uint(wv.resetting) or uint(wv.test) or
      uint(bit_set(wv.lfsr, LFSR_TAP_1) xor bit_set(wv.lfsr, LFSR_TAP_2))
    wv.lfsr = wv.lfsr and 0x7fffff
  wv.last_clock = clock


proc sawtooth(wv: Waveform): uint =
  ## The top 12 bits of the phase accumulator are directly used as the sawtooth waveform.
  (wv.acc shr 12) and 0xfff

proc triangle(wv: Waveform): uint =
  ## For the triangle waveform, the MSB is xored against the other 11 of the top 12 bits
  ## from the phase accumulator. Those 11 bits are then shifted one to the left. When the
  ## MSB is high, this results in a reversal of the upward slope of the waveform, resulting
  ## in a triangle. The shift means that the triangle retains the same frequency and
  ## amplitude of the sawtooth original, but the fact that it's 11 bits means that it has
  ## half the resolution.
  ##
  ## If the RING bit in `VCREG` is set, then the MSB of the synched oscillator is used to
  ## potentially invert the slope one more time. Having the frequencies of the two
  ## oscillators differ will produce complex waveforms. This is "ring modulation". Ring
  ## modulation only works on the triangle waveform, and only if the synched oscillator has
  ## a non-zero frequency set. No other attribute of the synched oscillator is used.
  let msb = bit_set(if wv.ring: wv.acc xor get(wv.sync_target).acc else: wv.acc, ACC_MSB)
  ((if msb: not wv.acc else: wv.acc) shr 11) and 0xfff

proc pulse(wv: Waveform): uint =
  ## A pulse waveform is generated by comparing the value of the top 12 bits of the
  ## oscillator with the 12 bits from `PWHI` (top 4 bits are unused) and `PWLO`. All output
  ## bits are then set to `1`s or `0`s based on that comparison.
  ##
  ## If the `TEST` bit of `VCREG` is set, the pulse waveform generator will output all 1's
  ## until `TEST` is cleared.
  if wv.test or ((wv.acc shr 12) and 0xfff) < wv.pw: 0xfff else: 0x000

proc noise(wv: Waveform): uint =
  ## Generates a pseudo-random noise waveform. This takes 8 particular bits from the LFSR
  ## and uses them as the top 8 of the 12 produced by the waveform generator (the bottom 4
  ## bits are zeros).
  uint(bit_set(wv.lfsr, LFSR_OUT_0)) shl 4 or
    uint(bit_set(wv.lfsr, LFSR_OUT_1)) shl 5 or
    uint(bit_set(wv.lfsr, LFSR_OUT_2)) shl 6 or
    uint(bit_set(wv.lfsr, LFSR_OUT_3)) shl 7 or
    uint(bit_set(wv.lfsr, LFSR_OUT_4)) shl 8 or
    uint(bit_set(wv.lfsr, LFSR_OUT_5)) shl 9 or
    uint(bit_set(wv.lfsr, LFSR_OUT_6)) shl 10 or
    uint(bit_set(wv.lfsr, LFSR_OUT_7)) shl 11

proc frelo*(wv: Waveform, value: uint) =
  ## Sets the low 8 bits of the frequency.
  wv.freq = (wv.freq and 0xff00) or (value and 0x00ff)

proc frehi*(wv: Waveform, value: uint) =
  ## Sets the high 8 bits of the frequency.
  wv.freq = (wv.freq and 0x00ff) or ((value shl 8) and 0xff00)

proc pwlo*(wv: Waveform, value: uint) =
  ## Sets the low 8 bits of the pulse width.
  wv.pw = (wv.pw and 0x0f00) or (value and 0x00ff)

proc pwhi*(wv: Waveform, value: uint) =
  ## Sets the high 4 bits of the pulse width.
  wv.pw = (wv.pw and 0x00ff) or ((value shl 8) and 0x0f00)

proc vcreg*(wv: Waveform, value: uint) =
  ## Sets the values of the test, ring, and sync bits, along with the waveform.
  wv.test = value.bit_set 3
  wv.ring = value.bit_set 2
  wv.sync = value.bit_set 1
  wv.waveform = (value shr 4) and 0x0f

proc reset*(wv: Waveform, value: bool = true) =
  ## Resets the generator. What happens depends on the `value` argument; if it's false,
  ## this indicates that the `RES` pin has gone low, which changes the behavior of some
  ## parts of the waveform generator but does not fully reset it. If it's true, then the
  ## special behavior stops and the chip resets to its default values.
  if value:
    wv.acc = 0
    wv.lfsr = 0x7ffff8
    wv.last_clock = false

    wv.freq = 0
    wv.pw = 0
    wv.test = false
    wv.ring = false
    wv.sync = false
    wv.waveform = 0

    wv.resetting = false
  else:
    wv.resetting = true

proc clock*(wv: Waveform) =
  ## Advances the waveform generator one clock cycle. This advances the internal accumulator
  ## one generation and potentially shifts the LFSR once.
  accumulate(wv)
  shift(wv)

proc sync*(wv: Waveform, target: Waveform) =
  ## Registers a waveform generator as the one to which this one is synched. This can't be
  ## done during construction because the generators sync recursively.
  wv.sync_target = some(target)

proc output*(wv: Waveform): uint =
  ## Generates the output of the waveform generator.
  ##
  ## A lot of documentation says that if more than one waveform is selected, the output is
  ## the bitwise AND of the selected waveforms. This real picture is much more complex; zero
  ## bits, for example, can bleed into adjacent one bits and flip them to zero. The
  ## mechanism by which this happens is not currently known.
  ##
  ## This isn't modeled directly as the details aren't known. Instead, for combined
  ## waveforms, samples of actual data from the `ENV3` register of a physical 6581 are used.
  ## These are 4096-entry tables, one for each of the possible output values from the single
  ## waveform generators. The result is an 8-bit number that is shifted into a 12-bit
  ## number, so the bottom four bits are lost and therefore this is not an exact
  ## reproduction. But it's all you can get from the `ENV3` register.
  ##
  ## Noise is handled differently. When noise is combined with any other waveform, the
  ## result (after a short time) is always values of 0. It is conjectured that this is
  ## because combining noise with another waveform causes the shift register to fill with
  ## zeros, meaning the noise waveform itself will be all zeroes. In the real 6581, this
  ## actually necessitates a chip reset in order for the shift register to be able to have
  ## any non-zero values from then on.
  ##
  ## There is no model known for this behavior, so this method just returns `0.` The
  ## original 6581 documentation warned against combining noise with any other waveform, and
  ## that warning is repeated here.
  case wv.waveform
  of 1: triangle(wv)
  of 2: sawtooth(wv)
  of 3: (uint(wavetable_st[sawtooth(wv)])) shl 4
  of 4: pulse(wv)
  of 5: ((uint(wavetable_pt[triangle(wv)])) shl 4) and pulse(wv)
  of 6: ((uint(wavetable_ps[sawtooth(wv)])) shl 4) and pulse(wv)
  of 7: ((uint(wavetable_pst[sawtooth(wv)])) shl 4) and pulse(wv)
  of 8: noise(wv)
  else: 0

proc new_waveform*: Waveform =
  ## Creates a new waveform generator with all internal values set to what they would be
  ## after a reset.
  Waveform(
    acc: 0,
    lfsr: 0x7ffff8,
    last_clock: false,
    freq: 0,
    pw: 0,
    test: false,
    ring: false,
    sync: false,
    waveform: 0,
    resetting: false,
  )
