; Apply mouse button binding.
BITS 32
ORG 0x3a9aa

key_forward equ 0x1363d
frame_state_139f4 equ 0x139f4
frame_state_13a89 equ 0x13a89
frame_state_13a8d equ 0x13a8d
key_state equ 0x6793c
input_actions equ 0x7defc

apply_mouse_button_binding:
    push ebx
    push ecx
    push edx
    mov ebx, eax
    mov edx, [frame_state_13a89]
    cmp edx, -1
    jz short .branch_3a9d8
    mov al, [edx + key_forward]
    mov ecx, 0xffffffff
    and eax, strict dword 0xff
    xor dl, dl
    mov [frame_state_13a89], ecx
    mov [eax + key_state], dl

.branch_3a9d8:
    test bx, bx
    jz near .branch_3aaa5
    mov eax, ebx
    xor ah, bh
    and al, 0x1
    cwde
    test eax, eax
    jz short .branch_3a9f0
    xor ebx, ebx
    jmp short .branch_3aa08

.branch_3a9f0:
    xor bh, bh
    and bl, 0x2
    movsx eax, bx
    test eax, eax
    jz short .branch_3aa03
    mov ebx, 0x2
    jmp short .branch_3aa08

.branch_3aa03:
    mov ebx, 0x1

.branch_3aa08:
    xor eax, eax

.branch_3aa0a:
    movsx edx, bx
    mov dl, [edx + frame_state_139f4]
    and edx, strict dword 0xff
    cmp edx, eax
    jnz near .branch_3aa9b
    xor edx, eax
    mov dl, [eax + key_forward]
    cmp edx, 0x6
    jz short .branch_3aa82
    cmp edx, 0x12
    jz short .branch_3aa82
    mov eax, ebx
    xor ah, bh
    and al, 0x1
    movsx edx, ax
    mov ax, [frame_state_13a8d]
    xor ah, ah
    and al, 0x1
    cwde
    cmp edx, eax
    setg al
    xor ah, ah
    mov dx, [input_actions]
    shl eax, byte 0xb
    or edx, eax
    mov eax, edx
    xor al, dl
    and ah, 0x8
    mov [frame_state_13a8d], bx
    cwde
    mov [input_actions], dx
    test eax, eax
    jng short .branch_3aaa5
    and bl, 0xfe
    mov [frame_state_13a8d], bx
    pop edx
    pop ecx
    pop ebx
    ret

.branch_3aa82:
    xor edx, edx
    mov dl, [eax + key_forward]
    mov bl, 0x1
    mov [frame_state_13a89], eax
    mov [edx + key_state], bl
    pop edx
    pop ecx
    pop ebx
    ret

.branch_3aa9b:
    inc eax
    cmp eax, 0x19
    jl near .branch_3aa0a

.branch_3aaa5:
    pop edx
    pop ecx
    pop ebx
    ret
