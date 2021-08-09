# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ./ic6567/[raster, registers]

proc all_tests* =
  registers.all_tests()
  raster.all_tests()

when is_main_module:
  all_tests()
