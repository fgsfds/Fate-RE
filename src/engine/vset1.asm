; "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
; Ken Silverman's official web site: "http://www.advsys.net/ken"
; See the included license file "BUILDLIC.TXT" for license info.
; This file has been modified from Ken Silverman's original release
; NASM transcription of historical A_MASM single-column raster routines.
; Explicit ModR/M encoding selects the original legal load-direction form.
BITS 32
ORG 0x642d0
setupvlineasm_:
 mov byte [0x6432c],al
 mov byte [0x6434e],al
 mov byte [0x64605],al
 mov byte [0x645fa],al
 mov byte [0x645d7],al
 mov byte [0x645d2],al
 ret
