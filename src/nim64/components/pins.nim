# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import sequtils
import tables
import ./link

type
  Pins* = ref object
    ## A collection of pins that is easily looked up either by pin number or by pin name.
    ## When indexed by number, that number is 1-based (there is no 0-pin). When indexed by
    ## name, the name is case-sensitive.
    ##
    ## There is no index-assignment operator implemented for this collection of pins. The
    ## pins themselves returned by either the indexing functions or the iterators are
    ## themselves able to be modified in multiple ways (level, mode, etc.) and with
    ## specialized functions (`set`, `clear`, etc.); assigning a new value by operator would
    ## be both less powerful and more ambiguous.
    by_number: seq[Pin]             ## The pins stored by numerical index.
    by_name: TableRef[string, Pin]  ## The pins stored by string index.

  PinInfo* = tuple
    ## Read-only information about a single pin.
    number: int   ## The pin's number.
    name: string  ## The pin's name.
    level: float  ## The pin's current level.
    mode: Mode    ## The pin's current mode.
    pull: Pull    ## The pin's current pull setting.

proc new_pins*(pins: varargs[Pin]): Pins =
  ## Creates a new collection of pins. All of the pins intended for the collection must be
  ## provided to this constructor proc; there is no facility to add pins later.
  ##
  ## The provided pins must also not skip any pin numbers starting with 1 and extending to
  ## the number of pins provided. By corollary it can also not duplicate any pin numbers.
  ## In either case, an `IndexDefect` is raised.
  var pin_seq: seq[Pin]
  new_seq(pin_seq, len(pins))
  var pin_table = new_table[string, Pin]()

  for i in 1..len(pins):
    let matching = filter(pins, proc (p: Pin): bool = number(p) == i)
    if len(matching) == 0: raise new_exception(IndexDefect, "Missing pin number " & $i)
    if len(matching) > 1: raise new_exception(IndexDefect, "Duplicate pin number " & $i)

    let pin = matching[0]
    pin_seq[pred(number(pin))] = pin
    pin_table[name(pin)] = pin

  Pins(by_number: pin_seq, by_name: pin_table)

proc `[]`*(pins: Pins, index: int): Pin =
  ## Looks up a pin in the collection by pin number.
  pins.by_number[pred(index)]

proc `[]`*(pins: Pins, index: string): Pin =
  ## Looks up a pin in the collection by name. This name is case-sensitive.
  pins.by_name[index]

iterator items*(pins: Pins): Pin =
  ## Iterates over the pins in the collection. The iteration order is by pin number.
  for pin in pins.by_number:
    yield pin

iterator pairs*(pins: Pins): (int, Pin) =
  ## Iterates over the pins in the collection, returning both the pin number and the pin
  ## itself. As with pin numbers, the first "index" returned is 1, not 0.
  for pin in pins.by_number:
    yield (number(pin), pin)

proc len*(pins: Pins): int =
  ## Returns the number of pins in the collection.
  len(pins.by_number)

proc info*(pins: Pins): seq[PinInfo] =
  ## Returns a read-only view of the pins in the collection.
  map(pins.by_number, proc (pin: Pin): PinInfo =
    (number(pin), name(pin), level(pin), mode(pin), pull(pin)))
