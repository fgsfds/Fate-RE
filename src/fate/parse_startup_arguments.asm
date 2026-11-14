; Parse startup arguments.
BITS 32
ORG 0x37524

map_extension equ 0xb79
extension_separator equ 0xb7e
command_line_options equ 0x12d18
argument_count equ 0x1419c
argument_vector equ 0x141a0
startup_shared_return equ 0x374b1
print_command_line_help equ 0x374b8
strcpy equ 0x60333
stricmp equ 0x62d95
strupr equ 0x62efc
strstr equ 0x62f1b
strtok equ 0x62fdd
force_video_setup equ 0x173d48

parse_startup_arguments:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    sub esp, 0x4
    mov ebx, eax
    mov byte [eax], 0x0
    mov eax, [argument_count]
    mov edi, [argument_vector]
    mov [esp], eax
    cmp eax, 0x2
    jl near .branch_375e1
    mov ebp, [esp]
    xor esi, esi

.branch_3754e:
    mov ecx, 0x1
    jmp near .branch_375d3

.branch_37558:
    mov eax, ecx
    mov eax, [edi + eax*4]
    xor edx, edx
    mov dl, [eax]
    cmp edx, 0x2d
    jz short .branch_375a0
    cmp edx, 0x2f
    jz short .branch_375a0
    cmp byte [ebx], 0x0
    jnz short .branch_375d2
    mov edx, eax
    mov eax, ebx
    call strcpy
    mov eax, ebx
    mov edx, map_extension
    call strupr
    mov eax, ebx
    call strstr
    test eax, eax
    jz short .branch_375d2
    mov edx, extension_separator
    mov eax, ebx
    call strtok
    mov ebx, eax
    jmp short .branch_375d2

.branch_375a0:
    mov eax, ecx
    mov eax, [edi + eax*4]
    mov edx, [nosplit esi*4 + command_line_options]
    inc eax
    call stricmp
    test eax, eax
    jnz short .branch_375d2
    test esi, esi
    jna short .branch_375c1
    cmp esi, 0x2
    jna short .branch_375cd
    jmp short .branch_375d2

.branch_375c1:
    mov dword [force_video_setup], 0x1
    jmp short .branch_375d2

.branch_375cd:
    call print_command_line_help

.branch_375d2:
    inc ecx

.branch_375d3:
    cmp ecx, ebp
    jl short .branch_37558
    inc esi
    cmp esi, 0x3
    jl near .branch_3754e

.branch_375e1:
    add esp, 0x4
    jmp near startup_shared_return
