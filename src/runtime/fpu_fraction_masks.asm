; Masks for the low 31 down to zero fractional bits.
BITS 32
ORG 0x69de3

%assign bits 31
%rep 32
    dd (1 << bits) - 1
    %assign bits bits - 1
%endrep
