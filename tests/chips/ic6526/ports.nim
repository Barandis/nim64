# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import unittest
import random
import ../../../src/nim64/utils

randomize()

include ./common

proc ddr_input =
  setup()

  write_register DDRA, 0
  for i in 0..7:
    check (mode chip[&"PA{i}"]) == Input
  
  write_register DDRB, 0
  for i in 0..7:
    check (mode chip[&"PB{i}"]) == Input

proc ddr_output =
  setup()

  write_register DDRA, 0xff
  for i in 0..7:
    check (mode chip[&"PA{i}"]) == Output
  
  write_register DDRB, 0xff
  for i in 0..7:
    check (mode chip[&"PB{i}"]) == Output

proc ddr_random =
  setup()

  for _ in 1..10:
    let value = uint8 rand 255

    write_register DDRA, value
    for i in 0..7:
      check (mode chip[&"PA{i}"]) == (if bit_set(value, i): Output else: Input)
    
    write_register DDRB, value
    for i in 0..7:
      check (mode chip[&"PB{i}"]) == (if bit_set(value, i): Output else: Input)

proc ddr_timer_out =
  setup()

  # turn on PBON for timer A
  write_register CRA, 0x02

  # set DDR for port B to all inputs, PB6 should remain output because of PBON
  write_register DDRB, 0
  for i in 0..7:
    check (mode chip[&"PB{i}"]) == (if i == 6: Output else: Input)
  
  # turn on PBON for timer B
  write_register CRB, 0x02
  # set DDR for port B to all inputs, PB6 AND PB7 should remain output because of PBON
  write_register DDRB, 0
  for i in 0..7:
    check (mode chip[&"PB{i}"]) == (if i == 6 or i == 7: Output else: Input)

proc pdr_receive =
  setup()

  let pa_value = uint8 rand 255

  write_register DDRA, 0
  value_to_traces pa_value, pa_traces
  check (read_register PRA) == pa_value

  let pb_value = uint8 rand 255

  write_register DDRB, 0
  value_to_traces pb_value, pb_traces
  check (read_register PRB) == pb_value

proc pdr_send =
  setup()

  let pa_value = uint8 rand 255

  write_register DDRA, 255
  write_register PRA, pa_value
  check (traces_to_value pa_traces) == pa_value

  let pb_value = uint8 rand 255

  write_register DDRB, 255
  write_register PRB, pb_value
  check (traces_to_value pb_traces) == pb_value

proc pdr_random =
  setup()

  let pa_mask     = uint8 rand 255
  let pa_in       = uint8 rand 255
  let pa_out      = uint8 rand 255
  let pa_expected = (pa_mask and pa_out) or (not pa_mask and pa_in)

  write_register DDRA, pa_mask
  value_to_traces pa_in, pa_traces
  write_register PRA, pa_out
  let pa_register = read_register PRA
  let pa_pins = traces_to_value pa_traces

  check:
    pa_register == pa_expected
    pa_pins == pa_expected

  let pb_mask     = uint8 rand 255
  let pb_in       = uint8 rand 255
  let pb_out      = uint8 rand 255
  let pb_expected = (pb_mask and pb_out) or (not pb_mask and pb_in)

  write_register DDRB, pb_mask
  value_to_traces pb_in, pb_traces
  write_register PRB, pb_out
  let pb_register = read_register PRB
  let pb_pins = traces_to_value pb_traces

  check:
    pb_register == pb_expected
    pb_pins == pb_expected

proc pdr_timer_out =
  # set all pins to output, write a 0 on all of them
  write_register DDRB, 0xff
  write_register PRB, 0x00

  # turn on PBON for both timers
  write_register CRA, 0x02
  write_register CRB, 0x02

  # write all 1's, PB6 and PB7 shouldn't send
  write_register PRB, 0b11111111
  check:
    (read_register PRB) == 0b00111111
    (traces_to_value pb_traces) == 0b00111111

proc pdr_trigger_pc =
  setup()

  # reading port A does not trigger PC
  write_register DDRA, 0x00
  value_to_traces 0xff, pa_traces
  check:
    (read_register PRA) == 0xff
    highp traces[PC]
  
  # writing port A does not trigger PC
  write_register DDRA, 0xff
  write_register PRA, 0x30
  check:
    (traces_to_value pa_traces) == 0x30
    highp traces[PC]
  
  # reading port B does trigger PC
  write_register DDRB, 0x00
  value_to_traces 0xff, pb_traces
  check:
    highp traces[PC]
    (read_register PRB) == 0xff
    lowp traces[PC]
  
  # PC resets on the next clock high
  set traces[PHI2]
  check highp traces[PC]
  clear traces[PHI2]

  # writing port B does trigger PC
  write_register DDRB, 0xff
  write_register PRB, 0x30
  check:
    (traces_to_value pb_traces) == 0x30
    lowp traces[PC]
  
  set traces[PHI2]
  check highp traces[PC]
  clear traces[PHI2]

proc all_tests* =
  suite "6526 CIA ports":
    test "setting DDR to 0 makes all port pins inputs": ddr_input()
    test "setting DDR to 0xff makes all port pins outputs": ddr_output()
    test "setting DDR to random numbers sets the correct modes": ddr_random()
    test "PBON forces PB6 and/or PB7 to remain outputs": ddr_timer_out()
    test "parallel data ports receive correct values": pdr_receive()
    test "parallel data ports send correct values": pdr_send()
    test "random in/out combinations result in correct port values": pdr_random()
    test "PBON causes register writes to be ignored": pdr_timer_out()
    test "reading or writing port B clears PC for one cycle": pdr_trigger_pc()

when is_main_module:
  all_tests()
