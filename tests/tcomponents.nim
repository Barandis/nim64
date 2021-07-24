# Copyright (c) 2021 Thomas J. Otterson
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ./components/pin
import ./components/trace

proc componentTests* =
  pinTests()
  traceTests()

when isMainModule:
  componentTests()
