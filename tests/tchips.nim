# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ./chips/[
  ic2114,
  ic2332,
  ic2364,
  ic4066,
  ic4164,
  ic6526,
  ic7406,
  ic7408,
  ic74139,
  ic74257,
  ic74258,
  ic74373,
  ic82s100,
]

proc all_tests* =
  ic2114.all_tests()
  ic2332.all_tests()
  ic2364.all_tests()
  ic4066.all_tests()
  ic4164.all_tests()
  ic6526.all_tests()
  ic7406.all_tests()
  ic7408.all_tests()
  ic74139.all_tests()
  ic74257.all_tests()
  ic74258.all_tests()
  ic74373.all_tests()
  ic82s100.all_tests()

when is_main_module:
  all_tests()
