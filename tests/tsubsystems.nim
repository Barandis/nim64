# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ./subsystems/[dram, pla]

proc all_tests* =
  dram.all_tests()
  pla.all_tests()

if is_main_module:
  all_tests()
