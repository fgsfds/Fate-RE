; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; Historical settransreverse semantic writes to original renderer instruction fields.
BITS 32
ORG 0x64450
settransreverse_:
 mov byte [0x644ee], 0xa3
 mov byte [0x644f4], 0x7
 mov byte [0x64a13], 0x1f
 mov byte [0x64a15], 0xb8
 mov byte [0x64c71], 0xb0
 mov byte [0x64c77], 0x17
 mov byte [0x64cde], 0xb0
 mov byte [0x64ce4], 0xd3
 mov byte [0x64cf5], 0xb0
 mov byte [0x64cfb], 0xd7
 mov byte [0x64db1], 0x87
 mov byte [0x64db7], 0xa1
 mov byte [0x64e10], 0x87
 mov byte [0x64e16], 0xdc
 mov byte [0x64e18], 0xa1
 mov byte [0x64e1e], 0xba
 mov byte [0x64e41], 0x87
 mov byte [0x64e47], 0xa2
 ret
