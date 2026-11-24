; Retained far-copy/BIOS tail following the C allocation phases.
BITS 32
ORG 0x43acf
frame_state_13fec equ 0x13fec
frame_state_286b80 equ 0x286b80
copy_far_memory equ 0x63272
dpmi_real_mode_far_call equ 0x438f9
allocate_video_dos_memory_tail:
    mov ax, [frame_state_286b80]
    push ebp
    mov word [esp + 0x28], ds
    mov ebx, edi
    mov [esp + 0x20], ax
    mov ecx, [esp + 0x28]
    mov word [esi + 0xa], 0x0
    xor eax, eax
    mov dx, [frame_state_13fec]
    call copy_far_memory
    lea ecx, [esp + 0x1c]
    mov eax, 0x10
    mov ebx, esi
    mov edx, esi
    call dpmi_real_mode_far_call
    mov edx, [esp + 0x24]
    mov cx, [frame_state_13fec]
    push ebp
    mov eax, edi
    xor ebx, ebx
    call copy_far_memory
    add esp, 0x28
    pop ebp
    pop edi
    pop esi
    pop ecx
    ret
