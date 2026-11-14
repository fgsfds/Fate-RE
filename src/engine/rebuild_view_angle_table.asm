; Rebuild the per-column viewing angle table.
BITS 32
ORG 0x56e8f

restore_edi_esi_edx_ecx_ebx equ 0x4abbf
frame_state_1dcdde equ 0x1dcdde
view_width_reciprocal equ 0x286b04
frame_state_287e94 equ 0x287e94
frame_state_287e96 equ 0x287e96

rebuild_view_angle_table:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    sub esp, 0x4
    push eax
    mov eax, 0x140
    mov ebx, [view_width_reciprocal]
    imul ebx
    shrd eax, edx, byte 0x10
    xor esi, esi
    xor ecx, ecx
    mov [esp + 0x4], eax
    jmp short .branch_56efd

.branch_56eb3:
    mov ebx, [esp + 0x4]
    mov eax, esi
    mov edi, esi
    and eax, strict dword 0xffff
    sar edi, byte 0x10
    add esi, ebx
    test eax, eax
    jz short .branch_56ee7
    movsx ebx, word [nosplit edi*2 + frame_state_287e96]
    movsx edx, word [nosplit edi*2 + frame_state_287e94]
    sub ebx, edx
    mov edx, ebx
    mov ebx, eax
    mov eax, edx
    imul ebx
    shrd eax, edx, byte 0x10

.branch_56ee7:
    movsx edx, word [nosplit edi*2 + frame_state_287e94]
    add eax, edx
    inc ecx
    sar eax, byte 0x6
    mov [nosplit ecx*2 + frame_state_1dcdde], ax

.branch_56efd:
    cmp ecx, [esp]
    jl short .branch_56eb3
    add esp, 0x8
    jmp near restore_edi_esi_edx_ecx_ebx
