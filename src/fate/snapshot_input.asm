; Save the current clock and active players' five-byte input records.
BITS 32
ORG 0x2d1bd
clock equ 0x287e88
saved_clock equ 0x3cee
first_player equ 0x19028a
next_player equ 0x18fd78
frame_index equ 0x770c4
current_input equ 0x5ac3c
input_history equ 0x55bbc

snapshot_input_:
    push ebx
    push ecx
    push edx
    mov eax,[clock]
    movsx ebx,word [first_player]
    mov [saved_clock],eax
    jmp .test
.player:
    mov ecx,[frame_index]
    mov edx,ecx
    mov eax,ebx
    shl edx,2
    shl eax,2
    add edx,ecx
    add eax,ebx
    shl edx,4
    add edx,eax
    mov cl,[eax+current_input]
    mov [edx+input_history],cl
    mov cl,[eax+current_input+1]
    mov [edx+input_history+1],cl
    mov cl,[eax+current_input+2]
    mov ax,[eax+current_input+3]
    mov [edx+input_history+2],cl
    movsx ebx,word [nosplit ebx*2+next_player]
    mov [edx+input_history+3],ax
.test:
    test ebx,ebx
    jge .player
    mov eax,[frame_index]
    inc eax
    and eax,255
    mov [frame_index],eax
    pop edx
    pop ecx
    pop ebx
    ret
