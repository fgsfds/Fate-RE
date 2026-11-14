; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; Historical fixtransluscence semantic writes to original renderer instruction fields.
BITS 32
ORG 0x643a0
fixtransluscence_:
 mov dword [0x644f7], eax
 mov dword [0x64c7a], eax
 mov dword [0x64ce7], eax
 mov dword [0x64cfe], eax
 mov dword [0x64a1c], eax
 mov dword [0x64e2b], eax
 mov dword [0x64e31], eax
 mov dword [0x64dc4], eax
 mov dword [0x64e54], eax
 ret
