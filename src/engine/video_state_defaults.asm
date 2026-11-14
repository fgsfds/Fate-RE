; Build video, capture and ART defaults in their original packed layout.
BITS 32
ORG 0x13fe6

%macro pad_to 1
    times %1 - 0x13fe6 - ($ - $$) db 0
%endmacro

    dw 0
    dd 1024                     ; DOS buffer size.
    pad_to 0x14010
    dd 1                        ; New frame flag.
    pad_to 0x1401c
    db 0xff                     ; Cache lock.
    pad_to 0x14029

%assign bit 0
%rep 8
    db 1 << bit
    %assign bit bit + 1
%endrep
%assign bit 0
%rep 31
    dd 1 << bit
    %assign bit bit + 1
%endrep
    dd 0x7fffffff               ; Final mask excludes the sign bit.

    dd -1, -1                   ; Cached renderer values.
    pad_to 0x140c3
    db 0, 1, 2, 3, 4, 3, 2, 1  ; Palette search neighbor order.
    pad_to 0x140d5
    db 10, 5, 1, 8
    dd 0
    dw 319, 199, 320, 200       ; Initial capture bounds and dimensions.
%assign shade 0
%rep 16
    db shade, shade, shade
    %assign shade shade + 8
%endrep
    db 0, 1
    dw 320
    pad_to 0x14155

    db 0, 0, 0,  0, 0, 42,  0, 42, 0,  0, 42, 42
    db 42, 0, 0,  42, 0, 42,  42, 21, 0,  42, 42, 42
    db 21, 21, 21,  21, 21, 63,  21, 63, 21,  21, 63, 63
    db 63, 21, 21,  63, 21, 63,  63, 63, 21,  63, 63, 63

    pad_to 0x14187
    dd -1, -1                   ; ART file index and handle.
    pad_to 0x14198
    dd 32
    pad_to 0x141a4
