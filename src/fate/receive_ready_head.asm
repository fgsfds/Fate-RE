; Original retained gap: Original readiness connecthead load, peer flag store and sender comparison; CX remains the lead index.
BITS 32
ORG 0x32717

first_player equ 0x19028a
frame_state_20a1c equ 0x20a1c

receive_ready_head:
    mov cx, [first_player]
    mov [eax + frame_state_20a1c], dl
    cmp cx, [esp + 0xc]
