# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import tables
import macros
import sequtils
import options
import ./link

type 
  PinInfo = tuple
    ## A tuple of the information that can be gleaned about a pin from the macro input. This 
    ## is simply the number, name, and mode, which are what's necessary to construct a pin. 
    ## The mode is kept as a `NimNode` because it immediately has `bindSym` applied to it; it 
    ## makes things easier in the end, and unlike name and number, there is no use for the 
    ## mode other than writing it into the constructor function.
    number: int
    name: string
    mode: NimNode
  
  RegInfo = tuple
    number: int
    name: string


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

proc parse_pin_or_register(node: NimNode): (int, string) =
  ## Takes an AST node and parses it for information about a single pin or a single 
  ## register. This is well inside a mode block for pins, so the only things it can gather 
  ## are number and name, which is all that's needed for a register in the first place. This
  ## is called once per pin by `parse_pins` and once per register by `parse_registers`
  ## below.

  let name = str_val node[0]
  var number: int = 0

  if node[1][0].kind == nnk_int_lit:
    # intVal returns a BiggestInteger, which is great but probably just means it needs to
    # be converted approximately everywhere
    number = int int_val node[1][0]
  else:
    error("Index number must be an integer", node)
  
  result = (number, name)

proc parse_pins(pins_tree: NimNode): seq[PinInfo] =
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
      let (number, name) = parse_pin_or_register stmt_node
      add result, (number, name, bindSym "Input")

  if is_some output_tree:
    for stmt_node in children get output_tree:
      let (number, name) = parse_pin_or_register stmt_node
      add result, (number, name, bind_sym "Output")
  
  if is_some bidi_tree:
    for stmt_node in children get bidi_tree:
      let (number, name) = parse_pin_or_register stmt_node
      add result, (number, name, bind_sym "Bidi")
  
  if is_some unc_tree:
    for stmt_node in children get unc_tree:
      let (number, name) = parse_pin_or_register stmt_node
      add result, (number, name, bind_sym "Unconnected")
  
proc parse_registers(regs_tree: NimNode): seq[RegInfo] =
  for stmt_node in children regs_tree:
    let (number, name) = parse_pin_or_register stmt_node
    add result, (number, name)

proc prelude(chip_type, pins_type: NimNode; num_pins, num_regs: int): NimNode =
  ## Produces the AST for the first part of the macro output. This includes types and the
  ## procs that are attached to those types (indexing and iterators).

  let brackets = new_tree(nnk_acc_quoted, ident "[]")
  let brequal = newTree(nnk_acc_quoted, ident "[]=")
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
  
  if num_regs > 0:
    let regs_type = ident ((str_val chip_type) & "Regs")

    let regs_def = quote do:
      type `regs_type` = ref object
        registers: array[`num_regs`, uint8]
        lookup: `table_sym`[string, int]
    
    insert result[0], 0, regs_def[0]
    
    let reg_procs = quote do:
      proc `brackets`(regs: `regs_type`, index: int): uint8 {.used, inline.} =
        regs.registers[index]
      proc `brackets`(regs: `regs_type`, index: string): uint8{.used, inline.} =
        regs.registers[regs.lookup[index]]
      proc `brequal`(regs: `regs_type`, index: int, value: uint8) {.used, inline.} =
        regs.registers[index] = value
      proc `brequal`(regs: `regs_type`, index: string, value: uint8) {.used, inline.} =
        regs.registers[regs.lookup[index]] = value
      iterator items(regs: `regs_type`): uint8 {.used.} =
        for value in regs.registers:
          yield value
      iterator pairs(regs: `regs_type`): tuple[a: int, b: uint8] {.used.} =
        for i, value in regs.registers:
          yield (i, value)
    
    insert result, 1, reg_procs

proc constants(pins: seq[PinInfo], registers: seq[RegInfo]): NimNode {.compile_time.} =
  ## Produces the AST for the second part of the macro output. This includes constants based
  ## on the names and numbers of the pins and registers in the macro input.

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
  
  for reg in registers:
    let node = new_tree(nnk_const_def,
      new_tree(nnk_pragma_expr,
        ident reg.name,
        new_tree(nnk_pragma, ident "used")
      ),
      new_empty_node(),
      new_int_lit_node reg.number,
    )
    add result, node

proc init(
  chip_type, pins_type, params_tree, init_tree: NimNode;
  pins: seq[PinInfo], regs: seq[RegInfo]): NimNode =
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

  let regs_len = len regs

  # There are two things missing from this tree: there are no formal parameters, and the
  # `raw_pins` array is empty. We'll fix both of those next.
  result = quote do:
    proc `proc_name`*: `chip_type` =
      let 
        raw_pins: array[1..`pins_len`, `pin_sym`] = []
        pin_table = `new_table_sym`[string, `pin_sym`]()
        names = `map_sym`(raw_pins, proc (pin: `pin_sym`): string = pin.name)
      
      for pairs in `zip_sym`(names, raw_pins):
        let (name, pin) = pairs
        pin_table[name] = pin
      
      let `pins_id` = `pins_type`(by_number: raw_pins, by_name: pin_table)
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
    let filtered = filter(pins, proc (pin: PinInfo): bool = pin.number == i)
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
  
  # We're doing registers after pins, even though registers will come first in document
  # order, so the indices to the pin brackets could remain the same whether registers exist
  # or not
  if regs_len > 0:
    let regs_id = ident "registers"
    let regs_type = ident ((str_val chip_type) & "Regs")

    let regs_tree = quote do:
      var raw_regs: array[`regs_len`, uint8]
      let reg_table = `new_table_sym`[string, int]()

      for i, reg in []: reg_table[reg] = i

      let `regs_id` {.used.} = `regs_type`(registers: raw_regs, lookup: reg_table)
    
    let reg_brackets = regs_tree[2][2]
    
    for i in 0..<(len regs):
      let filtered = filter(regs, proc (reg: RegInfo): bool = reg.number == i)
      if (len filtered) == 0:
        error ("Missing register number " & $i)
      elif (len filtered) > 1:
        error ("Duplicate register number " & $i)
      
      let reg = filtered[0]
      add reg_brackets, new_str_lit_node reg.name

    insert result[6], 0, regs_tree 
  
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
  ## chip Ic2364(memory: array[8192, uint8]):
  ## ```
  ## 
  ## Inside this `chip` block there can be one to three other blocks.
  ## 
  ## ## `pins`
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
  ## Here is an example `pins` block, one that would be used in a 7406 hex inverter.
  ## 
  ## ```nim
  ## pins:
  ##   input:
  ##     A1: 1
  ##     A2: 3
  ##     A3: 5
  ##     A4: 9
  ##     A5: 11
  ##     A6: 13
  ##  
  ##   output:
  ##     Y1: 2
  ##     Y2: 4
  ##     Y3: 6
  ##     Y4: 8
  ##     Y5: 10
  ##     Y6: 12
  ##  
  ##   unconnected:
  ##     VCC: 14
  ##     GND: 7
  ## ```
  ## 
  ## ## `registers`
  ## 
  ## This optional block is used to define registers for those chips that have them. Unlike
  ## the `pins` block, this does not have any sub-blocks; all register definitions go
  ## directly under `registers`. Definitions are the same as in the `pins` block though:
  ## the register name is followed by a colon and then the register index.
  ## 
  ## Registers begin from index 0, and like the pins, there must be no missing or duplicate
  ## indexes. Furthermore, no register can share a name with another register or with a pin.
  ## Constants are created for both pins and registers, and constants must have unique
  ## names.
  ## 
  ## If a `registers` block is provided, then a `registers` variable will be available in
  ## the `init` section (see below).
  ## 
  ## Here is a sample `registers` block, one from a 6526 CIA.
  ## 
  ## ```nim
  ## registers:
  ##   PRA: 0
  ##   PRB: 1
  ##   DDRA: 2
  ##   DDRB: 3
  ##   TALO: 4
  ##   TAHI: 5
  ##   TBLO: 6
  ##   TBHI: 7
  ##   TOD10TH: 8
  ##   TODSEC: 9
  ##   TODMIN: 10
  ##   TODHR: 11
  ##   SDR: 12
  ##   ICR: 13
  ##   CRA: 14
  ##   CRB: 15
  ## ```
  ## 
  ## ## `init`
  ## 
  ## The final possible block is also optional: the `init` block. This simply contains code 
  ## that runs when a new instance of the chip is created. This code runs after the pins and
  ## registers (if any) are created, and it has access to those pins via the `pins` variable
  ## and those registers via the `registers` variable. It's used for whatever initialization
  ## is necessary; that includes setting handlers on pins, which is where the functionality
  ## of a chip comes from in the first place. So the `init` block can essentially be used to
  ## define the entire behavior of a chip.
  ## 
  ## Both `pins` and `registers` can be indexed by either integer (the index) or string (the
  ## name). `pins` is read-only (though of course the returned pin can be modified freely),
  ## but `registers` also is assignable by both integer and string index. Both have
  ## iterators for both `items` and `pairs`.
  ## 
  ## If a parameter list was included after the chip name (see above), then variables of
  ## those names and types are *also* made available in the `init` block. They will be set
  ## to the value provided to the generated constructor proc (see below) when a chip is
  ## actually created.
  ## 
  ## If no `init` block exists, there will still be a constructor proc created, but it'll 
  ## only create the chip and return it with no custom functionality.
  ## 
  ## Here is a sample `init` block, this time from a 2364 ROM. The 2364 definition does not
  ## have a `registers` block so no `registers` variable is available here, but it does have
  ## a parameter named `memory` with the type `array[8192, uint8]` that is available in this
  ## block (and is in fact referenced in the `read` proc). The chip definition shown above
  ## for the 2364 shows that parameter.
  ## 
  ## (Any symbol other than `pins` and `memory` in this code comes either from a local
  ## definition or from an import.)
  ## 
  ## ```nim
  ## init:
  ##   let addr_pins = map(to_seq 0..12, proc (i: int): Pin = pins[&"A{i}"])
  ##   let data_pins = map(to_seq 0..7, proc (i: int): Pin = pins[&"D{i}"])
  ##
  ##   proc read =
  ##     value_to_pins memory[pins_to_value addr_pins], data_pins
  ##  
  ##   proc enable_listener(pin: Pin) =
  ##     if lowp pin: read() elif highp pin: tri_pins data_pins
  ##  
  ##   add_listener pins[CS], enable_listener
  ## ```
  ## 
  ## With all of that for input, this macro provides quite a lot.
  ## 
  ## * A type with the same name as appeared after `chip` is created and exported. It has no
  ##   exported properties, but it does have exported overloads of the `[]` operator. These
  ##   let a chip instance be indexed by pin number or pin name, and the pin of that number
  ##   or name is the result. It also has iterators exported both for `items` and for
  ##   `pairs`, both of which also yield pins.
  ## * A full set of constants is exported. These constants are named the same as every pin
  ##   name, and their values are the pin numbers associated with them.
  ## * A constructor proc with a name equal to "new" plus the type name is exported. This
  ##   proc creates all of the chip's pins and prepares the indexing, along with whatever
  ##   the user provides in the `init` block. If a parameter list was provided with the
  ##   chip name, this proc will take the same parameters, and they will be available to the
  ##   rest of the code in the `init` block.
  ## * One or two unexported types are created. The first will be the type for the `pins`
  ##   variable in the `init` block; the other is the type of the `registers` variable and
  ##   will only be present if there is a `registers` block.
  ## * Iterators and the `[]` operator (using either number or name for the index) are 
  ##   provided for both types, but they are not exported and are only available within the
  ##   `init` block.  The `registers` variable will also have `[]=` available to assign to
  ##   a register by number or name index.
  ## * If a `registers` block is present, a second set of constants will be generated. There
  ##   will be one for each register, and the name will be a register name with the value of
  ##   that register's number. Unlike the constants above, these are *not* exported and are
  ##   therefore only available to the `init` block.

  let (chip_type, pins_type, params_tree) = parse_header header

  var pins_tree = none NimNode
  var regs_tree = none NimNode
  var init_tree = none NimNode

  for node in children body:
    if (kind node) == nnk_call and (str_val node[0]) == "pins":
      pins_tree = some node[1]
    elif (kind node) == nnk_call and (str_val node[0]) == "registers":
      regs_tree = some node[1]
    elif (kind node) == nnk_call and (str_val node[0]) == "init":
      init_tree = some node[1]
    else: error ("Unknown section: " & str_val node[0])

  if is_none pins_tree: error "`chip` requires a `pins` section."
  if is_none regs_tree: regs_tree = some new_empty_node()
  if is_none init_tree: init_tree = some new_empty_node()
  
  let pin_info = parse_pins get pins_tree
  let num_pins = len pin_info

  let reg_info = parse_registers get regs_tree
  let num_regs = len reg_info

  result = prelude(chip_type, pins_type, num_pins, num_regs)
  add result, constants(pin_info, reg_info)
  add result, init(chip_type, pins_type, params_tree, get init_tree, pin_info, reg_info)
