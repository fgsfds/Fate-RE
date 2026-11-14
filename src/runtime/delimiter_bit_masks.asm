; Bit positions used by the delimiter bitmap routines.
BITS 32

%assign bit 0
%rep 8
    db 1 << bit
%assign bit bit + 1
%endrep
