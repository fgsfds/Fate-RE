; Clear the frame counter and timing state.
BITS 32
ORG 0x4c0b0

totalclocklock equ 0x2863c0
frame_count equ 0x287e74
totalclock equ 0x287e88

reset_frame_timing:
    push edx
    xor edx, edx
    mov [frame_count], edx
    mov [totalclock], edx
    mov [totalclocklock], edx
    pop edx
    ret
