# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import tables
import macros
import sequtils
import options
import ./link

type PinRepr = tuple
  ## A tuple of the information that can be gleaned about a pin from the macro input. This 
  ## is simply the number, name, and mode, which are what's necessary to construct a pin. 
  ## The mode is kept as a `NimNode` because it immediately has `bindSym` applied to it; it 
  ## makes things easier in the end, and unlike name and number, there is no use for the 
  ## mode other than writing it into the constructor function.

  number: int
  name: string
  mode: NimNode

proc parsePin(node: NimNode): (int, string) =
  ## Takes an AST node and parses it for information about a single pin. This is well inside
  ## a mode block, so the only things it can gather are number and name. This is called once
  ## per pin by `parsePins` below.

  let name = node[0].strVal
  var number: int = 0

  if node[1][0].kind == nnkIntLit:
    number = cast[int](node[1][0].intVal)
  else:
    error("Pin number must be an integer", node)
  
  result = (number, name)

proc parsePins(pinsSection: NimNode): seq[PinRepr] =
  ## Takes the AST of the full pin section and parses it, returning information about all
  ## pins. Since at this level the mode blocks are still visible, this proc can and does
  ## include mode information as well.

  var inputSection = none(NimNode)
  var outputSection = none(NimNode)
  var bidiSection = none(NimNode)
  var unconnectedSection = none(NimNode)

  for node in pinsSection.children():
    if node.kind == nnkCall:
      let ident = node[0].strVal
      case ident
      of "input": inputSection = some(node[1])
      of "output": outputSection = some(node[1])
      of "bidi": bidiSection = some(node[1])
      of "unconnected": unconnectedSection = some(node[1])
      else: error("Unknown pin type: " & ident, node)
  
  if inputSection.isSome:
    for stmtNode in inputSection.get().children():
      let (number, name) = parsePin(stmtNode)
      result.add((number, name, bindSym("Input")))

  if outputSection.isSome:
    for stmtNode in outputSection.get().children():
      let (number, name) = parsePin(stmtNode)
      result.add((number, name, bindSym("Output")))
  
  if bidiSection.isSome:
    for stmtNode in bidiSection.get().children():
      let (number, name) = parsePin(stmtNode)
      result.add((number, name, bindSym("Bidi")))
  
  if unconnectedSection.isSome:
    for stmtNode in unconnectedSection.get().children():
      let (number, name) = parsePin(stmtNode)
      result.add((number, name, bindSym("Unconnected")))

proc prelude(chipType, pinsType: NimNode, numPins: int): NimNode =
  ## Produces the AST for the first part of the macro output. This includes types and the
  ## procs that are attached to those types (indexing and iterators).

  let brackets = newTree(nnkAccQuoted, ident("[]"))
  let pinSym = bindSym("Pin")
  let tableSym = bindSym("TableRef")

  # This produces a full type (the pins type) that is not exported with indexing and
  # iteration capabilities that are also not exported (though the procs and iterators
  # attached to the chip itself *are* exported and do the same thing). These are created
  # just to be available with the `pins` variable in the `init` block.
  result = quote do:
    type 
      `pinsType` = ref object
        byNumber: array[1..`numPins`, `pinSym`]
        byName: `tableSym`[string, `pinSym`]
      `chipType`* = ref object
        pins: `pinsType`

    proc `brackets`(pins: `pinsType`, index: int): `pinSym` {.inline.} = pins.byNumber[index]
    proc `brackets`(pins: `pinsType`, index: string): `pinSym` {.inline.} = pins.byName[index]
    iterator items*(pins: `pinsType`): `pinSym` =
      for pin in pins.byNumber:
        yield pin
    iterator pairs*(pins: `pinsType`): tuple[a: int, b: `pinSym`] =
      for i, pin in pins.byNumber:
        yield (i, pin)

    proc `brackets`*(chip: `chipType`, index: int): `pinSym` {.inline.} = chip.pins[index]
    proc `brackets`*(chip: `chipType`, index: string): `pinSym` {.inline.} = chip.pins[index]
    iterator items*(chip: `chipType`): `pinSym` =
      for pin in chip.pins.byNumber:
        yield pin
    iterator pairs*(chip: `chipType`): tuple[a: int, b: `pinSym`] =
      for i, pin in chip.pins.byNumber:
        yield (i, pin)

proc constants(pins: seq[PinRepr]): NimNode {.compileTime.} =
  ## Produces the AST for the second part of the macro output. This includes constants based
  ## on the names and numbers of the pins in the macro input.

  result = newNimNode(nnkConstSection)

  for pin in pins:
    let node = newTree(nnkConstDef,
      newTree(nnkPostfix,
        ident("*"),
        ident(pin.name),
      ),
      newEmptyNode(),
      newIntLitNode(pin.number),
    )
    result.add(node)

proc init(chipType, pinsType, initSection: NimNode, pins: seq[PinRepr]): NimNode =
  ## Produces the AST for the third part of the macro output. This is the constructor proc
  ## that will create a new instance of the chip once the type is defined.

  let procName = ident("new" & chipType.strVal)
  let newTableSym = bindSym("newTable")
  let pinSym = bindSym("Pin")
  let mapSym = bindSym("map")
  let zipSym = bindSym("zip")

  let pinsLen = pins.len
  let pinsIdent = ident("pins")

  # There is one part missing from this quote: `rawPins` is an empty array. We'll fix that
  # in a bit.
  result = quote do:
    proc `procName`*: `chipType` =
      let 
        rawPins: array[1..`pinsLen`, `pinSym`] = []
        table = `newTableSym`[string, `pinSym`]()
        names = rawPins.`mapSym`(proc (pin: `pinSym`): string = pin.name)
      
      for pairs in `zipSym`(names, rawPins):
        let (name, pin) = pairs
        table[name] = pin
      
      let `pinsIdent` = `pinsType`(byNumber: rawPins, byName: table)
      result = `chipType`(pins: `pinsIdent`)
  
  # This is the node for the brackets in `rawPins = []`. We use it as an attachment point
  # for the nodes that make up the entries in that array. We're basically returning to a
  # node we already created to insert some more stuff into it, which is of course fine
  # because it's still compile time when this is running.
  let brackets = result[6][0][0][2] # !

  # Run through the pins sequence by pin number, not by index. This ensures that the array
  # elements are produced in the proper order no matter the order in the macro input.
  for i in 1..pins.len:
    let filtered = pins.filter(proc (pin: PinRepr): bool = pin.number == i)
    if filtered.len == 0:
      error("Missing pin number " & $i)
    elif filtered.len > 1:
      error("Duplicate pin number " & $i)
    
    let pin = filtered[0]
    brackets.add(newCall(
      bindSym("newPin"),
      newIntLitNode(pin.number),
      newStrLitNode(pin.name),
      pin.mode
    ))
  
  result[6].add(initSection)

macro chip*(name, body: untyped): untyped =
  ## A macro to produce a full definition of a chip from declarative parts.
  ## 
  ## The macro takes the form of a block definition, with other blocks inside of it. The 
  ## name of the new chip must be included before the first block begins, right after the
  ## `chip` identifier:
  ## 
  ##     chip Ic7406:
  ## 
  ## Inside this `chip` block there can be two others.
  ## 
  ## The `pins` block is *required*. It provides all of the information that the macro needs
  ## to produce the chip's pins. These pins are separated into blocks named after the four
  ## modes: `input`, `output`, `bidi`, and `unconnected`. There can only be one instance of
  ## a given block; later blocks with the same name will overwrite the first one, which is
  ## not something you want.
  ## 
  ## Within each mode block are the pin definitions, which are exceedingly simple: they are
  ## the name of the pin, followed by a colon, followed by the number of that pin.
  ## 
  ## It is important that the pin numbers are complete and unique. The smallest pin number
  ## must be 1, and the largest must be the same as the number of total pins. If any pins
  ## are missing in the sequence, or if the same number is used by more than one pin, an
  ## error will be thrown and compilation will fail.
  ## 
  ## It is also important that all of the names be legal identifiers in Nim. These names are
  ## used to create constants and the compiler won't allow it if those constants are not
  ## legally named.
  ## 
  ## The second possible block is optional: the `init` block. This simply contains code that
  ## runs when a new instance of the chip is created. This code runs after the pins are
  ## created, and it has access to those pins via the `pins` variable. This variable can be
  ## indexed by integer (the pin number) or string (the pin name), and by this point the
  ## aforementioned constants also exist for further indexing utility (the first pin in the
  ## block above could be accessed with `pins[A1]` in the `init` block). If no `init` block
  ## exists, there will still be a constructor proc created, but it'll only create the chip
  ## and return it with no custom functionality.
  ## 
  ## With all of that for input, this macro provides quite a lot.
  ## 
  ## * A type with the same name as appeared after `chip` is created and exported. (It has
  ##   no exported properties.)
  ## * That type has procs attached to it for indexing (either by integer or by string).
  ##   The integer indexing is 1-based rather than 0-based since there is never a pin 0.
  ## * Iterators are provided for the type (both `items` and `pairs`).
  ## * A full set of constants is exported. These constants are named the same as every pin
  ##   name, and their values are the pin numbers associated with them.
  ## * A constructor proc with a name equal to "new" plus the type name is exported. This
  ##   proc creates all of the chip's pins and prepares the indexing, along with whatever
  ##   the user provides in the `init` block.
  ## 
  ## As an example, here is what would be required to make a working 7406 hex inverter.
  ## 
  ## ```
  ## chip Ic7406:
  ##   pins:
  ##     input:
  ##       A1: 1
  ##       A2: 3
  ##       A3: 5
  ##       A4: 9
  ##       A5: 11
  ##       A6: 13
  ##   
  ##     output:
  ##       Y1: 2
  ##       Y2: 4
  ##       Y3: 6
  ##       Y4: 8
  ##       Y5: 10
  ##       Y6: 12
  ##   
  ##     unconnected:
  ##       VCC: 14
  ##       GND: 7
  ## 
  ##   init:
  ##     +pins[Y1]
  ##     +pins[Y2]
  ##     +pins[Y3]
  ##     +pins[Y4]
  ##     +pins[Y5]
  ##     +pins[Y6]
  ## 
  ##     proc dataListener(gate: int): proc (pin: Pin) =
  ##       let ypin = pins[&"Y{gate}"]
  ##       proc listener(pin: Pin) =
  ##         ypin.level = if pin.high: 0 else: 1
  ##       result = listener
  ## 
  ##     for i in 1..6: pins[&"A{i}"].addListener(dataListener(i))
  ## ```
  ## 
  ## And here is the code the macro produces from that input. It's reformatted somewhat here
  ## (macro output doesn't have to be pretty), and the extensive use of gensyms is left out
  ## for clarity.
  ## 
  ## ```
  ## type
  ##   Ic7406Pins = ref object
  ##     byNumber: array[1 .. 14, Pin]
  ##     byName: TableRef[string, Pin]
  ## 
  ##   Ic7406* = ref object
  ##     pins: Ic7406Pins
  ##
  ## proc `[]`(pins: Ic7406Pins; index: int): Pin {.inline.} =
  ##   pins.byNumber[index]
  ## 
  ## proc `[]`(pins: Ic7406Pins; index: string): Pin {.inline.} =
  ##   pins.byName[index]
  ## 
  ## iterator items(pins: Ic7406Pins): Pin =
  ##   for pin in pins.byNumber:
  ##     yield pin
  ## 
  ## iterator pairs(pins: Ic7406Pins): tuple[a: int, b: Pin] =
  ##   for i, pin in pins.byNumber:
  ##     yield (i, pin)
  ## 
  ## proc `[]`*(chip: Ic7406; index: int): Pin {.inline.} =
  ##   chip.pins[index]
  ## 
  ## proc `[]`*(chip: Ic7406; index: string): Pin {.inline.} =
  ##   chip.pins[index]
  ## 
  ## iterator items*(chip: Ic7406): Pin =
  ##   for pin in chip.pins.byNumber:
  ##     yield pin
  ## 
  ## iterator pairs*(chip: Ic7406): tuple[a: int, b: Pin] =
  ##   for i, pin in chip.pins.byNumber:
  ##     yield (i, pin)
  ## 
  ## const
  ##   A1* = 1
  ##   A2* = 3
  ##   A3* = 5
  ##   A4* = 9
  ##   A5* = 11
  ##   A6* = 13
  ##   Y1* = 2
  ##   Y2* = 4
  ##   Y3* = 6
  ##   Y4* = 8
  ##   Y5* = 10
  ##   Y6* = 12
  ##   VCC* = 14
  ##   GND* = 7
  ## 
  ## proc newIc7406*(): Ic7406 =
  ##   let
  ##     rawPins: array[1 .. 14, Pin] = [newPin(1, "A1", Input),
  ##         newPin(2, "Y1", Output), newPin(3, "A2", Input),
  ##         newPin(4, "Y2", Output), newPin(5, "A3", Input),
  ##         newPin(6, "Y3", Output), newPin(7, "GND", Unconnected),
  ##         newPin(8, "Y4", Output), newPin(9, "A4", Input),
  ##         newPin(10, "Y5", Output), newPin(11, "A5", Input),
  ##         newPin(12, "Y6", Output), newPin(13, "A6", Input),
  ##         newPin(14, "VCC", Unconnected)]
  ##     table = newTable[string, Pin]()
  ##     names = rawPins.map(proc (pin: Pin): string = pin.name)
  ## 
  ##   for pairs in zip(names, rawPins):
  ##     let (name, pin) = pairs
  ##     table[name] = pin
  ## 
  ##   let pins = Ic7406Pins(byNumber: rawPins, byName: table)
  ##   result = Ic7406(pins: pins)
  ## 
  ##   +pins[Y1]
  ##   +pins[Y2]
  ##   +pins[Y3]
  ##   +pins[Y4]
  ##   +pins[Y5]
  ##   +pins[Y6]
  ## 
  ##   proc dataListener(gate: int): proc (pin: Pin) =
  ##     let ypin = pins[&"Y{gate}"]
  ##     proc listener(pin: Pin) =
  ##       ypin.level = if pin.high: 0 else: 1
  ##     result = listener
  ## 
  ##   for i in 1..6: pins[&"A{i}"].addListener(dataListener(i))
  ## ```
  ## 
  ## This makes clear that the actual pin container is not an exported type and it does not
  ## have exported procs associated with it. It is given the same procs (indexing and
  ## iteration) as the chip itself has, but that can only be used by code in the `init`
  ## block.

  let chipName = name.strVal
  let chipType = ident(chipName)
  let pinsType = ident(chipName & "Pins")

  var pinsSection = none(NimNode)
  var initSection = none(NimNode)

  for node in body.children():
    if node.kind == nnkCall and node[0].strVal == "pins":
      pinsSection = some(node[1])
    elif node.kind == nnkCall and node[0].strVal == "init":
      initSection = some(node[1])
  if pinsSection.isNone: error("`chip` requires a `pins` section.")
  if initSection.isNone: initSection = some(newEmptyNode())
  
  let pinReprs = parsePins(pinsSection.get())
  let numPins = pinReprs.len

  result = prelude(chipType, pinsType, numPins)
  result.add(constants(pinReprs))
  result.add(init(chipType, pinsType, initSection.get(), pinReprs))
