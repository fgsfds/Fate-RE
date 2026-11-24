; Legacy BIOS boundary: input DS at local frame+0x22 remains unspecified.
; Independent transfer/frame instructions are supplied by guarded C contexts.
BITS 32
ORG 0x43b06
allocate_video_dos_memory_bios_call:
    call 0x438f9
