# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https:#opensource.org/licenses/MIT

## Implementations of pins and traces, which represent the entities that chips in a computer
## use to communicate with each other. The pins represent the sole interface of a chip or a
## port with the world outside, while the traces represent the printed copper lines on a
## circuit board that connect pins of one device to another.
## 
## The module takes its name from the fact that these two components are used to link chips
## and ports. "Interface" would have been preferred but that's a reserved Nim keyword.
## (Today I learned.)
## 
## These two types are implemented in the same file because the two of them are intimately
## linked. For one, they're mutually recursive; a `Pin` has a reference to a `Trace`, while
## a `Trace` has references to all of the `Pin`s that have references to it. Additionally,
## traces and pins are updated slightly differently if its a connected pin/trace doing it,
## and putting the two types together allow each of them to call updating functions that do
## not then have to be exported.
## 
## *(Since this is the first file written in this project, there is some additional
## flexibilty mixed in. Each pin or trace can be set or cleared with the function syntax 
## (`set(pin)`), the method syntax (`pin.set` or `pin.set()`), or an operator syntax 
## (`+pin`). Which syntax will be used in the rest of the project is unknown at the time of 
## writing.)*
## 
## A few days down the road and I've made up my mind. First of all, I felt the operators
## just added noise and weren't clear in purpose, which is the hallmark of a frivolously
## added operator. So I removed them. I also decided that the coding style for this project
## is going to be...function syntax with no parentheses. This is appealing for speed of
## typing and just for the way it reads. Note that I will use parentheses to group function
## calls, but in a Haskell-y way: 
## 
## ```nim
## # an example that became an accidental NOR gate
## 
## # this way is wrong; it doesn't know how to group nots and function calls
## if not highp apin and not highp bpin: set ypin else: clear ypin
## 
## # so you could do it this way instead
## if not highp(apin) and not highp(bpin): set ypin else: clear ypin
## 
## # but I prefer it this way
## if not (highp apin) and not (highp bpin): set ypin else: clear ypin
## ```
## 
## Speaking of that, what's with the `p` ending all those functions? Well, I have *never*
## liked the `isSomething` syntax for predicate functions (functions which take one argument
## and return a bool). In any language. It's ugly and it takes 3-4 extra keystrokes just to
## say that it's a predicate. I do think it's important to be able to see that something's a
## predicate at a glance, especially when those predicates are mixed in with other single-
## argument functions that are not, like in the example above with `set` and `clear`, but
## `is` (or worse, `get`) just isn't the way I want to do it.
## 
## There are languages where `?` is a legal character (Lisp allows it, and Ruby allows it
## as long as it's the last character in an identifier), and I think that's a fantastic way
## to mark a predicate. But that method isn't available in Nim. So I have hearkened back to
## the days of Lisp, where function names would be postfixed with `p` to indicate that
## they're predicates. Not as good as `?`, but a lot better than `is`.
## 
## (The question of why Lisp used `p` when it *could* have used `?` is a good one that I
## don't know the answer to. Probably something to do with the leyboards they were using in
## 1958.)
## 
## Every exported mutation function in this module is chainable (they all return a `Pin` or
## a `Trace` as appropriate, and all of them are discardable). This is meant to make it more
## concise to set up a new instance; you can do something like this to create a new `Pin`
## with all of its properties already set.
## ```
## let pin = newPin(1, "A", Output).set().pullUp().addListener(listener)
## ```
## For the sake of completeness, chaining was even added to `name=` functions and operators,
## so you *could* do `(pin.mode = Output).set()` if you really wanted to. But if you need to
## do that, just use `setMode(pin, Output).set()`.

from math import classify, fcNan
from sequtils import filter, keepIf
from sugar import `->`, `=>`

type
  Mode* = enum
    ## The direction in which levels are propagated through the pin.
    Unconnected ## No levels are propagated in either direction.
    Input       ## Levels will propagate from a trace to the pin, but not vice versa.
    Output      ## Levels will propagate from the pin to a trace, but not vice versa.
    Bidi        ## Levels will propagate both from the pin to a trace and vice versa.
  
  Pull = enum
    ## Optionally sets the level of a pin or trace that has no level set (that level is 
    ## NaN). This simulates the effect of pull-up and pull-down resistors.
    Off   ## The level of a level-NaN pin or trace will remain NaN.
    Up    ## The level of a level-NaN pin or trace will instead be set to 1.0.
    Down  ## The level of a level-NaN pin or trace will instead be set to 0.0.
  
  Pin* = ref object
    ## A pin on an IC package or a port.
    ##
    ## This is the sole interface between these devices and the outside world. Pins have a
    ## mode, which indicates whether they're used by their chip/port for input, output, 
    ## both, or neither; and a level, which is the signal present on them. In digital 
    ## circuits, this is generally 0 or 1, though there's no reason a pin can't work with 
    ## analog signals (and thus have any level at all).
    ## 
    ## These pins are tri-state capable, meaning that at least digitally speaking, they have
    ## three potential levels: high (1), low (0), and tri-state (Z). The last is a high-
    ## impedence state that generally means that the pin isn't contributing to its circuit
    ## at all, as though it's switched off. If a pin is in tri-state, it will have a level
    ## of `NaN`.
    ##
    ## Pins may also be pulled up or down, which defines what level they have if a level
    ## isn't given to them (they're tri-stated). This emulates the internal pull-ups and 
    ## pull-downs that some chips have (such as the port pins on a 6526 CIA).
    ##
    ## Pins and traces are intimately linked, which is why both are defined in this file. A
    ## pin can be associated with exactly one trace, and unless the pin's level is `NaN` and
    ## it is an output pin, the pin and the trace will have the same level. (It follows then
    ## that all of the other pins connected to that trace will also have that level.) If
    ## their levels do not match, then one is changed to match the other. If the pin is an
    ## output pin, it will define the mutual level. If it's an input pin, the trace will
    ## define the level. If the pin is bidirectional, the level will be the level of the
    ## trace if it is connected to other non-bidirectional, non-null output pins; otherwise,
    ## whatever was set last will prevail.
    ##
    ## A pin may also have one or more listeners registered to it. The listener(s) will be
    ## invoked if the level of the pin changes *because of a change to its trace's level.* 
    ## No listener will be invoked if the level of the pin is merely set programmatically. 
    ## This means that only input and bidirectional pins will invoke listeners, though 
    ## output pins may also register them, since it is possible that the output pin will 
    ## become a different kind of pin later.
    number: int                 ## The pin number. This is normally defined in chip or port 
                                ## literature.
    name: string                ## The pin name. Again, this is normally defined in chip or 
                                ## port literature.
    trace: Trace                ## The trace to which this pin is connected. Will be `nil` 
                                ## if the pin has not been connected to a trace. Once a 
                                ## trace has been connected, there is no way to disconnect
                                ## it (physical pins don't generally change their traces
                                ## either).
    mode: Mode                  ## The mode of the pin, a description of which direction 
                                ## data is propagating through it.
    pull: Pull                  ## The level that the pin will take if its level is set to 
                                ## `NaN`. This value is set by `pullUp`, `pullDown`, and
                                ## `pullOff`
    level: float                ## The level of the pin. If the pin has no level (i.e., it's
                                ## disconnected or in a hi-Z state), this will be `NaN`.
    listeners: seq[Pin -> void] ## A list of listener functions that get invoked, in order,
                                ## when the pin's level is changed by its connected trace.
    connected: bool             ## Whether or not the pin has a connected trace.
  
  Trace* = ref object
    ## A printed-circuit board trace that connects two or more pins.
    ##
    ## A trace is designed primarily to have its level modified by a connected output pin.
    ## However, the level can also be set directly (this is often useful in testing and
    ## debugging). When a trace's level is set directly, its actual value is chosen 
    ## according to the following rules:
    ##
    ## 1. If the trace has at least one output pin connected to it that has a level, the
    ##    trace takes on the maximum level among all of its connected output pins.
    ## 2. If the value being set is `NaN`: a. If the trace has been pulled up, its value is
    ##    1.0. b. If the trace has been pulled down, its value is 0.0. c. Its value is
    ##    `NaN`.
    ## 3. The trace takes on the set value.
    ## 
    ## The `NaN` means a little something different with a trace; on a pin, it refers to a
    ## tri-state (a high impedence state where the pin isn't driving its trace); with a 
    ## trace it just means that no level has been set. The procs that deal with this are
    ## still named after the tri state (`tri` and `trip`) because that finer point doesn't
    ## mean much most of the time.
    ##
    ## If a trace is set by a pin (either by an output pin changing values or by an
    ## unconnected pin mode-changing into an output pin), then the value is simply set
    ## *unless* the value it's being set to is `NaN`. In that case the same rules as direct
    ## setting apply.
    ##
    ## A change in the level of the trace will be propagated to any input pins connected to
    ## the trace. When this happens, the observers of all of those input pins are notified
    ##  of the change.
    pins: seq[Pin]  ## A list of all of the pins that are connected to this trace.
    pull: Pull      ## The level that the trace will take if its level is set to `NaN` and 
                    ## there are no output pins with levels that will override this. This
                    ## value is set by `pullUp`, `pullDown`, and `pullOff`.
    level: float    ## The level of the trace. If the trace has no level (i.e., it has no 
                    ## output pins with levels and has had its own level set to `NaN`), this
                    ## will be `NaN`.


proc isNaN(n: float): bool {.inline.} =
  ## Utility function to determine whether a float is `NaN`. This is used in place of
  ## comparisons since `NaN != NaN`.
  n.classify == fcNaN

proc equal(a, b: float): bool {.inline.} =
  ## Equality, but with NaN equaling itself. Necessary to prevent infinite loops in places
  ## where pins only update if their level changes (without this, NaN "changing" to NaN will
  ## trigger an update).
  result = (a.isNaN and b.isNaN) or (a == b)

proc inputp*(mode: Mode): bool {.inline.} =
  ## Determines whether a mode is an input mode; i.e., whether it is `Input` or `Bidi`.
  mode == Input or mode == Bidi

proc outputp*(mode: Mode): bool {.inline.} =
  ## Determines whether a mode is an output mode; i.e., whether it's `Output` or `Bidi`.
  mode == Output or mode == Bidi

proc toLevel(pull: Pull): float =
  ## Translates a `Pull` value into a level that is used by the pin or trace with that 
  ## `Pull` value if it doesn't have a different value set.
  case pull
  of Off: NaN
  of Up: 1.0
  of Down: 0.0

proc number*(pin: Pin): int {.inline.} =
  ## The pin's number. This is the physical location of a pin on its chip's package.
  pin.number

proc name*(pin: Pin): string =
  ## The pin's name. This is generally provided by the device's literature.
  pin.name

proc highp*(pin: Pin): bool {.inline.} =
  ## Determines whether the pin is high. While this generally means a value of 1, any value
  ## of 0.5 or higher will be considered "high".
  pin.level >= 0.5

proc lowp*(pin: Pin): bool {.inline.} =
  ## Determines whether the pin is low. While this generally means a value of 0, any value
  ## less than 0.5 will be considered "low".
  pin.level < 0.5

proc trip*(pin: Pin): bool {.inline.} =
  ## Determines whether the pin's level is tri-state. This is represented by a value of 
  ## `NaN` and indicates that a pin is not connected to (and influencing the level of) its 
  ## trace.
  pin.level.isNaN

proc highp*(trace: Trace): bool {.inline.} =
  ## Determines whether the trace is high. While this generally means a value of 1, any 
  ## value of 0.5 or higher will be considered "high"
  trace.level >= 0.5

proc lowp*(trace: Trace): bool {.inline.} =
  ## Determines whether the trace is low. While this generally means a value of 0, any value
  ## less than 0.5 will be considered "low".
  trace.level < 0.5

proc trip*(trace: Trace): bool {.inline.} =
  ## Determines whether the pin's level is tri-state. This is represented by a value of 
  ## `NaN` and indicates that a trace has no level at all because no output pins are driving 
  ## it.
  trace.level.isNaN

proc normalize(pin: Pin, level: float): float =
  ## Normalizes a level by accounting for the pin's pull state if that level is `NaN`.
  if level.isNaN: pin.pull.toLevel() else: level

proc update(pin: Pin) =
  ## Updates the level of a pin to its trace's level. This should only be called by the 
  ## pin's connected trace, and this represents the biggest reason why `Pin` and `Trace` 
  ## are defined in the same file (so that a trace has access to this function even though 
  ## it's not exported). This will update the pin's level, taking pull into account if the 
  ## trace has an `NaN` value. If the pin's value changes as a result of this function call,
  ## its listeners will be invoked.
  if pin.connected:
    let normalized = pin.normalize(pin.trace.level)
    if not equal(pin.level, normalized) and pin.mode.inputp:
      pin.level = normalized
      for listener in pin.listeners: listener(pin)

proc calculate(trace: Trace, level: float): float =
  ## Calculates a new level for the trace. While a level is provided to this function, it's
  ## easily overridden. If there is at least one connected output trace with a level, the
  ## highest of those levels will be chosen instead. Otherwise, if the trace has a pull,
  ## that value will become the new value. Only if neither of these situations are true will
  ## the provided level actually take effect.
  let outputs = trace.pins.filter(pin => pin.mode == Output)
  if outputs.len > 0:
    var max = -Inf
    for output in outputs:
      if output.level > max:
        max = output.level
    if max > -Inf:
      return max
  
  if level.isNaN:
    return trace.pull.toLevel

  return level

proc update(trace: Trace, level: float) =
  ## Updates the level of the trace to the provided level. This function currently
  ## duplicates `setLevel` for traces. It's here because historically, setting a trace with
  ## pins was different than setting it directly (a pin could override a trace's value even
  ## if there were other output pins connected to it that had higher levels) and because I
  ## want to keep it here if I find that the new way (highest output pin level wins) doesn't
  ## work for some reason.
  #trace.level = if level.isNaN: trace.calculate(level) else: level
  trace.level = trace.calculate(level)
  for pin in trace.pins: pin.update()

proc setLevel*(pin: Pin, level: float): Pin {.discardable.} =
  ## Sets the pin's level. This will have no effect if the pin's mode is `Input` and if the 
  ## pin is connected to a trace. Otherwise, any connected trace is also updated with the 
  ## new level.
  result = pin
  if pin.connected:
    if pin.mode != Input:
      pin.level = pin.normalize(level)
      if pin.mode != Unconnected:
        pin.trace.update(pin.level)
  else:
    pin.level = pin.normalize(level)

proc setLevel*(trace: Trace, level: float): Trace {.discardable.} =
  ## Sets the trace's level. This setting will be overidden if the trace has other output
  ## pins connected to it or if it has been pulled up or down.
  result = trace
  trace.level = trace.calculate(level)
  for pin in trace.pins: pin.update()

proc level*(pin: Pin): float =
  ## Returns the pin's current level.
  pin.level

proc `level=`*(pin: Pin, level: float): Pin {.discardable.} =
  ## Sets the pin's level. This will have no effect if the pin's mode is `Input` and if the 
  ## pin is connected to a trace. Otherwise, any connected trace is also updated with the 
  ## new level.
  pin.setLevel(level)

proc level*(trace: Trace): float =
  ## Returns the trace's current level.
  trace.level

proc `level=`*(trace: Trace, level: float): Trace {.discardable.} =
  ## Sets the trace's level. This setting will be overidden if the trace has other output
  ## pins connected to it or if it has been pulled up or down.
  trace.setLevel(level)

proc set*(pin: Pin): Pin {.discardable, inline.} =
  ## Sets the pin's level to 1. This will have no effect if the pin's mode is `Input` and if
  ## the pin is connected to a trace.
  result = pin
  pin.setLevel(1.0)

proc clear*(pin: Pin): Pin {.discardable, inline.} =
  ## Sets the pin's level to 0. This will have no effect if the pin's mode is `Input` and if
  ## the pin is connected to a trace.
  result = pin
  pin.setLevel(0.0)

proc tri*(pin: Pin): Pin {.discardable, inline.} =
  ## Sets the pin's level to `NaN`, tri-stating it. This will have no effect if the pin's 
  ## mode is `Input` and if the pin is connected to a trace. If the pin has been pulled up 
  ## or down, it will take on the level associated with that pull instead.
  result = pin
  pin.setLevel(NaN)

proc set*(trace: Trace): Trace {.discardable, inline.} =
  ## Sets the trace's value to 1. This will only have an effect if no higher-leveled output
  ## pins are connected to the trace.
  result = trace
  trace.setLevel(1.0)

proc clear*(trace: Trace): Trace {.discardable, inline.} =
  ## Sets the trace's value to 0. This will only have an effect if no higher-leveled output
  ## pins are connected to the trace.
  result = trace
  trace.setLevel(0.0)

proc tri*(trace: Trace): Trace {.discardable, inline.} =
  ## Sets the trace's value to `NaN`, which represents no level at all. This will only have 
  ## an effect if no leveled output pins are connected to the trace.
  result = trace
  trace.setLevel(NaN)

proc toggle*(pin: Pin): Pin {.discardable.} =
  ## Toggles the pin's level. This will treat that level as digital; if it is "high" (0.5 or
  ## over), the pin will be set to 0, and if it's "low" (less than 0.5), the pin will be set
  ## to 1. This has no effect on pins with `NaN` levels.
  result = pin
  if pin.highp: clear(pin)
  elif pin.lowp: set(pin)

proc setMode*(pin: Pin, mode: Mode): Pin {.discardable.} =
  ## Sets the pin's mode. This will also account for the values that the pin and its
  ## connected trace might take on because of the new mode.
  result = pin

  let oldMode = pin.mode
  let oldLevel = pin.level
  pin.mode = mode

  if pin.connected:
    if mode.outputp:
      pin.trace.update(pin.level)
    else:
      if mode == Input:
        pin.level = pin.normalize(pin.trace.level)
      if oldMode.outputp and not oldLevel.isNaN:
        pin.trace.update(NaN)

proc mode*(pin: Pin): Mode =
  ## Returns the pin's current mode.
  pin.mode

proc `mode=`*(pin: Pin, mode: Mode): Pin {.discardable.} =
  ## Sets the pin's mode. This will also account for the values that the pin and its
  ## connected trace might take on because of the new mode.
  result = pin
  pin.setMode(mode)

proc inputp*(pin: Pin): bool =
  ## Determines whether the pin is in an input mode; i.e., whether it is `Input` or `Bidi`.
  pin.mode.inputp

proc outputp*(pin: Pin): bool =
  ## Determines whether the pin is in an output mode; i.e., whether it is `Output` or 
  ## `Bidi`.
  pin.mode.outputp

proc addListener*(pin: Pin, listener: Pin -> void): Pin {.discardable.} =
  ## Adds a new listener function to the list of listeners that the pin will call when its
  ## trace updates it. If the function is already in the list, it will not be added a second
  ## time.
  result = pin
  if listener notin pin.listeners: pin.listeners.add(listener)

proc removeListener*(pin: Pin, listener: Pin -> void): Pin {.discardable.} =
  ## Removes the provided listener function from the list of listeners that the pin will
  ## call when its trace updates it. If the listener is already not in this list, this
  ## function will do noting.
  result = pin
  pin.listeners.keepIf(l => l != listener)

proc pullUp*(pin: Pin): Pin {.discardable.} =
  ## Sets the pin to be pulled up. This pin will then take on a level of 1 any time its
  ## level is set to `NaN`.
  result = pin
  pin.pull = Up
  pin.level = pin.normalize(pin.level)

proc pullDown*(pin: Pin): Pin {.discardable.} =
  ## Sets the pin to be pulled down. This pin will then take on a level of 0 any time its
  ## level is set to `NaN`.
  result = pin
  pin.pull = Down
  pin.level = pin.normalize(pin.level)

proc pullOff*(pin: Pin): Pin {.discardable.} =
  ## Removes any pull status from the pin. The pin will then take on a level of `NaN` if
  ## it is set to that level.
  result = pin
  pin.pull = Off
  pin.level = pin.normalize(pin.level)

proc pullUp*(trace: Trace): Trace {.discardable.} =
  ## Sets the trace to be pulled up. This trace will then take on a level of 1 any time its
  ## level is set to `NaN`.
  result = trace
  trace.pull = Up
  trace.update(trace.level)

proc pullDown*(trace: Trace): Trace {.discardable.} =
  ## Sets the trace to be pulled down. This trace will then take on a level of 0 any time 
  ## its level is set to `NaN`.
  result = trace
  trace.pull = Down
  trace.update(trace.level)

proc pullOff*(trace: Trace): Trace {.discardable.} =
  ## Removes any pull status from the trace. The trace will then take on a level of `NaN` if
  ## it is set to that level.
  result = trace
  trace.pull = Off
  trace.update(trace.level)

proc setTrace(pin: Pin, trace: Trace) =
  ## Assigns the trace to the pin. This can only be done once; after a trace is set, that
  ## trace cannot be removed or changed.
  if not pin.connected:
    pin.trace = trace
    pin.connected = true
    if pin.mode == Input or pin.mode == Bidi and pin.level.isNaN:
      pin.level = trace.level
    elif pin.mode.outputp:
      trace.update(NaN)

proc addPin*(trace: Trace, pin: Pin): Trace {.discardable.} =
  ## Adds a pin to the ones connected by the trace. If the pin is already connected to a
  ## trace (including to this one), this function will do nothing.
  result = trace
  if not pin.connected:
    trace.pins.add(pin)
    pin.setTrace(trace)

proc addPins*(trace: Trace, pins: varargs[Pin]): Trace {.discardable.} =
  ## Adds one or more pins to the ones connected by the trace. If any of these pins is
  ## already connected to a trace (including this one), the add will not happen for that
  ## pin.
  result = trace
  for pin in pins: trace.addPin(pin)

proc newPin*(number: int, name: string, mode: Mode = Unconnected): Pin =
  ## Creates a new `Pin`. This pin will start with a level of `NaN` and no pull.
  result = Pin(
    number: number,
    name: name,
    pull: Off,
    level: NaN,
    trace: nil,
    listeners: @[],
    connected: false,
  )
  result.setMode(mode)

proc newTrace*(pins: varargs[Pin]): Trace =
  ## Creates a new `Trace` from a sequence of the pins that should be connected to the new
  ## trace. This trace will start with no pull and a level defined by the output pins in
  ## the pin sequence.
  result = Trace(
    pins: @[],
    pull: Off,
  )
  result.addPins(pins)
  result.update(NaN)
