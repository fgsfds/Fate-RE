; DPMI video memory allocation and mapping diagnostics.
BITS 32
ORG 0x1944

    db 'DPMI_allocRealSeg failed!', 10, 0
    db 'DPMI_allocSelector() failed!', 10, 0
    db 'DPMI_mapPhysicalToLinear() failed!', 10, 0
    db 'DPMI_setSelectorBase() failed!', 10, 0
    db 'DPMI_setSelectorLimit() failed!', 10, 0
