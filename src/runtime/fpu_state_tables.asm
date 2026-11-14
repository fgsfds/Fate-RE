; Emulator tables indexed by the physical x87 register offset (TOP * 10).
BITS 32
ORG 0x67a4e

%assign slot 0
%rep 8
    dw ((slot + 1) & 7) * 10, ((slot - 1) & 7) * 10, slot << 11
    dd slot
    %assign slot slot + 1
%endrep

; Clear the slot tag, or encode zero, valid, special and empty.
%assign shift 0
%rep 8
    dw ~(3 << shift) & 0xffff, 1 << shift, 0, 2 << shift, 3 << shift
    %assign shift shift + 2
%endrep

; Status high-byte condition bits for comparisons and FXAM classes.
    db 0x01, 0x40, 0x00, 0x45
    db 0x00, 0x02, 0x40, 0x42, 0x01, 0x03, 0x41, 0x43
