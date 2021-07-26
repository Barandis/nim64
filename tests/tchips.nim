# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ./chips/ic2114
import ./chips/ic2332
import ./chips/ic2364
import ./chips/ic4066
import ./chips/ic7406
import ./chips/ic7408
import ./chips/ic74139
import ./chips/ic74257
import ./chips/ic74258
import ./chips/ic74373

proc allTests* =
  ic2114.allTests()
  ic2332.allTests()
  ic2364.allTests()
  ic4066.allTests()
  ic7406.allTests()
  ic7408.allTests()
  ic74139.allTests()
  ic74257.allTests()
  ic74258.allTests()
  ic74373.allTests()

when isMainModule:
  allTests()
