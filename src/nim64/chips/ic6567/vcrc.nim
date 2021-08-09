# Copyright (c) 2021 Thomas J. Otterson
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ./access
import ./raster

type VcRc* = ref object
  vc: uint
  vcbase: uint
  rc: uint
  vmli: uint
  idle: bool
  last_bad_line: bool

proc new_vc_rc*: VcRc =
  VcRc(
    vc: 0,
    vcbase: 0,
    rc: 0,
    vmli: 0,
    idle: false,
    last_bad_line: false,
  )

proc pre_read*(vcrc: VcRc, counter: RasterCounter) =
  if not vcrc.last_bad_line and bad_line(counter): vcrc.idle = false
  vcrc.last_bad_line = bad_line(counter)

  # 1. Once somewhere outside of the range of raster lines $30-$f7 (i.e. outside of the Bad
  #    Line range), VCBASE is reset to zero. This is presumably done in raster line 0, the
  #    exact moment cannot be determined and is irrelevant.
  if raster(counter) == 0 and cycle(counter) == 1 and phase(counter) == 1: vcrc.vcbase = 0

  # 2. In the first phase of cycle 14 of each line, VC is loaded from VCBASE (VCBASE->VC)
  #    and VMLI is cleared. If there is a Bad Line Condition in this phase, RC is also reset
  #    to zero.
  if cycle(counter) == 14 and phase(counter) == 1:
    vcrc.vc = vcrc.vcbase
    vcrc.vmli = 0
    if bad_line(counter): vcrc.rc = 0

  # 5. In the first phase of cycle 58, the VIC checks if RC=7. If so, the video logic goes
  #    to idle state and VCBASE is loaded from VC (VC->VCBASE). If the video logic is in
  #    display state afterwards (this is always the case if there is a Bad Line Condition),
  #    RC is incremented.
  if cycle(counter) == 58 and phase(counter) == 1:
    if vcrc.rc == 7:
      vcrc.idle = true
      vcrc.vcbase = vcrc.vc
    if not vcrc.idle: vcrc.rc += 1

proc post_read*(vcrc: Vcrc, access: AccessType) =
  #  4. VC and VMLI are incremented after each g-access in display state.
  if access == BmChar and not vcrc.idle:
    vcrc.vc += 1
    vcrc.vmli += 1

proc vc*(vcrc: VcRc): uint {.inline.} =
  vcrc.vc

proc rc*(vcrc: VcRc): uint {.inline.} =
  vcrc.rc

proc vmli*(vcrc: VcRc): uint {.inline.} =
  vcrc.vmli

proc idle*(vcrc: VcRc): bool {.inline.} =
  vcrc.idle