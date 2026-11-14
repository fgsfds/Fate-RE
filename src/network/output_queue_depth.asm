; Return the number of queued serial bytes for the active transport.
BITS 32
ORG 0x436fa
transport equ 0x13cde
write_index equ 0x18fdd0
read_index equ 0x18fdd8
startcom equ 0x4204f

output_queue_depth_:
    push edx
    xor eax,eax
    mov al,[transport]
    cmp eax,1
    jl .inactive
    cmp eax,4
    jg .inactive
    call startcom
    mov eax,[write_index]
    movsx edx,word [eax]
    mov eax,[read_index]
    movsx eax,word [eax]
    sub edx,eax
    lea eax,[edx+16384]
    and eax,16383
    pop edx
    ret
.inactive:
    xor eax,eax
    pop edx
    ret
