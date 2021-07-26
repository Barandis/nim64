# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ./components/[pin, trace]

proc all_tests* =
  pin.all_tests()
  trace.all_tests()

when is_main_module:
  all_tests()
