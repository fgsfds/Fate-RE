; Two columns of editable key bindings, with pointers into the display buffers.
BITS 32
ORG 0x13656

key_display_buffers equ 0x174268
%assign action 0
%rep 25
    db 1
    dw 0
    dd key_display_buffers + 30 * action
    times 8 db 0
%if action < 13
    dw 2, 20 + 10 * action
%else
    dw 162, 20 + 10 * (action - 13)
%endif
    dw 0
    %assign action action + 1
%endrep
