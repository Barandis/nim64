# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https:##opensource.org/licenses/MIT

## An emulation of the 6581 Sound Interface Device.
##
## The 6581 was designed as an advanced (for 1982) synthesizer, something that would set the
## new Commodore 64 apart from similar home computers. It has three individual oscillators
## that are each controlled with their own envelope generators and amplitude modulators. The
## outputs from these "voices" can optionally then be sent through a programmable audio
## filter (analog in the physical 6581, simulated digitally here), and then they are mixed
## for output. Tacked onto this is the capability to handle two game paddles
## (potentiometers).
##
## These features are controlled with a collection of 29 registers (32 addresses are
## available with the 5 address inputs, but the last three addresses are unused). The first
## 25 are write-only; these are 7 for control of each of the three voices and 4 for control
## of the filter and mixer. The final 4 registers are read-only and provide information
## about the potentiometers and the internals of voice 3.
##
## ======  ========  =====  ===============================================================
## Offset  Register  R/W    Description
## ======  ========  =====  ===============================================================
## `$00`   `FRELO1`  W      Voice 1 frequency, low 8 bits
## `$01`   `FREHI1`  W      Voice 1 frequency, high 8 bits
## `$02`   `PWLO1`   W      Voice 1 pulse width, low 8 bits
## `$03`   `PWHI1`   W      Voice 1 pulse width, high 4 bits
## `$04`   `VCREG1`  W      Voice 1 control register
## `$05`   `ATDCY1`  W      Voice 1 attack/decay
## `$06`   `SUREL1`  W      Voice 1 sustain/release
## `$07`   `FRELO2`  W      Voice 2 frequency, low 8 bits
## `$08`   `FREHI2`  W      Voice 2 frequency, high 8 bits
## `$09`   `PWLO2`   W      Voice 2 pulse width, low 8 bits
## `$0A`   `PWHI2`   W      Voice 2 pulse width, high 4 bits
## `$0B`   `VCREG2`  W      Voice 2 control register
## `$0C`   `ATDCY2`  W      Voice 2 attack/decay
## `$0D`   `SUREL2`  W      Voice 2 sustain/release
## `$0E`   `FRELO3`  W      Voice 3 frequency, low 8 bits
## `$0F`   `FREHI3`  W      Voice 3 frequency, high 8 bits
## `$10`   `PWLO3`   W      Voice 3 pulse width, low 8 bits
## `$11`   `PWHI3`   W      Voice 3 pulse width, high 4 bits
## `$12`   `VCREG3`  W      Voice 3 control register
## `$13`   `ATDCY3`  W      Voice 3 attack/decay
## `$14`   `SUREL3`  W      Voice 3 sustain/release
## `$15`   `CUTLO`   W      Filter cutoff, low 3 bits
## `$16`   `CUTHI`   W      Filter cutoff, high 8 bits
## `$17`   `RESON`   W      Filter voice switching and resonance
## `$18`   `SIGVOL`  W      Master volume and filter mode
## `$19`   `POTX`    R      Potentiometer X current value
## `$1A`   `POTY`    R      Potentiometer Y current value
## `$1B`   `OSC3`    R      Voice 3 waveform generator output, high 8 bits
## `$1C`   `ENV3`    R      Voice 3 envelope generator output
## ======  ========  =====  ===============================================================
##
## ## Voices
##
## Each of the 6581's three voices consists of a waveform generator, an envelope generator,
## and an amplitude modulator. The waveform generator creates a sound wave of a particular
## shape at the requested frequency. The envelope generator creates a volume profile for
## each "note", controlling the note's attack time, decay time, sustain level, and release
## time. The amplitude modulator then combines these two, making a waveform that varies in
## volume according to the envelope.
##
## ### Waveform Generators
##
## Each waveform generator starts with a 24-bit phase accumulating oscillator. This is a
## digital oscillator in which the 16-bit number held in `FRELOx` and `FREHIx` is added to
## the accumulator every clock cycle. Once the PAO reaches its max value, it rolls over to 0
## and starts again. In this way, the `FRELOx` and `FREHIx` registers control the frequency
## of the oscillator; a higher number will cause the PAO to roll over more often, increasing
## its frequency.
##
## The output of a PAO is therefore a digital sawtooth wave. In most applications, this
## output is fed to a lookup table which results in the value of a sine wave at that point
## in its phase (hence the name "phase accumulating oscillator"), but the 6581 doesn't have
## enough silicon to hold a lookup table. Instead, it uses logical manipulations to produce
## four waveforms that do not require lookup tables.
##
## One of those waveforms is the sawtooth itself. The top 12 bits of the PAO output are
## passed along as the sawtooth output.
##
## A triangle wave is produced by exclusive-oring the most significant bit of the PAO output
## with the next 11 bits. This causes those 11 bits to reverse when the MSB is high, turning
## the sawtooth into a triangle. These 11 bits are shifted to the left (and a 0 added as bit
## zero) to produce a triangle wave that has the same amplitude as the sawtooth but with
## half the resolution.
##
## A pulse wave is produced with a comparator. The value of the top 12 bits of the PAO is
## compared with the contents of the pulse width registers `PWLOx` and `PWHIx` (the high 4
## bits of `PWHIx` are ignored). If the register value is higher, the output is `0xfff`. If
## the PAO value is higher, the output is `0x000`. A square (pulse) wave is thus created
## that alternates at these two values at a rate depending on the frequency of the PAO's
## sawtooth, with the pulse width registers controlling the percentage of time that the
## waveform spends at the max value compared to the min value.
##
## Finally, pseudo-random noise is produced by a separate 23-bit linear feedback shift
## register (LFSR). This shift register is clocked by bit 19 of the PAO, so the frequency of
## the noise can be controlled. The values of bits 17 and 22 are exclusive-ored and fed back
## to bit 0. The result is a completely deterministic set of bits that nonetheless "looks"
## random. Eight bits of this register are used as the output; four zeros are added as low
## bits to create a 12-bit noise waveform.
##
## Selection of the waveforms is done with the `VCREGx` register, which looks like this:
##
## =========  =========  ==========  ==========  =========  =========  =========  =========
## 7          6          5           4           3          2          1          0
## =========  =========  ==========  ==========  =========  =========  =========  =========
## `NOISE`    `PULSE`    `SAWTOOTH`  `TRIANGLE`  `TEST`     `RING`     `SYNC`     `GATE`
## =========  =========  ==========  ==========  =========  =========  =========  =========
##
## Bits 4-7 control the output waveform. More than one of these can be selected at a time;
## doing so is *supposed* to (by the documentation) logically and the bits of each waveform
## together. The reality was not so. Combining waveforms creates output that can't be
## accurately modelled; this emulator instead uses samples of actual 6581 output to create
## these "combined waveforms".
##
## The exception is noise; due to a flaw in the chip design (and there were a few; the 6581
## was designed and produced with severe limits on time and silicon space), combining
## another waveform with the noise waveform causes the LFSR to fill with zeroes, resulting
## in zero output (and requiring that the chip be reset or the `TEST` bit to be set and
## cleared before noise can be produced again). This emulator simply returns a `0` value
## when combining noise.
##
## The diagram above has four other bits hinting at other functions. The `TEST` bit causes
## normal operation of it is low, but if it is set to high, the PAO fills with zeroes, the
## LFSR fills with ones, and the pulse generator latches at max value. Returning `TEST` to
## low resumes normal operation (including resetting the LFSR so it doesn't simply continue
## to produce all `1`s).
##
## The `SYNC` bit controls synching the PAO with another voice's PAO (the other voice is
## hardcoded; voice 1 used voice 3, voice 2 used voice 1, and voice 3 used voice 2). When
## the synched PAO's MSB transitions from `0` to `1`, the current PAO resets to zero no
## matter what value it is at. No other property of the synched PAO matters, only its
## frequency, so the synched voice can still be controlled to produce sound as normal. This
## mechanism allows for the production of much more complex waveforms than one PAO alone
## could do.
##
## The `RING` bit controls ring modulation. Ring modulation is only used if the current PAO
## is set to the triangle waveform. In this case, the MSB of the synced PAO is
## *exclusive-ored* with the current PAO's value, meaning that the current PAO output
## reverses (like the triangle wave output) when the synched MSB is `1`. This can produce
## even more complex waveforms with a wide range of non-harmonic overtones that can be used
## for creating special effects, including gongs and bells.
##
## The `GATE` bit has no effect on the waveform generator; it is used by the envelope
## generator that is discussed next.
##
## The high 8 bits of voice 3's waveform generator output are made available in the `OSC3`
## register. This register has often also been called something like `RANDOM` and has been
## so named because it's common usage to apply a `NOISE` waveform to voice 3 and then use
## this register to generate pseudo-random numbers. The waveform is available here even if
## the voice is not used, because it's never gated (see the `GATE` bit of the envelope
## generator below) or because it's disconnected (see the `DSCNV3` bit in the filter
## discussion even further below).
##
## ### Envelope Generator
##
## Each envelope generator is a simple circuit that produces a value from 0x00 to 0xff on
## every clock cycle. This value behaves in a way determined by the phase that the envelope
## generator is in at the time: either attack, decay, sustain, or release. The result is an
## "envelope", a volume profile that controls the way each note is shaped.
##
## The attack phase begins when the `GATE` bit of the `VCREGx` register (seen in the diagram
## just above) is set to `1`. The envelope output starts at 0x00 and rises to 0xff at a rate
## determined by the high 4 bits of the `ATDCYx` register, according to the following table:
##
## =====  ============
## Value  Attack rate
## =====  ============
## `$0`   2 ms
## `$1`   8 ms
## `$2`   16 ms
## `$3`   24 ms
## `$4`   38 ms
## `$5`   56 ms
## `$6`   68 ms
## `$7`   80 ms
## `$8`   100 ms
## `$9`   250 ms
## `$A`   500 ms
## `$B`   800 ms
## `$C`   1 s
## `$D`   3 s
## `$E`   5 s
## `$F`   8 s
## =====  ============
##
## Once the envelope output reaches `0xff`, the decay phase begins. In this phase, the
## envelope output falls at a rate determined by the low 4 bits of the `ATDCYx` register,
## according to the table above. However, at various points, the decay rate slows. This is
## used to produce a smooth curve from the max value to zero, and it results in the decay
## (and release, see below) phases taking potentially three times as long as the table
## above.
##
## The decay continues until the envelope output reaches the sustain level, set by the high
## 4 bits of the `SURELx` register. (Note that unlike attack and decay, this setting does
## not control a *time*, it controls a *level*.) The actual sustain value is derived by
## doubling the hexadecimal digit set in the register; setting sustain to `$C`, for
## instance, would cause the decay phase to end and the sustain phase to begin once the
## envelope output falls to `0xcc`. Nothing terribly interesting happens in the sustain
## phase; the envelope output simply stays at the same level.
##
## This phase transitions into the release phase when the `GATE` bit of the `VCREGx`
## register is set to `0`. The release phase is mechanically exactly the same as the decay
## phase, except that it makes the envelope output decrement all the way to zero rather
## than to the sustain level. The rate at which this happens is controlled by the low 4 bits
## of the `SURELx` register.
##
## The result is a volume profile that is meant to sound more natural than simply turning a
## waveform on and off to produce a note. It can be used to simulate a number of different
## instruments, from an organ (min attack and release, max sustain) to a percussion
## instrument (min attack, decay fast for a drum or slow for a cymbal, zero sustain). It can
## also be used to produce more unusual effects, such as the reverse envelope (slow attack,
## max sustain, fast release).
##
## The envelope generator has a couple of important bugs that were exploited by software
## engineers and thus need to be emulated as well. The most famous is the ADSR delay bug.
## This bug manifests when an attack, decay, or release value is reset in the middle of its
## phase to a number that has already passed. For example, if the attack is set initially to
## 250ms, and then after half that time it gets reset to 100ms, this bug would happen. The
## attack does not immediately stop and move into the decay phase; instead, the internal
## counter that controls each phase must reach its max value, wrap to zero, and *then* reach
## the new value before the attack will end. This can cause significant enough delays in
## phase transitions to be audible, and it would be used by programmers to create
## interesting sounds.
##
## Another bug skirts the design that once the envelope value does not wrap around once it
## reaches zero. In this case, if an attack is started by setting the `GATE` bit, and that
## `GATE` bit is immediately cleared while the envelope output is still zero (starting the
## release phase), then the envelope generator *will* wrap around, basically starting a
## release phase from `0xff` rather than just doing nothing as it should have.
##
## The output of voice 3's envelope generator is made available in the `ENV3` register.
##
## ### Amplitude modulator
##
## The amplitude modulator basically multiplies the outputs of the waveform and envelope
## generators. The result is the waveform produced by the waveform generator, with its
## volume controlled by the envelope produced by the envelope generator. There is no control
## for the amplitude modulator, and in this emulation, it does not merit a separate file of
## code (it's embedded into the voice code).
##
## ## Filter/mixer
##
## The 6581 also features a single programmable filter. Each voice can either skip the
## filter or be routed through it, and an additional external input (from the `EXT` pin) can
## be controlled in the same way. Whether or not these four inputs are filtered, they are
## all combined in a mixer at the end which produces the final output.
##
## The 6581's filter is an analog filter, but since we don't have the capability of being
## analog in a computer program, it is emulated digitally. The filter's mode, cutoff
## frequency, and resonance can be changed, along with the selection of voices that are
## routed through it, and these are all controlled by four registers.
##
## The cutoff frequency is controlled by the `CUTLO` and `CUTHI` registers. This renders an
## 11-bit number (the top 5 bits of `CUTLO` are ignored) that determines the frequency at
## which the filter begins to work - if set to low-pass, this is the frequency above which
## volume is lowered; if set to high-pass, this is the frequency *below* which volume is
## lowered; and if set to band-pass, this is the center of the frequencies that are passed
## through unimpeded while both lower *and* higher frequencies are suppressed.
##
## The values in `CUTLO` and `CUTHI` do not determine the cutoff frequency directly. In
## fact, the curve for frequencies depending on the register setting is complex and even has
## a discontinuiuty at one point. The cutoff frequency starts at about 220Hz at register
## value zero and rises, slowly at first, and then much more quickly as it approaches the
## halfway register value of `$3FF`; at `$3FF`, the frequency is about 6kHz. Then there is a
## sudden drop to about 4.6kHz at register value `$400`. The frequency then again rises,
## uickly at first and then slower as it approaches the max register value of `$7FF`, where
## the cutoff frequency is about 18kHz. There is no particular model to these values, and
## they vary slightly between chips; the values in this emulator are interpolated from 27
## sample values taken from a physical 6581 chip.
##
## The cutoff frequency values also depend on the two capacitors external to the chip. One
## is attached across `CAP1A` and `CAP1B`, while the other is connected to `CAP2A` and
## `CAP2B`. The values selected here assume 470pF capacitors across these pins, as was the
## case in the Commodore 64. The CAP pins are otherwise not emulated.
##
## The other two filter/mixer-related registers have multiple purposes. The `RESON` register
## controls resonance and which voices are actually filtered:
##
## =========  =========  =========  =========  =========  =========  =========  =========
## 7          6          5          4          3          2          1          0
## =========  =========  =========  =========  =========  =========  =========  =========
## `RES3`     `RES2`     `RES1`     `RES0`     `FILTEX`   `FILTV3`   `FILTV2`   `FILTV1`
## =========  =========  =========  =========  =========  =========  =========  =========
##
## Bits 4-7 control the resonance, which essentially causes frequencies near the cutoff
## frequency to be *amplified* before being attentuated beyond the cutoff frequency. This
## was an undesirable artifact in filters originally, but it became useful particularly for
## sound effects and so is often a feature in modern filters. A higher value for resonance
## will cause frequencies near the cutoff frequency to be amplified more.
##
## Bits 0-3 control which voices are sent through the filter in the first place; there is
## one bit for each voice, plus an additional bit to control whether the external input is
## filtered. (The external input is not otherwise controllable; it is either filtered or
## not, and then it's mixed with the signals from the three voices before being output.)
##
## The type of filter is determined by the settings in the final filter register, `SIGVOL`:
##
## =========  =========  =========  =========  =========  =========  =========  =========
## 7          6          5          4          3          2          1          0
## =========  =========  =========  =========  =========  =========  =========  =========
## `DSCNV3`   `FILTHP`   `FILTBP`   `FILTLP`   `VOL3`     `VOL2`     `VOL1`     `VOL0`
## =========  =========  =========  =========  =========  =========  =========  =========
##
## Bits 4-6 control the filter mode, which is either high-pass, band-pass, or low-pass.
## These modes can be combined (though they must share their cutoff frequencies and
## resonances); a common way to do this is to create a "notch filter" by combining high-pass
## and low-pass filters that reject frequencies near the cutoff frequency in a manner
## opposite to that of a band-pass filter.
##
## Bit 7 allows voice 3 to be disconnected entirely. This is only possible if voice 3 is
## *not* routed through the filter; if it is, the setting of this bit is ignored. This
## option lets voice 3 be used simply for synching or ring modulation without actually
## contributing sound to the output.
##
## The other four bits (0-3) control the master volume of the mixer. All four signals,
## whether they are filtered or unfiltered, are combined by a mixer and the final volume of
## that mixer is controlled by these four bits.
##
## ## External filter
##
## In the physical 6581, the signal that comes out of the mixer is sent directly to the
## `AUDIO` output pin. However, in the Commodore 64, this pin is connected to another filter
## external to the 6581, and the output of that filter is actually sent to the audio/video
## connector. For the sake of convenience, that external filter is emulated directly in this
## Ic6581 type.
##
## The external filter is a simple pair of RC filters that is tuned to pass frequencies
## between 16Hz and 16kHz. It is completely passive, neither tunable or otherwise
## controllable (including that it can't be disabled).
##
## ## Potentiometers
##
## Completely unrelated to sound production, the 6581 also dedicates two pins and two
## registers to potentiometer reading. In practice, these potentiometers are almost always
## game paddles, though there is nothing preventing them from being any other kind of device
## that can send a varying voltage to the `POTX` and `POTY` pins (via Control Ports 1 and
## 2).
##
## The physical 6581 expects these to be RC circuits that charge a capacitor at a varying
## rate depending on the value of the resistor (which is a variable resistor - a
## potentiometer - that is normally the game paddle itself). The 6581 circuitry reads the
## capacitor discharge time and translates it to a value between `0x00` and `0xff`, which is
## then made available in the appropriate register (`POTXR` register for `POTX` pin, and
## `POTYR` register for `POTY` pin). This process takes 512 clock cycles, so the values of
## the registers update that often.
##
## In this emulation, physical processes like capacitor discharge are not modelled, so the
## values on the `POTX` and `POTY` pins are simply reflected in their registers (after
## dropping any bits above the eighth). The registers still only update every 512 cycles to
## be consistent with that original behavior.
##
## ## Read-only versus write-only registers
##
## The 6581 is unusual in that it has no registers that can be both read and written. The
## `POTX`, `POTY`, `OSC3`, and `ENV3` registers are read-only; attempting to write to these
## registers has no effect. All of the other registers are write-only, and attempting to
## read them is handled a bit strangely.
##
## When a register is written to in a physical 6581, the value on the data pins lingers on
## the internal data bus for a time. An attempt to read a write-only register would then
## result in that value, no matter which register had been written and no matter which
## write-only register has a read attempted on it. This value on the internal data bus would
## decay over time, causing bits to switch to zero at unpredictable times over the course of
## about two milliseconds. Since that unpredicable behavior is impossible to model (it's
## different on every 6581), the choice here is to return the last written value on any read
## of a write-only register, unless it's been more than 2000 clock cycles since the last
## write. In that case, a zero is returned.
##
## ## Pin interface
##
## The vast majority of interaction with the 6581 is done through setting registers to
## certain values. The main output only takes up one pin. For this reason, despite the
## complexity of the chip internally, it can comfortably fit in a 28-pin package.
## ```
##            +-----+--+-----+
##      CAP1A |1    +--+   28| VDD
##      CAP1B |2           27| AUDIO
##      CAP2A |3           26| EXT
##      CAP2B |4           25| VCC
##        RES |5           24| POTX
##       PHI2 |6           23| POTY
##        R_W |7           22| D7
##         CS |8    6581   21| D6
##         A0 |9           20| D5
##         A1 |10          19| D4
##         A2 |11          18| D3
##         A3 |12          17| D2
##         A4 |13          16| D1
##        GND |14          15| D0
##            +--------------+
## ```
## Some names are changed from the datasheet, aside from the regular switch from φ2 to PHI2.
## POTX and POTY are called POT X and POT Y respectively, and the audio pins are called EXT
## IN and AUDIO OUT. These are all changed here because spaces are inconvenient.
##
## Pin assignments are explained below.
##
## =====  =======  ========================================================================
## Pin    Name     Description
## =====  =======  ========================================================================
## 1      `CAP1A`  Connection for filter capacitor 1, not emulated.
## 2      `CAP1B`  Connection for filter capacitor 1, not emulated.
## 3      `CAP2A`  Connection for filter capacitor 2, not emulated.
## 4      `CAP2B`  Connection for filter capacitor 2, not emulated.
## 5      `RES`    Reset. When this goes low, the chip resets.
## 6      `PHI2`   Clock input. Should be 1MHz; other values will shift audio frequencies.
## 7      `R_W`    Read (`1`) and write (`0`) control for the registers.
## 8      `CS`     Chip select. Must be low to read or write registers.
## 9      `A0`     Address pin 0.
## 10     `A1`     Address pin 1.
## 11     `A2`     Address pin 2.
## 12     `A3`     Address pin 3.
## 13     `A4`     Address pin 4.
## 14     `GND`    Electrical ground. Not emulated.
## 15     `D0`     Data pin 0.
## 16     `D1`     Data pin 1.
## 17     `D2`     Data pin 2.
## 18     `D3`     Data pin 3.
## 19     `D4`     Data pin 4.
## 20     `D5`     Data pin 5.
## 21     `D6`     Data pin 6.
## 22     `D7`     Data pin 7.
## 23     `POTY`   Potentiometer Y input.
## 24     `POTX`   Potentiometer X input.
## 25     `VCC`    +5V power supply. Not emulated.
## 26     `EXT`    External audio input.
## 27     `AUDIO`  Audio output.
## 28     `VDD`    +12V power supply. Not emulated.
## =====  =======  ========================================================================
##
## Pins `POTX`, `POTY`, `EXT`, and `AUDIO` are all analog pins. `POTX` and `POTY` expect
## values from `0x00` to `0xff` on them; if higher values are applied to these pins, the top
## bits will be left off until there are 8 left. `AUDIO` is approximately 20 bits wide, and
## `EXT` should be about the same to mix evenly with the generated audio.
##
## In the Commodore 64, U18 is a 6581. It responds to addresses from `$D400` to `$D7FF`.
## This is many more addresses than are necessary to accomodate the 29 registers that are
## actually present. These registers repeat every 32 (`$20`) addresses through that space.
## For example, writing `$D400`, `$D420`, `$D440`, etc. will all write to the `FRELO1`
## register, and reading `$D419`, `$D439`, `$D459`, etc. will all read from the `POTX`
## register. It's recommended to ignore this "feature" and just read from/write to the
## lowest address (`$D400` and `$D419` in these examples).
##
## R7, R38, C13, C37, and Q8 make up the external filter that is not a part of the physical
## chip but that is emulated by this type.

import sequtils
import strformat
import ../utils
import ../components/[chip, link]
import ./ic6581/voice
import ./ic6581/filter
import ./ic6581/external

chip Ic6581:
  pins:
    input:
      # Address pins to access internal registers
      A0: 9
      A1: 10
      A2: 11
      A3: 12
      A4: 13

      # Potentiometer pins. These are analog inputs whose value is fed to the appropriate
      # registers every 512 cycles.
      POTX: 24
      POTY: 23

      # External audio input. This is also an analog input which should be somewhere near
      # 20 bits in size.
      EXT: 26

      # System clock input. This is expected to be a 1 MHz clock.
      PHI2: 6

      # Read/write. Determines whether data is being read from (1) or written to (0) the
      # registers on the chip.
      R_W: 7

      # Chip select pin. When this is low, the chip allows communication with its registers
      # through the address pins and the R_W pin. When this is high, the data pins are
      # tri-stated.
      CS: 8

      # Resets the chip on a low signal.
      RES: 5

    output:
      # Data pins. These can move data in either direction, but only one direction at a
      # time, dictated by the R_W pin.
      D0: 15
      D1: 16
      D2: 17
      D3: 18
      D4: 19
      D5: 20
      D6: 21
      D7: 22

      # Audio out. This is an analog output that, at full volume, will have values around
      # 20 bits in size.
      AUDIO: 27

    unconnected:
      # Filter capacitor connections. Larger capacitors, necessary for the proper operation
      # of the on-board filters, are connected across these pairs of pins. There is no need
      # to emulate them here.
      CAP1A: 1
      CAP1B: 2
      CAP2A: 3
      CAP2B: 4

      # Power supply and ground pins. These are not emulated.
      VDD: 28
      VCC: 25
      GND: 14

  registers:
    # These are all described in the large comment at the beginning of this file, so no
    # further description is given here.

    # Voice 1
    FRELO1: 0
    FREHI1: 1
    PWLO1: 2
    PWHI1: 3
    VCREG1: 4
    ATDCY1: 5
    SUREL1: 6

    # Voice 1
    FRELO2: 7
    FREHI2: 8
    PWLO2: 9
    PWHI2: 10
    VCREG2: 11
    ATDCY2: 12
    SUREL2: 13

    # Voice 3
    FRELO3: 14
    FREHI3: 15
    PWLO3: 16
    PWHI3: 17
    VCREG3: 18
    ATDCY3: 19
    SUREL3: 20

    # Filter
    CUTLO: 21
    CUTHI: 22
    RESON: 23
    SIGVOL: 24

    # Read-only registers. The 'R' is added to the POT registers to give them distinct names
    # from the pins associated with them.
    POTXR: 25
    POTYR: 26
    OSC3: 27
    ENV3: 28

    # Unused, included so that there's an even 32
    UNUSED1: 29
    UNUSED2: 30
    UNUSED3: 31

  init:
    # Pulling these down so that if they're unconnected (level NaN), they'll put 0 in their
    # registers
    pull_down(pins[POTX])
    pull_down(pins[POTY])

    let addr_pins = map(to_seq 0..4, proc (i: int): Pin = pins[&"A{i}"])
    let data_pins = map(to_seq 0..7, proc (i: int): Pin = pins[&"D{i}"])

    # This is the maximum number of cycles for which a write-only register, when read, will
    # return a value of whatever was last written to *any* register. After that number of
    # cycles since the last write, any read from a write-only register will result in zero.
    # This is a simplification of the actual write-only read model, which fades the value
    # more gradually to zero.
    const MaxLastWriteTime = 2000

    # The spec says that RES must be low for at least 10 cycles before a reset will occur.
    # This variable is set to 0 when RES first goes low, and each φ2 cycle increments it.
    # When it gets to 10, `reset` will be called.
    var reset_clock = 0

    # Flag to know whether the chip has reset since the last time RES went low. This is used
    # to ensure that the chip only resets once, rather than once every 10 cycles as long as
    # RES is held low.
    var has_reset = false

    # The last value that was written to a write-only register. This is used to emulate the
    # way the SID returns that value if a write-only register is read from.
    var last_write_value = 0u8

    # The number of cycles since the last write to a write-only register. After a certain
    # number of these, reading from a write-only register no longer returns the last written
    # value and instead returns 0.
    var last_write_time = 0

    # The number of cycles since the last time the potentiometer pins were read and their
    # values stored in the pot registers. This resets after 512 cycles.
    var last_pot_time = 0

    include ./ic6581/constants

    # The three voices, each consisting of an independent waveform generator, envelope
    # generator, and amplitude modulator.
    let voice1 = new_voice()
    let voice2 = new_voice()
    let voice3 = new_voice()

    sync(voice1, voice3)
    sync(voice2, voice1)
    sync(voice3, voice2)

    # The filter for the individual voices, plus the mizer that combines them into one
    # signal.
    let filter = new_filter()

    # The external filter. This is actually, as the name suggests, a circuit that is
    # external to the 6581. It is a high-pass RC filter tuned to 16Hz and a low-pass RC
    # filter tuned to 16kHz. In a physical C-64, this is the only thing that exists between
    # the audio out pin of the 6581 and the audio output pin on the audio/video connector,
    # so it makes sense to have it be a part of a 6581 emulation that is intended only for a
    # C64 emulation.
    let external = new_external_filter()

    proc reset =
      # This is the result of a reset according to the specs of the device. This is pretty
      # simple since the only outputs are the data lines and the audio out; all registers
      # are set to zero, audio output is silenced, and data lines are set back to their
      # normal unconnected state.
      #
      # Since the three unused registers always return $FF, we just set that here and keep
      # it from changing.
      for i in 0..31:
        registers[i] = if i >= UNUSED1: 0xff else: 0x00
      mode_to_pins(Output, data_pins)
      tri_pins(data_pins)

      reset(voice1)
      reset(voice2)
      reset(voice3)
      reset(filter)
      reset(external)

    proc read_register(index: int): uint8 =
      # Reads a SID register. This only works as expected for the four read-only registers.
      #
      # The three unused registers always return $FF. The write-only registers return the
      # value of the last write made to *any* SID register. However, in the real chip this
      # last-write value 'fades' over time until, after 2000-4000 clock cycles, it is zero.
      # The model for this fading is unknown and is not properly emulated here; this
      # emulation simply returns the last written value as long as the last write has
      # happened in the last 2000 cycles; otherwise it returns 0.
      if index < POTXR: last_write_value else: registers[index]

    proc write_register(index: int, value: uint8) =
      if index == PWHI1 or index == PWHI2 or index == PWHI3:
        # Strip the upper four bits
        registers[index] = value and 0x0f
      elif index == CUTLO:
        # Strip the upper five bits
        registers[index] = value and 0x07
      elif index < POTXR:
        registers[index] = value
      last_write_value = value
      last_write_time = 0

      case index
      of FRELO1: frelo(voice1, value)
      of FREHI1: frehi(voice1, value)
      of PWLO1:  pwlo(voice1, value)
      of PWHI1:  pwhi(voice1, value)
      of VCREG1: vcreg(voice1, value)
      of ATDCY1: atdcy(voice1, value)
      of SUREL1: surel(voice1, value)
      of FRELO2: frelo(voice2, value)
      of FREHI2: frehi(voice2, value)
      of PWLO2:  pwlo(voice2, value)
      of PWHI2:  pwhi(voice2, value)
      of VCREG2: vcreg(voice2, value)
      of ATDCY2: atdcy(voice2, value)
      of SUREL2: surel(voice2, value)
      of FRELO3: frelo(voice3, value)
      of FREHI3: frehi(voice3, value)
      of PWLO3:  pwlo(voice3, value)
      of PWHI3:  pwhi(voice3, value)
      of VCREG3: vcreg(voice3, value)
      of ATDCY3: atdcy(voice3, value)
      of SUREL3: surel(voice3, value)
      of CUTLO:  cutlo(filter, value)
      of CUTHI:  cuthi(filter, value)
      of RESON:  reson(filter, value)
      of SIGVOL: sigvol(filter, value)
      else: discard

    proc reset_listener(pin: Pin) =
      if lowp(pin):
        reset_clock = 0
        reset(voice1, false)
        reset(voice2, false)
        reset(voice3, false)
      elif highp(pin):
        has_reset = false

    proc clock_listener(pin: Pin) =
      if highp(pin):
        # Check to see if RES has been held low for 10 cycles; if so, perform the reset
        if lowp(pins[RES]) and not has_reset:
          reset_clock += 1
          if reset_clock >= 10:
            reset()
            has_reset = true

        # Check to see if last written value has bled off the internal data bus yet
        last_write_time += 1
        if (last_write_time >= MaxLastWriteTime): last_write_value = 0

        # Check to see if pots should be read (once every 512 clock cycles); if so, load
        # their registers with the values of the pins
        last_pot_time += 1
        if (last_pot_time >= 512):
          last_pot_time = 0
          registers[POTXR] = uint8(int(level(pins[POTX])) and 0xff)
          registers[POTYR] = uint8(int(level(pins[POTY])) and 0xff)

        # Clock sound components and put their outputs on the AUDIO pin
        clock(voice1)
        clock(voice2)
        clock(voice3)
        clock(filter, output(voice1), output(voice2), output(voice3), int(level(pins[EXT])))
        clock(external, output(filter))
        set_level(pins[AUDIO], float(output(external)))

        # Dump the voice 3 oscillator and envelope values into their registers
        registers[OSC3] = uint8((waveform_output(voice3) shr 4) and 0xff)
        registers[ENV3] = uint8(envelope_output(voice3))

    proc enable_listener(pin: Pin) =
      if highp(pin):
        mode_to_pins(Output, data_pins)
        tri_pins(data_pins)
      elif lowp(pin):
        let index = pins_to_value(addr_pins)
        if highp(pins[R_W]):
          value_to_pins(read_register(int(index)), data_pins)
        elif lowp(pins[R_W]):
          mode_to_pins(Input, data_pins)
          write_register(int(index), uint8(pins_to_value(data_pins)))

    add_listener(pins[RES], reset_listener)
    add_listener(pins[PHI2], clock_listener)
    add_listener(pins[CS], enable_listener)
