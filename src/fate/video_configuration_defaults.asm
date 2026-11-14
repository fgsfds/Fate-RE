; Configuration radix weights, option names and video mode defaults.
BITS 32
ORG 0x12cf4

%assign digit 0
%rep 8
    dd 1 << (digit * 4)
    %assign digit digit + 1
%endrep
    dd 255
    dd 0x960, 0x968, 0x96a, 0x96f, 0x984, 0x984
    dd 0x990, 0x996, 0x99b, 0x9a8, 0x9ae, 0x9b7
    dw 320, 360, 400, 200, 360, 400
    dw 0, 0, 1, 1, 2, 2
    dw 320, 640, 200, 480
    dw 0, 0, 1, 1
    dd 2, 320, 200, 0, 0
