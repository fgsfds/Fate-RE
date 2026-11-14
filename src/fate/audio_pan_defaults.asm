; Initial input state, pan lookup and audio settings.
BITS 32
ORG 0x12c28

    dw 256, 0, 1
    dd -1, 0
    times 10 db 0

%assign pan 8
%rep 9
    dd pan * 4096
    %assign pan pan - 1
%endrep
    dd 4096, 8432
%assign pan 2
%rep 7
    dd pan * 4096
    %assign pan pan + 1
%endrep
    dd 28912
%assign pan 8
%rep 8
    dd pan * 4096
    %assign pan pan + 1
%endrep
    dd 65535
%assign pan 15
%rep 8
    dd pan * 4096
    %assign pan pan - 1
%endrep

    dd -1, 1, 1, 12, 12
    times 3 dd 0
