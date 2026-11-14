; Detect x87 support and supply adjacent CRT helpers.
BITS 32
ORG 0x6463b

init_fpu_callbacks equ 0x64600
fpu_type equ 0x141a8
fpu_present equ 0x141a9
skip_fpu_type_update equ 0x14498

probe_fpu:
    push edx
    mov ah, byte [fpu_type]
    test ah, ah
    jne short restore_probe_register
    mov byte [fpu_present], ah
    db 0x2b, 0xc0 ; SUB EAX, EAX uses the register-destination opcode.
    push eax
    fninit
    fnstcw word [esp]
    pop eax
    db 0x8a, 0xc4 ; MOV AL, AH uses the register-destination opcode.
    xor dl, dl
    cmp al, 3
    jne short check_update_flag
    call init_fpu_callbacks
    mov dl, al

check_update_flag:
    cmp byte [skip_fpu_type_update], 0
    jne short restore_probe_register
    mov byte [fpu_type], dl
    mov byte [fpu_present], dl

restore_probe_register:
    pop edx
    ret

tolower_:
    cmp eax, 0x41
    jl short return_character
    cmp eax, 0x5a
    jg short return_character
    add eax, 0x20

return_character:
    ret

set_permission_denied:
    mov eax, 0xd

; Fall through to set_errno at 0x6468e.
