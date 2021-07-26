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

proc parse_header(header: NimNode): (NimNode, NimNode, NimNode) =
  ## Parses the part that comes *before* the block, between the `chip` identifier and the
  ## first colon. This will most often just be an identifier for the new type of chip, but
  ## it *can* contain a parameter list in parentheses as well. If it does, that same
  ## parameter list is included in the constructor function, and variables of those names
  ## and types are made available to the `init` block.
  ## 
  let chip_name = if (kind header) == nnk_ident: str_val header else: str_val header[0]
  let chip_type = ident chip_name
  let pins_type = ident (chip_name & "Pins")
  var params_tree = new_tree(nnk_formal_params, chip_type)

  if (kind header) == nnk_obj_constr:
    for i in 1..<(len header):
      let param_id = header[i][0]
      let param_type = header[i][1]
      let param = new_ident_defs(param_id, param_type, new_empty_node())
      add params_tree, param

  result = (chip_type, pins_type, params_tree)

proc parse_pin(node: NimNode): (int, string) =
  ## Takes an AST node and parses it for information about a single pin. This is well inside
  ## a mode block, so the only things it can gather are number and name. This is called once
  ## per pin by `parse_pins` below.

  let name = str_val node[0]
  var number: int = 0

  if node[1][0].kind == nnk_int_lit:
    # intVal returns a BiggestInteger, which is great but probably just means it needs to
    # be converted approximately everywhere
    number = int int_val node[1][0]
  else:
    error("Pin number must be an integer", node)
  
  result = (number, name)

proc parse_pins(pins_tree: NimNode): seq[PinRepr] =
  ## Takes the AST of the full pin section and parses it, returning information about all
  ## pins. Since at this level the mode blocks are still visible, this proc can and does
  ## include mode information as well.

  var input_tree = none NimNode
  var output_tree = none NimNode
  var bidi_tree = none NimNode
  var unc_tree = none NimNode

  for node in children pins_tree:
    if (kind node) == nnk_call:
      let ident = str_val node[0]
      case ident
      of "input": input_tree = some node[1]
      of "output": output_tree = some node[1]
      of "bidi": bidi_tree = some node[1]
      of "unconnected": unc_tree = some node[1]
      else: error("Unknown pin type: " & ident, node)
  
  if is_some input_tree:
    for stmt_node in children get input_tree:
      let (number, name) = parse_pin stmt_node
      add result, (number, name, bindSym "Input")

  if is_some output_tree:
    for stmt_node in children get output_tree:
      let (number, name) = parse_pin stmt_node
      add result, (number, name, bind_sym "Output")
  
  if is_some bidi_tree:
    for stmt_node in children get bidi_tree:
      let (number, name) = parse_pin stmt_node
      add result, (number, name, bind_sym "Bidi")
  
  if is_some unc_tree:
    for stmt_node in children get unc_tree:
      let (number, name) = parse_pin stmt_node
      add result, (number, name, bind_sym "Unconnected")

proc prelude(chip_type, pins_type: NimNode; num_pins: int): NimNode =
  ## Produces the AST for the first part of the macro output. This includes types and the
  ## procs that are attached to those types (indexing and iterators).

  let brackets = new_tree(nnk_acc_quoted, ident "[]")
  let pin_sym = bind_sym "Pin"
  let table_sym = bind_sym "TableRef"

  # This produces a full type (the pins type) that is not exported with indexing and
  # iteration capabilities that are also not exported (though the procs and iterators
  # attached to the chip itself *are* exported and do the same thing). These are created
  # just to be available with the `pins` variable in the `init` block.
  result = quote do:
    type 
      `pins_type` = ref object
        by_number: array[1..`num_pins`, `pin_sym`]
        by_name: `table_sym`[string, `pin_sym`]
      `chip_type`* = ref object
        pins: `pins_type`

    proc `brackets`(pins: `pins_type`, index: int): `pin_sym` {.inline.} = pins.by_number[index]
    proc `brackets`(pins: `pins_type`, index: string): `pin_sym` {.inline.} = pins.by_name[index]
    iterator items(pins: `pins_type`): `pin_sym` =
      for pin in pins.by_number:
        yield pin
    iterator pairs(pins: `pins_type`): tuple[a: int, b: `pin_sym`] =
      for i, pin in pins.by_number:
        yield (i, pin)

    proc `brackets`*(chip: `chip_type`, index: int): `pin_sym` {.inline.} = chip.pins[index]
    proc `brackets`*(chip: `chip_type`, index: string): `pin_sym` {.inline.} = chip.pins[index]
    iterator items*(chip: `chip_type`): `pin_sym` =
      for pin in chip.pins:
        yield pin
    iterator pairs*(chip: `chip_type`): tuple[a: int, b: `pin_sym`] =
      for i, pin in chip.pins:
        yield (i, pin)

proc constants(pins: seq[PinRepr]): NimNode {.compile_time.} =
  ## Produces the AST for the second part of the macro output. This includes constants based
  ## on the names and numbers of the pins in the macro input.

  result = new_nim_node nnk_const_section

  for pin in pins:
    let node = new_tree(nnk_const_def,
      new_tree(nnk_postfix,
        ident "*",
        ident pin.name,
      ),
      new_empty_node(),
      new_int_lit_node pin.number,
    )
    add result, node

proc init(chip_type, pins_type, params_tree, init_tree: NimNode; pins: seq[PinRepr]): NimNode =
  ## Produces the AST for the third part of the macro output. This is the constructor proc
  ## that will create a new instance of the chip once the type is defined. `chip_type` and
  ## `pins_type` are always Ident nodes. `params_tree` is a FormalParams node; if there are 
  ## no parameters it just contains the return type. `init_tree` is an Empty node if there 
  ## is no `init` section; otherwise it's a StmtList node.

  let proc_name = ident ("new" & str_val chip_type)
  let new_table_sym = bind_sym "newTable"
  let pin_sym = bind_sym "Pin"
  let map_sym = bind_sym "map"
  let zip_sym = bind_sym "zip"

  let pins_len = len pins
  let pins_id = ident "pins"

  # There are two things missing from this tree: there are no formal parameters, and the
  # `raw_pins` array is empty. We'll fix both of those next.
  result = quote do:
    proc `proc_name`*: `chip_type` =
      let 
        raw_pins: array[1..`pins_len`, `pin_sym`] = []
        table = `new_table_sym`[string, `pin_sym`]()
        names = `map_sym`(raw_pins, proc (pin: `pin_sym`): string = pin.name)
      
      for pairs in `zip_sym`(names, raw_pins):
        let (name, pin) = pairs
        table[name] = pin
      
      let `pins_id` = `pins_type`(by_number: raw_pins, by_name: table)
      result = `chip_type`(pins: `pins_id`)
  
  # Add in the formal parameters to the proc. If there aren't any, this just swaps out one
  # return-type-only FormalParams node for another.
  del result, 3
  insert result, 3, params_tree
  
  # This is the node for the brackets in `raw_pins = []`. We use it as an attachment point
  # for the nodes that make up the entries in that array. We're basically returning to a
  # node we already created to insert some more stuff into it, which is of course fine
  # because it's still compile time when this is running.
  let brackets = result[6][0][0][2] # !

  # Run through the pins sequence by pin number, not by index. This ensures that the array
  # elements are produced in the proper order no matter the order in the macro input.
  for i in 1..(len pins):
    let filtered = filter(pins, proc (pin: PinRepr): bool = pin.number == i)
    if (len filtered) == 0:
      error ("Missing pin number " & $i)
    elif (len filtered) > 1:
      error ("Duplicate pin number " & $i)
    
    let pin = filtered[0]
    add brackets, new_call(
      bind_sym "new_pin",
      new_int_lit_node pin.number,
      new_str_lit_node pin.name,
      pin.mode
    )
  
  # Finally, add the `init` section verbatim.
  add result[6], init_tree

macro chip*(header, body: untyped): untyped =
  ## A macro to produce a full definition of a chip from declarative parts.
  ## 
  ## The macro takes the form of a block definition, with other blocks inside of it. The 
  ## name of the new chip must be included before the first block begins, right after the
  ## `chip` identifier:
  ## 
  ## ```
  ## chip Ic7406:
  ## ```
  ## 
  ## Optionally, a list of parameters can be included in parentheses after the name of the
  ## new chip. These must include the name and the type, like normal for parameter lists.
  ## 
  ## ```
  ## chip Ic2332(memory: array[4096, uint8]):
  ## ```
  ## 
  ## Inside this `chip` block there can be two other blocks.
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
  ## If a parameter list was included after the chip name (see above), then variables of
  ## those names and types are *also* made available in the `init` block. They will be set
  ## to the value provided by the generated constructor proc (see below) when this macro is
  ## actually invoked.
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
  ##   the user provides in the `init` block. If a parameter list was provided with the
  ##   chip name, this proc will take the same parameters, and they will be avialable to the
  ##   rest of the code in the `init` block.
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
  ##     proc data_listener(gate: int): proc (pin: Pin) =
  ##       let ypin = pins[&"Y{gate}"]
  ##       result = proc (pin: Pin) =
  ##         if highp pin: clear ypin else: set ypin
  ##
  ##     for i in 1..6: add_listener pins[&"A{i}"], data_listener i
  ## ```
  ## 
  ## And here is the code the macro produces from that input. It's reformatted somewhat here
  ## (macro output doesn't have to be pretty), and the extensive use of gensyms is left out
  ## for clarity.
  ## 
  ## ```
  ## type
  ##   Ic7406Pins = ref object
  ##     by_number: array[1 .. 14, Pin]
  ##     by_name: TableRef[string, Pin]
  ## 
  ##   Ic7406* = ref object
  ##     pins: Ic7406Pins
  ##
  ## proc `[]`(pins: Ic7406Pins; index: int): Pin {.inline.} =
  ##   pins.by_number[index]
  ## 
  ## proc `[]`(pins: Ic7406Pins; index: string): Pin {.inline.} =
  ##   pins.by_name[index]
  ## 
  ## iterator items(pins: Ic7406Pins): Pin =
  ##   for pin in pins.by_number:
  ##     yield pin
  ## 
  ## iterator pairs(pins: Ic7406Pins): tuple[a: int, b: Pin] =
  ##   for i, pin in pins.by_number:
  ##     yield (i, pin)
  ## 
  ## proc `[]`*(chip: Ic7406; index: int): Pin {.inline.} =
  ##   chip.pins[index]
  ## 
  ## proc `[]`*(chip: Ic7406; index: string): Pin {.inline.} =
  ##   chip.pins[index]
  ## 
  ## iterator items*(chip: Ic7406): Pin =
  ##   for pin in chip.pins:
  ##     yield pin
  ## 
  ## iterator pairs*(chip: Ic7406): tuple[a: int, b: Pin] =
  ##   for i, pin in chip.pins:
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
  ## proc new_Ic7406*(): Ic7406 =
  ##   let
  ##     raw_pins: array[1 .. 14, Pin] = [newPin(1, "A1", Input),
  ##         newPin(2, "Y1", Output), newPin(3, "A2", Input),
  ##         newPin(4, "Y2", Output), newPin(5, "A3", Input),
  ##         newPin(6, "Y3", Output), newPin(7, "GND", Unconnected),
  ##         newPin(8, "Y4", Output), newPin(9, "A4", Input),
  ##         newPin(10, "Y5", Output), newPin(11, "A5", Input),
  ##         newPin(12, "Y6", Output), newPin(13, "A6", Input),
  ##         newPin(14, "VCC", Unconnected)]
  ##     table = new_table[string, Pin]()
  ##     names = raw_pins.map(proc (pin: Pin): string = pin.name)
  ## 
  ##   for pairs in zip(names, raw_pins):
  ##     let (name, pin) = pairs
  ##     table[name] = pin
  ## 
  ##   let pins = Ic7406Pins(by_number: raw_pins, by_name: table)
  ##   result = Ic7406(pins: pins)
  ## 
  ##   proc data_listener(gate: int): proc (pin: Pin) =
  ##     let ypin = pins[&"Y{gate}"]
  ##     result = proc (pin: Pin) =
  ##       if highp pin: clear ypin else: set ypin
  ##
  ##   for i in 1..6: add_listener pins[&"A{i}"], data_listener i
  ## ```
  ## 
  ## This makes clear that the actual pin container is not an exported type and it does not
  ## have exported procs associated with it. It is given the same procs (indexing and
  ## iteration) as the chip itself has, but that can only be used by code in the `init`
  ## block.

  let (chip_type, pins_type, params_tree) = parse_header header

  var pins_tree = none NimNode
  var init_tree = none NimNode

  for node in children body:
    if (kind node) == nnk_call and (str_val node[0]) == "pins":
      pins_tree = some node[1]
    elif (kind node) == nnk_call and (str_val node[0]) == "init":
      init_tree = some node[1]
  if is_none pins_tree: error "`chip` requires a `pins` section."
  if is_none init_tree: init_tree = some new_empty_node()
  
  let pin_reprs = parse_pins get pins_tree
  let num_pins = len pin_reprs

  result = prelude(chip_type, pins_type, num_pins)
  add result, constants pin_reprs
  add result, init(chip_type, pins_type, params_tree, get init_tree, pin_reprs)
