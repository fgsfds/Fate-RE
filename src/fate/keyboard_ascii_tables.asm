; Set 1 keyboard scan codes translated to ASCII for text entry.
BITS 32
ORG 0x3d04

%macro keypad_and_tail 1
    times 0x47 - ($ - %1) db 0
    db '789-456+1230.'
    times 128 - ($ - %1) db 0
%endmacro

unshifted:
    db 0, 0, '1234567890-=', 0, 0
    db 'qwertyuiop[]', 0, 0
    db "asdfghjkl;'", 0x60, 0, 0x5c
    db 'zxcvbnm,./', 0, '*', 0, ' '
    keypad_and_tail unshifted

shifted:
    db 0, 0, '!@#$%^&*()_+', 0, 0
    db 'QWERTYUIOP{}', 0, 0
    db 'ASDFGHJKL:"~', 0, '|'
    db 'ZXCVBNM<>?', 0, '*', 0, ' '
    keypad_and_tail shifted
