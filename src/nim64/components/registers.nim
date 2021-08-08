# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import tables

type
  ## A collection of registers that can be indexed and/or assigned to by either register
  ## number or register name. When indexed by number, the index is 0-based. When indexed by
  ## name, the name is case-sensitive.
  Registers* = ref object
    values: seq[uint8]
    lookup: TableRef[string, int]

  RegisterInfo* = tuple
    ## Information about a single register in tuple form.
    name: string
    value: uint8

proc new_registers*(registers: varargs[string]): Registers =
  ## Creates a new collection of registers. All of the registers in the collection must be
  ## provided to this constructor proc; there is no facility to add more later.
  ##
  ## The registers will be implicitly given an index (0-based) matching the order in which
  ## they appear in the argument list.
  var reg_seq: seq[uint8]
  new_seq(reg_seq, len(registers))
  var reg_table = new_table[string, int]()

  for index, name in registers:
    reg_seq[index] = 0
    reg_table[name] = index

  Registers(values: reg_seq, lookup: reg_table)

proc `[]`*(registers: Registers, index: int): uint8 =
  ## Returns the value of a register based on the register's number.
  registers.values[index]

proc `[]`*(registers: Registers, index: string): uint8 =
  ## Returns the value of a register based on the register's name.
  registers.values[registers.lookup[index]]

proc `[]=`*(registers: Registers, index: int, value: uint8) =
  ## Modifies the value of a register based on the register's number.
  registers.values[index] = value

proc `[]=`*(registers: Registers, index: string, value: uint8) =
  ## Modifies the value of a register based on the register's name.
  registers.values[registers.lookup[index]] = value

iterator items*(registers: Registers): uint8 =
  ## Iterates over the register collection, returning the values of each register.
  for value in registers.values:
    yield value

iterator pairs*(registers: Registers): (int, uint8) =
  ## Iterates over the register collection, returning both the register's number and its
  ## value.
  for index, value in registers.values:
    yield (index, value)

proc len*(registers: Registers): int =
  ## Returns the number of registers in the collection.
  len(registers.values)

proc info*(registers: Registers): seq[RegisterInfo] =
  ## Returns a read-only view of the colleciton, including both the names and the values of
  ## each register.
  new_seq(result, len(registers.values))
  for (name, index) in registers.lookup.pairs:
    result[index] = (name, registers.values[index])
