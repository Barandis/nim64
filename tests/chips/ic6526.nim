# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ./ic6526/[misc, ports, serial, timera, timerb, tod]

proc all_tests* =
  ports.all_tests()
  timera.all_tests()
  timerb.all_tests()
  tod.all_tests()
  serial.all_tests()
  misc.all_tests()

when is_main_module:
  all_tests()
