; Initialize VESA mode.
BITS 32
ORG 0x43d0c

vesa_request_signature equ 0x19e2
vesa_reply_signature equ 0x19e7
vesa_not_supported_message equ 0x19ec
vesa_mode_not_found_message equ 0x19fd
software_framebuffer equ 0x13ff0
vesa_probe_attempted equ 0x13ff4
vesa_pm_set_window equ 0x13ff5
vesa_pm_set_display_start equ 0x13ff9
print_diagnostic equ 0x40bb4
dpmi_real_mode_interrupt equ 0x4380a
dpmi_real_mode_far_call equ 0x438f9
allocate_video_dos_memory equ 0x43a50
query_vesa_mode equ 0x43b28
map_video_memory equ 0x43b71
restore_ebp_edi_esi_ecx_ebx equ 0x50347
runtime_exit equ 0x60353
memcpy equ 0x6329a
memcmp equ 0x632bf
divide_with_remainder equ 0x632e8
vesa_controller_info equ 0x1ec2a0
vesa_mode_list_far_pointer equ 0x1ec2ae
page_offset_remainders equ 0x1ec49c
page_offset_quotients equ 0x1ec49e
linear_page_addresses equ 0x1ec5a0
vesa_mode_list equ 0x1ec720
skip_bank_switch equ 0x286b54
mapped_video_base equ 0x286b58
bank_shift equ 0x286b5c
linear_framebuffer_enabled equ 0x286b60
video_pitch equ 0x286b64
video_width equ 0x286b68
video_page_size equ 0x286b70
draw_page_address equ 0x286b74
video_page_count equ 0x286b78
video_height equ 0x286b7c
use_software_framebuffer equ 0x286b84
framebuffer_offset equ 0x288116
framebuffer_selector equ 0x28811a

initialize_vesa_mode:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    sub esp, strict dword 0x120
    mov esi, eax
    mov edi, edx
    cmp byte [vesa_probe_attempted], 0x0
    jnz near .branch_43dd9
    mov dl, 0x1
    mov ebx, 0x4
    mov eax, vesa_controller_info
    mov [vesa_probe_attempted], dl
    mov edx, vesa_request_signature
    call memcpy
    mov edx, 0x4f00
    mov ebx, 0x200
    lea eax, [esp + 0x100]
    mov [esp + 0x100], dx
    mov edx, vesa_controller_info
    call allocate_video_dos_memory
    xor eax, eax
    mov ax, [esp + 0x100]
    cmp eax, 0x4f
    jnz short .branch_43d8e
    mov ebx, 0x4
    mov edx, vesa_reply_signature
    mov eax, vesa_controller_info
    call memcmp
    test eax, eax
    jz short .branch_43da0

.branch_43d8e:
    push strict dword vesa_not_supported_message
    call print_diagnostic
    add esp, 0x4
    jmp near .branch_44131

.branch_43da0:
    mov eax, [vesa_mode_list_far_pointer]
    mov edx, [vesa_mode_list_far_pointer]
    xor ax, ax
    and edx, strict dword 0xffff
    shr eax, byte 0xc
    add eax, edx
    mov edx, vesa_mode_list

.branch_43dbe:
    movsx ebx, word [eax]
    cmp ebx, -1
    jz short .branch_43dd4
    mov bx, [eax]
    add eax, 0x2
    mov [edx], bx
    add edx, 0x2
    jmp short .branch_43dbe

.branch_43dd4:
    mov word [edx], 0xffff

.branch_43dd9:
    mov ebx, vesa_mode_list
    mov [video_width], esi
    mov [video_height], edi
    jmp near .branch_4410f

.branch_43def:
    mov edx, esp
    call query_vesa_mode
    test eax, eax
    jz near .branch_4410c
    xor eax, eax
    mov al, [esp + 0x1b]
    cmp eax, 0x4
    jnz near .branch_4410c
    xor eax, eax
    mov al, [esp + 0x19]
    cmp eax, 0x8
    jnz near .branch_4410c
    xor eax, eax
    mov al, [esp + 0x18]
    cmp eax, 0x1
    jnz near .branch_4410c
    movsx eax, word [esp + 0x12]
    cmp eax, esi
    jnz near .branch_4410c
    movsx eax, word [esp + 0x14]
    cmp eax, edi
    jnz near .branch_4410c
    movsx eax, word [esp + 0x10]
    mov [video_pitch], eax
    xor eax, eax
    mov al, [esp + 0x1d]
    inc eax
    cmp eax, 0x40
    jl short .branch_43e60
    mov eax, 0x40

.branch_43e60:
    mov [video_page_count], eax
    mov eax, [esp]
    mov ecx, 0x4f02
    xor ah, ah
    mov [esp + 0x100], cx
    and al, 0x80
    mov dx, [ebx]
    shl eax, byte 0x7
    lea ebx, [esp + 0x100]
    or edx, eax
    mov eax, 0x10
    mov [esp + 0x102], dx
    lea edx, [esp + 0x100]
    lea ecx, [esp + 0x110]
    call dpmi_real_mode_interrupt
    mov eax, 0x4f0a
    lea ebx, [esp + 0x100]
    xor edx, edx
    mov [esp + 0x100], ax
    mov [esp + 0x102], dx
    mov [esp + 0x104], dx
    mov [esp + 0x106], dx
    lea edx, [esp + 0x100]
    mov eax, 0x10
    call dpmi_real_mode_far_call
    xor eax, eax
    mov ax, [esp + 0x100]
    cmp eax, 0x4f
    jnz short .branch_43f24
    xor eax, eax
    xor ebx, ebx
    mov ax, [esp + 0x110]
    mov bx, [esp + 0x10a]
    shl eax, byte 0x4
    add ebx, eax
    movsx eax, word [ebx]
    add eax, ebx
    mov [vesa_pm_set_window], eax
    movsx eax, word [ebx + 0x2]
    add eax, ebx
    mov [vesa_pm_set_display_start], eax

.branch_43f24:
    mov eax, [esp]
    xor ah, ah
    and al, 0x80
    cwde
    test eax, eax
    jz near .branch_43fb2
    mov eax, [esp + 0x28]
    mov esi, 0x1
    call map_video_memory
    mov edi, [video_page_count]
    mov [framebuffer_selector], dx
    mov [framebuffer_offset], eax
    mov [linear_framebuffer_enabled], esi
    cmp edi, esi
    setng al
    and eax, strict dword 0xff
    mov ebp, [video_height]
    mov [use_software_framebuffer], eax
    mov eax, [video_pitch]
    imul eax, ebp
    xor ecx, ecx
    mov [video_page_size], eax
    mov eax, [mapped_video_base]
    xor ebx, ebx
    mov [draw_page_address], eax
    mov eax, [video_page_count]
    jmp short .branch_43fa9

.branch_43f91:
    mov edx, [mapped_video_base]
    add edx, ecx
    mov [nosplit ebx*4 + linear_page_addresses], edx
    mov edx, [video_page_size]
    inc ebx
    add ecx, edx

.branch_43fa9:
    cmp ebx, eax
    jl short .branch_43f91
    jmp near .branch_440b7

.branch_43fb2:
    mov eax, [esp + 0x4]
    cmp ax, strict word 0x8
    jc short .branch_43fe0
    jna near .branch_4401a
    cmp ax, strict word 0x20
    jc short .branch_43fd5
    jna short .branch_44002
    cmp ax, strict word 0x40
    jz short .branch_43ff8
    jmp near .branch_44048

.branch_43fd5:
    cmp ax, strict word 0x10
    jz short .branch_4400e
    jmp near .branch_44048

.branch_43fe0:
    cmp ax, strict word 0x2
    jc short .branch_43ff0
    jna short .branch_44032
    cmp ax, strict word 0x4
    jz short .branch_44026
    jmp short .branch_44048

.branch_43ff0:
    cmp ax, strict word 0x1
    jz short .branch_4403e
    jmp short .branch_44048

.branch_43ff8:
    xor edx, edx
    mov [bank_shift], edx
    jmp short .branch_44048

.branch_44002:
    mov dword [bank_shift], 0x1
    jmp short .branch_44048

.branch_4400e:
    mov dword [bank_shift], 0x2
    jmp short .branch_44048

.branch_4401a:
    mov dword [bank_shift], 0x3
    jmp short .branch_44048

.branch_44026:
    mov dword [bank_shift], 0x4
    jmp short .branch_44048

.branch_44032:
    mov dword [bank_shift], 0x5
    jmp short .branch_44048

.branch_4403e:
    mov dword [bank_shift], 0x6

.branch_44048:
    xor ecx, ecx
    mov [linear_framebuffer_enabled], ecx
    cmp esi, strict dword 0x140
    jnz short .branch_44087
    cmp edi, strict dword 0xc8
    jnz short .branch_44087
    cmp dword [video_page_count], 0x2
    jl short .branch_44087
    mov edx, 0x10000
    mov ebx, 0xa0000
    mov [use_software_framebuffer], ecx
    mov [video_page_size], edx
    mov [draw_page_address], ebx
    jmp short .branch_440ad

.branch_44087:
    mov eax, [video_pitch]
    imul eax, [video_height]
    mov edi, 0x1
    mov [video_page_size], eax
    mov eax, [software_framebuffer]
    mov [use_software_framebuffer], edi
    mov [draw_page_address], eax

.branch_440ad:
    mov dword [video_page_count], 0x1

.branch_440b7:
    mov eax, [use_software_framebuffer]
    xor ecx, ecx
    xor ebx, ebx
    mov [skip_bank_switch], eax
    jmp short .branch_44102

.branch_440c7:
    lea esi, [esp + 0x118]
    mov edx, [video_pitch]
    mov eax, ecx
    call divide_with_remainder
    inc ebx
    mov eax, [esp + 0x11c]
    mov edi, [video_page_size]
    mov [nosplit ebx*4 + page_offset_remainders], ax
    mov eax, [esp + 0x118]
    add ecx, edi
    mov [nosplit ebx*4 + page_offset_quotients], ax

.branch_44102:
    cmp ebx, [video_page_count]
    jl short .branch_440c7
    jmp short .branch_44131

.branch_4410c:
    add ebx, 0x2

.branch_4410f:
    movsx eax, word [ebx]
    cmp eax, -1
    jnz near .branch_43def
    push edi
    push esi
    push strict dword vesa_mode_not_found_message
    call print_diagnostic
    add esp, 0xc
    xor eax, eax
    call runtime_exit

.branch_44131:
    add esp, strict dword 0x120
    jmp near restore_ebp_edi_esi_ecx_ebx
