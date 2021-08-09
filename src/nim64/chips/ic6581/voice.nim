# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ./envelope
import ./waveform

# The value of the waveform generator that corresponds to zero in the output waveform. Since
# the 12-bit waveform output ranges from 0x000 to 0xfff, this value *should* be in the
# middle, at 0x800. However, actual measurement of the zero-output voltages on the 6581's
# output pins showed that the actual zero value was much lower.
#
# It's entirely possible that different chips could lead to different zero values, but they
# all should be similar enough that this value will suffice for emulation.
const WaveformZero = 0x380

# It turns out that the D/A converter in the 6581 (which is not emulated since the emulation
# is entirely digital) adds an additional DC offset to the output signal. This was also
# measured directly on a physical 6581 to be about this value.
const VoiceOffset = 0x800 * 0xff

type Voice* = ref object
  ## An emulation of a single 6581 voice, including a waveform generator, an envelope
  ## generator, and an amplitude modulator. The waveform and envelope generators are created
  ## from their respective types, while the amplitude modulator is built into this type
  ## (in the `output` proc).
  ##
  ## This is a pretty straightforward class, consisting largely of procs that delegate to
  ## the underlying waveform and envelope generators. The amplitude modulator is fashioned
  ## by simply multiplying the outputs of the generators, adjusting the output value with
  ## the DC offsets that have been found in the actual chip.
  waveform: Waveform ## This voice's waveform generator.
  envelope: Envelope ## This voice's envelope generator.

proc frelo*(voice: Voice, value: uint) =
  ## Sets the lower 8 bits of the frequency of the voice's waveform generator.
  frelo(voice.waveform, value)

proc frehi*(voice: Voice, value: uint) =
  ## Sets the upper 8 bits of the frequency of the voice's waveform generator.
  frehi(voice.waveform, value)

proc pwlo*(voice: Voice, value: uint) =
  ## Sets the lower 8 bits of the pulse width of the voice's waveform generator.
  pwlo(voice.waveform, value)

proc pwhi*(voice: Voice, value: uint) =
  ## Sets the upper 4 bits of the pulse width of the voice's waveform generator. The high 4
  ## bits of the passed value are ignored.
  pwhi(voice.waveform, value)

proc vcreg*(voice: Voice, value: uint) =
  ## Sets the value of the control register for the voice. Setting bit 0 to a different
  ## value than it previously had will initiate the attack phase (`0` -> `1`) or the release
  ## phase (`1` -> `0`) of the voice's envelope generator.
  vcreg(voice.waveform, value)
  vcreg(voice.envelope, value)

proc atdcy*(voice: Voice, value: uint) =
  ## Sets the attack (upper 4 bits) and the decay (lower 4 bits) for the voice's envelope
  ## generator.
  atdcy(voice.envelope, value)

proc surel*(voice: Voice, value: uint) =
  ## Sets the sustain (upper 4 bits) and the release (lower 4 bits) for the voice's envelope
  ## generator.
  surel(voice.envelope, value)

proc reset*(voice: Voice, value: bool = true) =
  ## Resets the voice. This delegates to the reset procs for the voice's waveform and
  ## envelope generator, which means that it requires two calls for a full reset (the first
  ## happens when `RES` goes low, and the second when it returns high).
  reset(voice.waveform, value)
  reset(voice.envelope, value)

proc clock*(voice: Voice) =
  ## Clocks the waveform and envelope generators so that they calculate their next output
  ## values.
  clock(voice.waveform)
  clock(voice.envelope)

proc sync*(voice: Voice, target: Voice) =
  ## Syncs another voice to this voice. This is used by the waveform generator when the
  ## SYNC or RING bits are set in the control register.
  sync(voice.waveform, target.waveform)

proc output*(voice: Voice): int =
  ## Calculates the output of the voice on this clock cycle. This proc emulates the
  ## "Amplitude Modulator" listed on the 6581 block diagram on its datasheet. The amplitude
  ## modulator is simple enough that it is integrated directly into the voice, rather than
  ## having a separate type for it and having Voice combine all three.
  (int(output(voice.waveform)) - WaveformZero) * int(output(voice.envelope)) + VoiceOffset

proc waveform_output*(voice: Voice): uint =
  ## Returns the output of the voice's waveform generator.
  output(voice.waveform)

proc envelope_output*(voice: Voice): uint =
  ## Returns the output of the voice's envelope generator.
  output(voice.envelope)

proc new_voice*: Voice =
  ## Creates a new Voice.
  Voice(
    waveform: new_waveform(),
    envelope: new_envelope(),
  )
