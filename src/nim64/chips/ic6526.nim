# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https:##opensource.org/licenses/MIT

## An emulation of the 6526 Complex Interface Adapter.
##
## The 6526 CIA was designed as an I/O provider for the 6500-series microprocessors. It
## features two 8-bit parallel data ports, a serial data port, two microsecond-accuracy
## interval timers, and a 0.1 second-accuracy time-of-day clock.
##
## These features are controlled and interacted with via 16 8-bit registers on the chip. In
## the Commodore 64, these can be accessed with the base addresses of `$DC00` (for CIA 1)
## and `$DD00` (for CIA 2).
##
## ======  =========  ============================
## Offset  Register   Function
## ======  =========  ============================
## `$0`    `PRA`      Parallel Data Register A
## `$1`    `PRB`      Parallel Data Register B
## `$2`    `DDRA`     Data Direction Register A
## `$3`    `DDRB`     Data Direction Register B
## `$4`    `TALO`     Timer A Low Register
## `$5`    `TAHI`     Timer A High Register
## `$6`    `TBLO`     Timer B Low Register
## `$7`    `TBHI`     Timer B High Register
## `$8`    `TOD10TH`  Time-of-Day Tenths Register
## `$9`    `TODSEC`   Time-of-Day Seconds Register
## `$A`    `TODMIN`   Time-of-Day Minutes Register
## `$B`    `TODHR`    Time-of-Day Hours Regsiter
## `$C`    `SDR`      Serial Data Register
## `$D`    `ICR`      Interrupt Control Register
## `$E`    `CRA`      Control Register A
## `$F`    `CRB`      Control Register B
## ======  =========  ============================
##
## ## Parallel Data Ports
##
## The pins `PA0`-`PA7` and `PB0`-`PB7` make up the two parallel data ports. The direction
## of each pin (input or output) is controlled individually by the corresponding bit in the
## Data Direction Register for each port (`DDRA` and `DDRB` respectively). Setting a bit to
## `1` means that that pin is being used as an output; a `0` sets it to an input instead.
##
## The parallel data registers, when read, return the state of the port's pins at that time,
## whether the pin is an input or an output. Writing to the parallel data registers sets the
## value of a pin (as long as it's an output pin, bits associated with input pins are
## ignored).
##
## Port B additionally can be used as outputs for the timers; `PB6` can signal for Timer A
## and `PB7` for Timer B. To do this, the `PBON` bit in the appropriate control register
## (`CRA` or `CRB`) must be set. The output mode is set with the `OUTMODE` bit in the same
## register. Setting this bit means that the output pin will toggle levels each time the
## timer reaches 0; clearing it means that a one-cycle-long high pulse will happen each time
## the timer reaches 0. This setting overrides the input/output settings; as long as one of
## the `PBON` bits is set, that Port B pin will be an output whatever is set in `DDRB`.
##
## Finally, the `PC` pin is associated with Port B. Each time `PRB` is read or written, the
## `PC` pin will go low for one cycle. This is useful as a signal that either the port's
## data has been accepted or that the port has data ready to be received.
##
## ## Interval Timers
##
## The two interval timers each track their countdown in pairs of registers - `TALO` and
## `TAHI` for Timer A and `TBLO` and `TBHI` for Timer B - allowing them to count a maximum
## of 65,536 cycles. The timers can count clock cycles (provided on pin `PHI2`) or
## transitions of the `CNT` pin to high. Given clock cycles with a 1 MHz clock frequency
## (typical of a Commodore 64), this makes for a maximum interval of about 0.066 seconds.
##
## Timer B can additionally count the number of times that Timer A reaches zero (called
## "underflow" in the literature) or the number of times that Timer A reaches zero while the
## `CNT` pin is high. By setting Timer A to count clock cycles and Timer B to count Timer A
## underflows, a maximum interval of over 71 minutes can be achieved.
##
## The type of event to count is set in the control registers. `CRA` has a bit called
## `INMODE`; if this is `0`, Timer A counts clock cycles, and if it's `1`, Timer A counts
## `CNT` transitions. For Timer B, `CRB` has *two* bits (`INMODE0` and `INMODE1`). A value
## of `00` or `01` on these bits is the same as for Timer A, but `10` causes Timer B to
## count Timer A underflows and `11` means Timer B will count only the Timer A underflows
## that happen when the `CNT` pin is high.
##
## Once a timer reaches zero, a number of things can happen. First, an interrupt request may
## be signaled. This requires that the `TA` or `TB` bits in the register `ICR` be set.
## Secondly, an output can be signaled on `PB6` (for Timer A) or `PB7` (for Timer B).
## Details of this have already been discussed in the "Parallel Data Ports" section.
## Finally, the timer is reset and the decision is made to either stop there or to continue
## counting down. This is controlled by the `RUNMODE` bit in `CRA` or `CRB`. If this bit is
## `0`, the timer resets and continues running; if it is `1`, the timer still resets but
## does not re-run.
##
## The four timer registers can be read at any time to see how many cycles remain for their
## respective timers. *Writing* to these registers is different. A write sets the value on a
## write-only shadow register of sorts that is associated with the actual register. When the
## register resets, the values in these shadow registers are what are loaded into the actual
## register. Hence, when writing to these registers, the values will not load into the
## actual register until the next underflow for that timer.
##
## The load will happen immediately if the `LOAD` bit of either `CRA` or `CRB` are set.
## Whatever is in the countdown registers will be overwritten with whatever is in the shadow
## registers at that point, effectively starting the countdown over at the new value. The
## value of `LOAD` is not stored; it is a strobe that causes the registers to reload
## immediately when it is written.
##
## Timer A may also be associated with the Serial Data Port. See that section below for more
## details.
##
## ## Time of Day Clock
##
## The Time of Day (TOD) clock is a much more human-friendly sort of timer. Rather than
## dealing with microseconds, the TOD's four registers store hours (`TODHR`), minutes
## (`TODMIN`), seconds (`TODSEC`), and tenths of seconds (`TOD10TH`). Once set, the TOD
## clock keeps accurate time as long as the signals on the clock pins are accurate.
##
## Reading these registers reveals the current time, but it has to be done in a particular
## manner. Reading `TODHR` causes all of the registers to stop updating until `TOD10TH` is
## read. This is to ensure that all four registers can be read at the same "time".
## Otherwise, it is possible (for example) to start reading the time at 1:59:59.9 and have
## time second tick over before the read is finished, making the first read happen before
## the hour changes and the others happen after. If this happened, the time would appear to
## be 1:00:00.0 when it really should be 2:00:00.0. The clock itself is not stopped during
## this pause; the clock merely doesn't update the registers until `TOD10TH` is next read.
##
## Writing the TOD registers works the same way, with a couple of additional caveats. First,
## the clock itself stops after `TODHR` is written until `TOD10TH` is also written. Second,
## it is possible that writing to these registers doesn't change the time at all; if the
## `ALARM` bit of `CRB` is set, then writing these registers changes the *alarm*, which is
## kept in shadow registers that can't be read.
##
## The four registers assume their data to be in a different kind of format: binary-coded
## decimal (BCD). In BCD, every four bits is used to represent a decimal digit rather than
## a hexadecimal digit. In this scheme, a register with the value `0000 1001` (`$09`),
## after incrementing, would hold the value `0001 0000` (`$10`) instead of the regular
## `0000 1010` (`$0A`). This means several values are invalid, which is never the case with
## regular binary numbers, but BCD is much easier to translate into straight decimal.
##
## Because of this BCD formatting, we know that the top four bits of `TOD10TH` will always
## be `0` (since the highest number it will hold is `$09`). Similarly, the top bit of
## `TODSEC` and `TODMIN` (max values `$59`) will always be `0`. The top 3 bits of `TODHR`
## (max value `$12`; there is no support for 24-hour time) would be always `0` except that
## bit 7 (`PM`) is used to indicate AM (`0`) or PM (`1`).
##
## The clock operates on external clock pulses fed to the `TOD` pin. By default, these
## pulses are expected to arrive at 60 Hz (in other words, `TOD10TH` will be incremented
## after every sixth pulse). If the `TODIN` bit of `CRA` is set, it will instead assume the
## clock frequency is 50 Hz (and `TOD10TH` will instead be updated every fifth clock pulse).
## Obviously, the accuracy of these pulses is important to having the correct time.
##
## When the clock reaches the same time as set in the alarm, an interrupt request will be
## initiated if the `ALRM` bit of the `ICR` register is set. Whether or not the interrupt is
## requested, the TOD clock will simply keep ticking.
##
## ## Serial Data Port
##
## In addition to the two parallel data ports, the 6526 features a single bidirectional
## serial data port. The serial port operates by coordinating the `SDR` and `CRA` registers,
## Timer A, interrupts, and the `SP` and `CNT` pins.
##
## Whether the serial port is being used to send or receive data is controlled by `SPMODE`
## bit of register `CRA` (`0` for receive and `1` for send). If receiving, the chip pushes a
## bit from the `SP` pin to an internal shift register every time the `CNT` pin goes high
## (the sending device is responsible for signaling `CNT`). Once 8 bits have been received,
## they are deposited in the `SDR` register and an interrupt request is generated.
##
## If the chip is sending, the contents of `SDR` are first pulled into the internal shift
## register. Timer A is used to clock the output; every *other* time that Timer A
## underflows, a bit will be taken from the shift register and put on the `SP` pin. At the
## same time, the `CNT` pin will be set high to indicate that the bit is ready (this is why
## the clock rate is half the Timer A underflow rate; the other underflows are used to clear
## the `CNT` pin.) Once the entire byte is sent, an interrupt request is generated; if the
## CPU had already put a new byte into `SDR` the transmission will continue, otherwise it
## will be paused until the next byte is ready.
##
## ## Control Registers
##
## Alongside the registers for the parallel ports, the interval timers, the TOD clock, and
## the serial port, the 6526 has three control registers. One controls the request of
## interrupts while the other two control the interval timers, the TOD clock, and the serial
## port.
##
## ### Interrupt Control Register (`ICR`)
##
## The ICR has different functions depending on whether it's being read from or written to.
## *Writing* to the ICR sets what interrupts should be responded to. *Reading* from the ICR
## reveals what interrupt conditions have been met and whether an interrupt request has
## actually been signaled.
##
## When written, the ICR looks like this.
##
## ======  ======  ======  ======  ======  ======  ======  ======
## 7       6       5       4       3       2       1       0
## ======  ======  ======  ======  ======  ======  ======  ======
## `SC`    x       x       `FLG`   `SP`    `ALRM`  `TB`    `TA`
## ======  ======  ======  ======  ======  ======  ======  ======
##
## Bits 0-4 are flags that represent the five sources of interrupts in the 6526:
##
## * `TA`: Timer A undeflow
## * `TB`: Timer B undeflow
## * `ALRM`: TOD Alarm
## * `SP`: The `SDR` register being full (receive) or empty (send)
## * `FLG`: The `FLAG` pin going low
##
## This marks the first appearance of the `FLAG` pin; this is simply a pin that potentially
## requests an interrupt when it goes low. A potential use of this is tying it to the `PC`
## pin of another 6526 to request an interrupt when parallel port data is sent or received
## (there is no interrupt bit for that).
##
## These bits are masks. If a bit is set, that indicates that the event associated with that
## bit *will* fire an interrupt (i.e., the IRQ pin will go low) when that event happens. If
## that bit is cleared, the event is still recorded, but no interrupt request goes out.
##
## The `SC` bit indicates whether the write is setting bits (`1`) or clearing them (`0`).
## Therefore, somewhat unintuitively, sending a `0` for a bit does not clear that bit; it
## leaves it unaffected. To set bits, one writes a value that has a `1` in the `SC` bit;
## i.e., writing `$85` (`10000101`) will set the `ALRM` and `TA` bits and leave the other
## bits unaffected.
##
## The same works for clearing bits, except that the `SC` bit is `0` in that case.
## Similarly, writing `$05` (`00000101`) will *clear* the `ALRM` and `TA` bits and leave the
## others unchanged. This means that clearing every bit actually requires writing something
## like `$1F` (`00011111`, the values of bits 5 and 6 actually don't matter because they're
## not associated with any interrupt flags).
##
## Reading the ICR looks a little different.
##
## ======  ======  ======  ======  ======  ======  ======  ======
## 7       6       5       4       3       2       1       0
## ======  ======  ======  ======  ======  ======  ======  ======
## `IR`    0       0       `FLG`   `SP`    `ALRM`  `TB`    `TA`
## ======  ======  ======  ======  ======  ======  ======  ======
##
## Bits 0-4 are the same names as when writing the register. In reading, however, they
## indicate that the event they're associated with *has actually happened* since the last
## time the `ICR` was read. The appropriate bit(s) will be set no matter what the interrupt
## mask settings that have been written.
##
## The masks instead affect the `IR` bit. If the event happened *and* the `ICR` had been
## written with a value that turned the bit for that event on, then the `IR` bit will also
## be set and the `IRQ` pin will go low.
##
## Here is an example for illustration. The reset state of the 6526 has all interrupt masks
## set to `0`. If `$82` (`10000010`) is written to the register, then the Timer B mask will
## be turned on and all the others will remain off. If Timer B was then set to count exactly
## two Timer A underflows (`TBLO` is `$02`, `TBHI` is `$00`, and the `INMODE1` and `INMODE0`
## bits of `CRB` are set to `10`), then the first Timer A underflow will only request an
## interrupt for Timer A and the second will request for both.
##
## In this scenario, when Timer A underflows for the first time, the `IRQ` pin will not be
## low and reading the `ICR` will yield `$01` (`00000001`). The Timer A underflow has
## happened (hence the `TA` bit being set when reading the `ICR`), but no interrupt has
## actually been requested (the `IR` bit is `0` and the `IRQ` pin is not low). This is
## because the Timer A mask, set by writing the `ICR`, was never set to `1`.
##
## The *next* time Timer A underflows, it also causes a Timer B underflow (since the latter
## was set to count 2 Timer A underflows). This time, the `IRQ` pin *will* go low, and
## reading the `ICR` will produce `$83` (`10000011`). The `TA` and `TB` bits are both set,
## and the `IR` bit is also set, because the Timer B mask was set to `1` (the `TA` bit is
## set because a Timer A event happened, but the Timer B event is what actually set `IR`).
##
## Reading the `ICR` will reset its value (just its read value; the masks will remain the
## same) and reset the `IRQ` pin.
##
## ### Control Register A (`CRA`)
##
## This control register handles Timer A, the serial port, and the frequency of the TOD
## clock.
##
## =========  =========  =========  =========  =========  =========  =========  =========
## 7          6          5          4          3          2          1          0
## =========  =========  =========  =========  =========  =========  =========  =========
## `TODIN`    `SPMODE`   `INMODE`   `LOAD`     `RUNMODE`  `OUTMODE`  `PBON`     `START`
## =========  =========  =========  =========  =========  =========  =========  =========
##
## The `START` bit indicates whether Timer A is running. If it's at `0`, setting it to `1`
## is what starts the timer. If Timer Ais in one-shot mode (see `RUNMODE` below), then when
## it underflows, this bit will be automatically cleared.
##
## The `PBON` bit can be set to `1` to have Timer A send output to pin `PB6`. If this bit is
## `0` then `PB6` operates normally.
##
## The `OUTMODE` bit says what kind of output `PB6` will have if it's set to be the Timer A
## output with PBON. If this is `0`, then `PB6` will go high for one clock cycle when Timer
## A underflows. If it's `1`, then `PB6` will toggle between high and low each time Timer A
## underflows.
##
## The `RUNMODE` bit determines what happens to Timer A itself after it underflows. A `0`
## here means continuous mode, where the timer will reset and continue running. If it's `1`,
## the timer will reset after underflow but will stop (setting `START` to `0` in the
## process).
##
## The `LOAD` bit is a strobe. It is not saved (on read, this bit will always be `0`, and
## writing a `0` to it has no effect). When `CRA` is written with a `1` in this bit
## position, the contents of the shadow register for each timer register will be immediately
## loaded into its respective timer register. In this way, the timers can be reset without
## having to wait for them to underflow (which is the only other way that the contents of
## the registers are reset).
##
## The `INMODE` bit determines what Timer A actually counts. If this is `0`, Timer A counts
## pulses on the `PHI2` pin (the system clock). If this is `1`, Timer A counts pulses on the
## `CNT` pin (which has no fixed function; any external circuit can provide pulses for
## `CNT`).
##
## The `SPMODE` bit determines whether the serial port is receiving (`0`) or sending (`1`).
##
## Finally, the `TODIN` bit sets the TOD clock frequency to 60Hz (`0`) or 50Hz (`1`). This
## does not, of course, change the actual clock frequency on the TOD pin; this clock is
## supplied externally. It simply changes how the TOD clock interprets those pulses. (In
## other words, setting this to 50Hz while supplying a 60Hz external clock will make for a
## TOD clock that runs very fast.)
##
## ### Control Register B (`CRB`)
##
## This control register handles Timer B and the setting of the TOD registers.
##
## =========  =========  =========  =========  =========  =========  =========  =========
## 7          6          5          4          3          2          1          0
## =========  =========  =========  =========  =========  =========  =========  =========
## `ALARM`    `INMODE1`  `INMODE0`  `LOAD`     `RUNMODE`  `OUTMODE`  `PBON`     `START`
## =========  =========  =========  =========  =========  =========  =========  =========
##
## The lower 5 bits of this register are identical to the lower 5 bits of `CRA` except that
## they affect Timer B instead of timer A, and that `PBON` sets the behavior of pin `PB7`
## rather than `PB6`.
##
## In this register, `INMODE` takes two bits (marked `INMODE0` for the lower bit and
## `INMODE1` for the upper). This is because in addition to the two events that Timer A can
## count, Timer B can count two more.
##
## * `00`: System clock (`PHI2` pin) pulses
## * `01`: `CNT` pin pulses
## * `10`: Timer A underflows
## * `11`: Timer A underflows that happen when `CNT` is high
##
## The `ALARM` bit determines what a write to TOD registers actually does. If this is `0`,
## the TOD registers are written normally. If it's `1`, then a write to the TOD registers is
## actually setting the TOD alarm (held in unreadable shadow registers).
##
## ## Pin Interface
##
## Many of the pins have already been covered, but there's still a bit more to talk about.
##
## One important matter on pins that *have* been covered is that the parallel port pins
## `PA0`-`PA7` and `PB0`-`PB7` are internally pulled up. If nothing is connected to them or
## if no data is coming into an input pin, that pin will read as a `1` when the `PRA` or
## `PRB` registers are read.
##
## Those registers are actually physically read and written through the address pins
## `A0`-`A3` and the data pins `D0`-`D7`. The offset listed in the very first table in this
## description is what must be on the `A` pins, while the `D` pins either have the data to
## write to that register or are set to the data to be read. Whether an operation is to be a
## read or write is actually set by the `R_W` pin.
##
## `RES` resets the chip when it's held low. Resetting makes all registers go to `$00`
## (which, as a side effect, sets all parallel port pins to inputs, stops the timers, etc.)
## except for the interval timer registers, which are all set to `$FF`.
##
## Finally, there is an active low chip select pin `CS`. Most of the chip continues
## functioning (running down interval timers, keeping track of the TOD, receiving data on
## ports, etc.) at all times. The `CS` simply must be low to do a read from or a write to
## the registers.
##
## The chip comes in a 40-pin dual in-line package with the following pin assignments.
## ```
##         +-----+--+-----+
##     VSS |1    +--+   40| CNT
##     PA0 |2           39| SP
##     PA1 |3           38| A0
##     PA2 |4           37| A1
##     PA3 |5           36| A2
##     PA4 |6           35| A3
##     PA5 |7           34| RES
##     PA6 |8           33| D0
##     PA7 |9           32| D1
##     PB0 |10          31| D2
##     PB1 |11   6526   30| D3
##     PB2 |12          29| D4
##     PB3 |13          28| D5
##     PB4 |14          27| D6
##     PB5 |15          26| D7
##     PB6 |16          25| PHI2
##     PB7 |17          24| FLAG
##      PC |18          23| CS
##     TOD |19          22| R_W
##     VCC |20          21| IRQ
##         +--------------+
## ```
## Pin assignments are explained below.
##
## =====  =======  ========================================================================
## Pin    Name     Description
## =====  =======  ========================================================================
## 1      `VSS`    0V power supply (ground). Not emulated.
## 2      `PA0`    Parallel port A pin 0.
## 3      `PA1`    Parallel port A pin 1.
## 4      `PA2`    Parallel port A pin 2.
## 5      `PA3`    Parallel port A pin 3.
## 6      `PA4`    Parallel port A pin 4.
## 7      `PA5`    Parallel port A pin 5.
## 8      `PA6`    Parallel port A pin 6.
## 9      `PA7`    Parallel port A pin 7.
## 10     `PB0`    Parallel port B pin 0.
## 11     `PB1`    Parallel port B pin 1.
## 12     `PB2`    Parallel port B pin 2.
## 13     `PB3`    Parallel port B pin 3.
## 14     `PB4`    Parallel port B pin 4.
## 15     `PB5`    Parallel port B pin 5.
## 16     `PB6`    Parallel port B pin 6.
## 17     `PB7`    Parallel port B pin 7.
## 18     `PC`     Handshaking output. Goes low for a cycle when `PRB` is read or written.
## 19     `TOD`    Time-of-day clock input. Should be 50 or 60Hz.
## 20     `VCC`    +5V power supply. Not emulated.
## 21     `IRQ`    Interrupt request. Set low each time an interrupt condition is met.
## 22     `R_W`    Read (`1`) and write (`0`) control for the registers.
## 23     `CS`     Chip select. Must be low to read or write registers.
## 24     `FLAG`   Handshaking input pin. Setting low can trigger an interrupt.
## 25     `PHI2`   Clock input. Should be 1MHz; other values will affect timer accuracy.
## 26     `D7`     Data pin 7.
## 27     `D6`     Data pin 6.
## 28     `D5`     Data pin 5.
## 29     `D4`     Data pin 4.
## 30     `D3`     Data pin 3.
## 31     `D2`     Data pin 2.
## 32     `D1`     Data pin 1.
## 33     `D0`     Data pin 0.
## 34     `RES`    Reset. When this goes low, the chip resets.
## 35     `A3`     Address pin 3.
## 36     `A2`     Address pin 2.
## 37     `A1`     Address pin 1.
## 38     `A0`     Address pin 0.
## 39     `SP`     Serial port.
## 40     `CNT`    Counter. Used to potentially clock the serial port or either timer.
## =====  ======  =========================================================================
##
## In the Commodore 64, U1 and U2 are both 6526s (called CIA1 and CIA2 respectively). CIA1
## controls the keyboard and control (game) ports, along with providing an interrupt (via
## its `FLAG` pin) that fires when the cassette is ready to be read. CIA2 controls the user
## port and the serial port, along with the RESTORE key on the keyboard. It also provides
## the upper two address pins to the VIC programmatically via the kernal code. CIA2's
## interrupts are tied to the CPU's `NMI` pin rather than the regular `IRQ` pin, so they
## will be handled immediately even if the CPU is masking interrupts.
##
## Registers for CIA1 are available at addresses `$DC00` to `$DCFF`, and regisers for CIA2
## are available at addresses `$DD00` to `$DDFF`. These 256-address blocks are much more
## than is necessary for the 16 registers on each chip. The registers instead appear to
## repeat every 16 addresses; reading `$DD0C` will read the `SDR` register of CIA2, but so
## will reading `$DD1C`, `$DD2C`, etc. It's recommended to ignore this "feature" and simply
## use the base address for each register.

import sequtils
import strformat
import sugar
import ../utils
import ../components/[chip, link]

import ./ic6526/constants
export constants

chip Ic6526:
  pins:
    input:
      # Register address pins. The 6526 has 16 addressable 8-bit registers, which requires
      # four pins.
      A0: 38
      A1: 37
      A2: 36
      A3: 35

      # Parallel Port A pins. These are bidirectional but the direction is switchable via
      # register. They're held high if unconnected through an internal pull-up resistor.
      PA0: 2
      PA1: 3
      PA2: 4
      PA3: 5
      PA4: 6
      PA5: 7
      PA6: 8
      PA7: 9

      # Parallel Port B pins. These are bidirectional but the direction is switchable via
      # register. They're held high if unconnected through an internal pull-up resistor.
      PB0: 10
      PB1: 11
      PB2: 12
      PB3: 13
      PB4: 14
      PB5: 15
      PB6: 16
      PB7: 17

      # IRQ input, maskable to fire hardware interrupt. Often used for handshaking.
      FLAG: 24

      # Determines whether data is being read from (1) or written to (0) the chip.
      R_W: 22

      # Serial port. This is bidirectional but the direction is chosen by a control bit.
      SP: 39

      # Counter pin. This is used for a couple of different purposes. As an input (its
      # default state), it can provide pulses for the interval timers to count, or it can
      # be used to signal that a new bit is available to receive on the serial port. It can
      # serve as an output as well; in that case the 6526 uses it to signal to the outside
      # that an outgoing bit is ready on the serial port pin.
      CNT: 40

      # System clock input. In the 6526 this is expected to be a 1 MHz clock.
      PHI2: 25

      # TOD clock input. This can be either 50Hz or 60Hz, selectable from a control
      # register.
      TOD: 19

      # Chip select pin. When this is low, the chip allows communication with its registers
      # through the address pins and the R_W pin. When this is high, the data pins are
      # tri-stated.
      CS: 23

      # Resets the chip on a low signal.
      RES: 34

    output:
      # Data bus pins. These are input OR output pins, not both at the same time.
      D0: 33
      D1: 32
      D2: 31
      D3: 30
      D4: 29
      D5: 28
      D6: 27
      D7: 26

      # Port control pin. Pulses low after a read or write on port B. Can be used for
      # handshaking.
      PC: 18

      # Interrupt request output. When low, this signals an interrupt to the CPU. There can
      # be several sources of interrupts connected to the same CPU, so this pin will be
      # tri-stated if there is no interrupt and `0` if there is. Setting the trace that
      # connects these interrupts to pull Up will cause the trace to be high unless one or
      # more IRQ pins lower it.
      IRQ: 21

    unconnected:
      # Power supply and ground pins. Not emulated.
      VCC: 20
      VSS: 1

  registers:
    PRA: 0      # Parallel data register A
    PRB: 1      # Parallel data register B
    DDRA: 2     # Data direction register A
    DDRB: 3     # Data direction register B
    TALO: 4     # Timer A low word
    TAHI: 5     # Timer A high word
    TBLO: 6     # Timer B low word
    TBHI: 7     # Timer B high word
    TOD10TH: 8  # Time-of-day tenths of seconds
    TODSEC: 9   # Time-of-day seconds
    TODMIN: 10  # Time-of-day minutes
    TODHR: 11   # Time-of-day hours
    SDR: 12     # Serial data register
    ICR: 13     # Interrupt control register
    CRA: 14     # Control register A
    CRB: 15     # Control register B

  init:
    pins[PC].set
    for i in 0..7:
      set_pull(pins[&"PA{i}"], Up)
      set_pull(pins[&"PB{i}"], Up)

    let addr_pins = map(to_seq(0..3), i => pins[&"A{i}"])
    let data_pins = map(to_seq(0..7), i => pins[&"D{i}"])
    let pa_pins = map(to_seq(0..7), i => pins[&"PA{i}"])
    let pb_pins = map(to_seq(0..7), i => pins[&"PB{i}"])

    # A group of "shadow registers" that allow different functionality between read and
    # write on a register, as well as storage for a second value. Not every register has a
    # latch associated, but notably latches are where the timers keep their reset values,
    # the TOD clock keeps its alarm setting, and the ICR keeps its mask for determining
    # which interrupts are enabled.
    var latches: array[16, uint8]

    include ./ic6526/ports
    include ./ic6526/timers
    include ./ic6526/tod
    include ./ic6526/control

    # Returns the value in the indexed register. While most registers are simply indexed as
    # any array would be, there are some that have additional functionality when read (for
    # example, reading the ICR register also clears it).
    proc read_register(index: int): uint8 =
      case index
      of PRB: read_prb()
      of TOD10TH: read_tenths()
      of TODHR: read_hours()
      of ICR: read_icr()
      else: registers[index]

    # Writes a value to one of the registers. Each register has some kind of functionality
    # in addition to simply writing the value; this proc calls the special proc needed to
    # make that happen.
    proc write_register(index: int, value: uint8) =
      case index
      of PRA: write_pra(value)
      of PRB: write_prb(value)
      of DDRA: write_ddra(value)
      of DDRB: write_ddrb(value)
      of TALO, TAHI, TBLO, TBHI: latches[index] = value
      of TOD10TH: write_tenths(value)
      of TODSEC: write_seconds(value)
      of TODMIN: write_minutes(value)
      of TODHR: write_hours(value)
      of SDR: write_sdr(value)
      of ICR: write_icr(value)
      of CRA: write_cra(value)
      of CRB: write_crb(value)
      else: registers[index] = value

    # This is the result of a reset according to the specs of the device. The kernal is
    # repsonsible for setting up actual operation. For example, it's well known that the
    # "default" state of the DDR on CIA 1 is all outputs for port A and all inputs for port
    # B; only in this way can the keyboard be scanned. However, the hardware reset sets both
    # ports to all inputs; the kernal routine starting at $FDA5 actually sets port A to be
    # all outputs.
    #
    # This function does the following:
    # 1. Sets interval timer registers to max ($FF each)
    # 2. Clears all other registers ($00 each) *
    # 3. Clears the IRQ mask in the ICR latch
    # 4. Disconnects all data lines
    # 5. Sets SP and CNT as inputs
    # 6. Resets IRQ and PC outputs to their default values
    #
    # * Note that pins PA0-PA7 and PB0-PB7 are pulled up by internal resistors, which is
    #   emulated, so the PCR registers will read all 1's for unconnected lines on reset.
    proc reset =
      # Backwards order to hit control registers first, so we know we're setting the TOD
      # clock later and not the TOD alarm, and also to ensure hours gets hit before tenths
      # so we know the clock hasn't halted
      for i in countdown(15, 0):
        # Timer latches get all 1's; ICR mask gets all flags reset; all others get all 0's
        let value = if i >= TALO and i <= TBHI: 0xffu8 elif i == ICR: 0x7fu8 else: 0x00u8
        write_register(i, value)
      # Read ICR to clear all IRQ flags and release the IRQ line
      discard read_register(ICR)

      # Force latched timer values into the timer registers. Also set CRB to write to TOD
      # alarm so we can zero that next.
      write_register(CRA, 1u8 shl LOAD)
      write_register(CRB, (1u8 shl ALARM or 1u8 shl LOAD))
      # Write zeros to the TOD alarm
      write_register(TODHR, 0)
      write_register(TODMIN, 0)
      write_register(TODSEC, 0)
      write_register(TOD10TH, 0)
      # Clear out any values we've put into the control registers
      write_register(CRA, 0)
      write_register(CRB, 0)

      # Set output pins to their default modes and values. IRQ is already reset by reading
      # the ICR above.
      mode_to_pins(Output, data_pins)
      tri_pins(data_pins)
      set_mode(pins[CNT], Input)
      set_mode(pins[SP], Input)
      set(pins[PC])

      # Call other reset procs to reset local state
      timer_reset()
      tod_reset()

    # Reads and writes between the data bus and the registers only happens on translation of
    # CS from high to low.
    add_listener(pins[CS], proc (pin: Pin) =
      if highp(pin):
        mode_to_pins(Output, data_pins)
        tri_pins(data_pins)
      elif lowp(pin):
        let index = pins_to_value(addr_pins)
        if highp(pins[R_W]):
          value_to_pins(read_register(int(index)), data_pins)
        elif lowp(pins[R_W]):
          mode_to_pins(Input, data_pins)
          write_register(int(index), uint8(pins_to_value(data_pins))))

    # FLAG handling. Lowering this pin sets the appropriate bit in the ICR and fires an
    # interrupt if that bit is enabled by the ICR mask. This is potentially useful for
    # handshaking with another 6526 by receiving its PC output on this pin.
    add_listener(pins[FLAG], proc (pin: Pin) =
      if lowp(pin):
        registers[ICR] = set_bit(registers[ICR], FLG)
        if bit_set(latches[ICR], FLG):
          registers[ICR] = set_bit(registers[ICR], IR)
          clear(pins[IRQ]))

    # Reset the chip when the reset pin goes low.
    add_listener(pins[RES], proc (pin: Pin) =
      if lowp(pin): reset())

    # initial values of all registers are the same as a reset
    reset()
