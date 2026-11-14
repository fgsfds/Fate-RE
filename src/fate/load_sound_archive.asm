; Read the sound archive index.
BITS 32
ORG 0x34956

sound_index_memory_error equ 0x72a
sound_archive_filename equ 0x75a
sound_archive_open_error equ 0x761
report_error equ 0x26a03
malloc equ 0x6126d
memset equ 0x61350
open equ 0x61368
lseek equ 0x615b6
read equ 0x615f7
free equ 0x6170a
frame_state_16fb1c equ 0x16fb1c
frame_state_16fe2c equ 0x16fe2c
sound_archive_handle equ 0x1714e0
sound_index_buffer equ 0x171603

load_sound_archive:
    push ebx
    push ecx
    push edx
    push esi
    mov eax, 0x1000
    call malloc
    mov [sound_index_buffer], eax
    test eax, eax
    jnz short .branch_34977
    mov eax, sound_index_memory_error
    call report_error

.branch_34977:
    mov ebx, 0x1000
    mov eax, [sound_index_buffer]
    xor edx, edx
    call memset
    push strict dword 0x200
    push strict dword sound_archive_filename
    call open
    add esp, 0x8
    mov [sound_archive_handle], eax
    cmp eax, -1
    jnz short .branch_349ae
    mov eax, sound_archive_open_error
    call report_error

.branch_349ae:
    mov ebx, 0x2
    mov edx, 0xfffff000
    mov eax, [sound_archive_handle]
    call lseek
    mov ebx, 0x1000
    mov edx, [sound_index_buffer]
    mov eax, [sound_archive_handle]
    call read
    xor edx, edx

.branch_349d9:
    mov ebx, edx
    shl ebx, byte 0x2
    sub ebx, edx
    mov ecx, frame_state_16fe2c
    shl ebx, byte 0x2
    add ecx, ebx
    mov [nosplit edx*4 + frame_state_16fb1c], ecx
    mov ecx, [sound_index_buffer]
    mov ecx, [ecx + ebx]
    mov ebx, [nosplit edx*4 + frame_state_16fb1c]
    shl ecx, byte 0xc
    mov [ebx + 0x4], ecx
    mov ecx, edx
    shl ecx, byte 0x2
    sub ecx, edx
    mov ebx, [sound_index_buffer]
    shl ecx, byte 0x2
    xor esi, esi
    mov si, [ecx + ebx + 0x4]
    mov ebx, [nosplit edx*4 + frame_state_16fb1c]
    mov [ebx + 0x8], esi
    mov ebx, [sound_index_buffer]
    mov bx, [ecx + ebx + 0x8]
    mov eax, [nosplit edx*4 + frame_state_16fb1c]
    and ebx, strict dword 0xffff
    inc edx
    mov [eax], ebx
    cmp edx, strict dword 0xa4
    jl short .branch_349d9
    mov eax, [sound_index_buffer]
    call free
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
