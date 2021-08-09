<!--
 Copyright (c) 2021 Thomas J. Otterson

 This software is released under the MIT License.
 https://opensource.org/licenses/MIT
-->

# nim64

---

This is a hobby-level emulation of the Commodore 64 written in Nim. This project came about after fears that the JavaScript one (https://github.com/Barandis/c64) is just going to be too slow, and then after fears that the Rust one (https://github.com/Barandis/rust-c64) is causing more time to be spent fighting the language than actually writing code. (I love Rust, but a project full of objects that have to be shared and mutated among many "owners" is not what you want to be doing with it.)

So while this is the third language that I've been using for this project in as many weeks, at least it's going to provide a good opportunity to learn more about Nim. (Hint: the macros are awesome; see components/chip.)

The JS is currently being ported over to Nim. Once that's done, all that'll have to be written is half the VIC and the CPU (which I already have experience emulating).

[There is some documentation available here.](https://barandis.github.io/nim64) This is not a library so the need for documentation isn't high, but there's some stuff there detailing how this project is done internally. In particular there is a lot of information on the implemented chips, and there are some interesting (to me) waveform graphs of what's coming out of the SID as it's currently programmed. More will be added as more code gets complete.

## Current Status

I've just reached the same point in the VIC where I was in the old JS implementation. After finishing that, it's on to the CPU, and then...well, we'll see when we get there.
