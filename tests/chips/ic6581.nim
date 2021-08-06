# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ./ic6581/[envelope, registers, waveform]

proc all_tests* =
  waveform.all_tests()
  envelope.all_tests()
  registers.all_tests()

if is_main_module:
  all_tests()
