; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; Historical settransnormal semantic writes to original renderer instruction fields.
BITS 32
ORG 0x643d0
settransnormal_:
 mov byte [0x644ee], 0x83
 mov byte [0x644f4], 0x27
 mov byte [0x64a13], 0x3f
 mov byte [0x64a15], 0x98
 mov byte [0x64c71], 0x90
 mov byte [0x64c77], 0x37
 mov byte [0x64cde], 0x90
 mov byte [0x64ce4], 0xf3
 mov byte [0x64cf5], 0x90
 mov byte [0x64cfb], 0xf7
 mov byte [0x64db1], 0xa7
 mov byte [0x64db7], 0x81
 mov byte [0x64e10], 0x9f
 mov byte [0x64e16], 0xe3
 mov byte [0x64e18], 0x81
 mov byte [0x64e1e], 0x9a
 mov byte [0x64e41], 0xa7
 mov byte [0x64e47], 0x82
 ret
