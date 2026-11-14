; Register and remove x87 emulation with Windows or a DPMI host.
BITS 32
ORG 0x6ac6a

dos_setvect equ 0x603de
windows_emulator_active equ 0x1748d
dpmi_emulator_active equ 0x1748c
windows_emulator_state equ 0x28925c
dpmi_vendor equ 0x1eb0
emulator_handler equ 0x57e2c

install_dpmi_emulator:
    push ebx
    push ecx
    push esi
    push edi
    push es
    push ebp
    push edx
    mov ebp, eax
    mov ax, 0x1600
    int 0x2f
    test al, al
    je short check_dpmi_emulator
    cmp al, 0x80
    je short check_dpmi_emulator
    xor al, al
    xor edx, edx
    xor ecx, ecx
    xor ebx, ebx
    mov ah, 0xfa
    int 0x2f
    cmp ax, 0x666
    jne short check_dpmi_emulator
    mov al, 0x22
    xor edx, edx
    xor ecx, ecx
    xor ebx, ebx
    mov ah, 0xfa
    int 0x2f
    test ax, ax
    jne short check_dpmi_emulator
    mov dh, 1
    mov al, 0x1e
    xor ecx, ecx
    xor ebx, ebx
    mov byte [windows_emulator_active], dh
    xor edx, edx
    mov ah, 0xfa
    int 0x2f
    mov eax, cs
    mov ebx, windows_emulator_state
    mov edx, eax
    mov ecx, ebx
    mov al, 0x20
    shr ecx, 0x10
    mov ah, 0xfa
    int 0x2f
    mov al, 1
    jmp short restore_install_registers

check_dpmi_emulator:
    mov edx, dword [esp]
    test ebp, ebp
    jne short query_dpmi_vendor
    test dx, dx
    je short return_not_windows

query_dpmi_vendor:
    mov esi, dpmi_vendor
    mov eax, 0xa00
    push es
    int 0x31
    sbb eax, eax
    pop es
    test eax, eax
    jne short return_not_windows
    mov eax, 7
    mov ebx, emulator_handler
    mov ecx, cs
    call dos_setvect
    mov es, [esp]
    mov ah, byte es:[ebp + 0x40]
    mov byte es:[ebp + 0x3e], 1
    or ah, 4
    mov byte es:[ebp + 0x40], ah
    mov eax, cr0
    or al, 4
    mov dl, 1
    mov cr0, eax
    mov ah, 0x30
    int 0x21
    mov byte [dpmi_emulator_active], dl

return_not_windows:
    xor al, al

restore_install_registers:
    add esp, 4
    pop ebp
    pop es
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

remove_dpmi_emulator:
    push ebx
    push ecx
    push es
    mov es, edx
    mov dl, byte [windows_emulator_active]
    test dl, dl
    je short check_dpmi_restore
    mov eax, cs
    mov edx, eax
    xor ecx, ecx
    xor ebx, ebx
    mov al, 0x21
    mov ah, 0xfa
    int 0x2f
    mov al, 0x1f
    xor edx, edx
    xor ecx, ecx
    xor ebx, ebx
    mov ah, 0xfa
    int 0x2f
    mov al, 1
    pop es
    pop ecx
    pop ebx
    ret

check_dpmi_restore:
    cmp byte [dpmi_emulator_active], 0
    je short return_not_windows_restore
    mov bl, byte es:[eax + 0x40]
    mov byte es:[eax + 0x3e], dl
    and bl, 0xfb
    mov byte es:[eax + 0x40], bl
    mov eax, cr0
    and al, 0xfb
    mov cr0, eax
    mov ah, 0x30
    int 0x21

return_not_windows_restore:
    xor al, al
    pop es
    pop ecx
    pop ebx
    ret
