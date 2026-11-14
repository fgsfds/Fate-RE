; Default Watcom stream slots and the following runtime workspace.
BITS 32
ORG 0x1424e

    times 6 db 0
%macro static_stream 2
    times 12 db 0
    dd %1, %2
    times 6 db 0
%endmacro
    static_stream 1, 0
    static_stream 2, 1
    static_stream 2, 2
    static_stream 3, 3
    static_stream 2, 4
    times 0x1445c - 0x1424e - ($ - $$) db 0
    db 'a'
