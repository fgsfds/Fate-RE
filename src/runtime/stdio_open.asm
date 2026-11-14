; Parse stdio modes and open or reopen streams.
BITS 32
ORG 0x6040b

default_file_mode equ 0x1445d
open_streams equ 0x2891e0
closed_streams equ 0x2891dc
tolower equ 0x6467b
set_errno equ 0x6468e
sopen equ 0x6138c
free_stream equ 0x6476c
fseek equ 0x64805
check_tty equ 0x64901
allocate_stream equ 0x646c4
close_stream equ 0x608bb

__open_flags_:
    push ebx
    push ecx
    push edx
    sub esp, 4
    mov edx, eax
    xor eax, eax
    mov al, byte [edx]
    xor ebx, ebx
    call tolower
    mov byte [esp], al
    cmp al, 0x72
    je short .parse_modifiers
    cmp al, 0x77
    je short .parse_modifiers
    cmp al, 0x61
    je short .parse_modifiers
    mov eax, 9
    call set_errno
    xor eax, eax
    jmp near .restore_parser_registers

.parse_modifiers:
    mov eax, ebx
    mov cl, byte [edx + 1]
    or al, 3
    cmp cl, 0x2b
    jne short .parse_second_character
    mov ebx, eax
    mov cl, byte [edx + 2]
    or al, 0x40
    cmp cl, 0x62
    je short .set_binary
    cmp cl, 0x74
    je short .apply_access_flags
    cmp dword [default_file_mode], 0x200

.use_binary_if_equal:
    jne short .apply_access_flags

.set_binary:
    mov ebx, eax
    jmp short .apply_access_flags

.parse_second_character:
    mov ecx, ebx
    or cl, 0x40
    cmp byte [edx + 1], 0x62
    jne short .check_text_modifier
    mov al, byte [edx + 2]
    mov ebx, ecx
    cmp al, 0x2b
    jne short .apply_access_flags
    or cl, 3
    jmp short .save_mode_flags

.check_text_modifier:
    cmp byte [edx + 1], 0x74
    jne short .check_default_mode
    cmp byte [edx + 2], 0x2b
    jmp short .use_binary_if_equal

.check_default_mode:
    cmp dword [default_file_mode], 0x200
    jne short .apply_access_flags

.save_mode_flags:
    mov ebx, ecx

.apply_access_flags:
    mov al, byte [esp]
    cmp al, 0x77
    jne short .check_append
    or bl, 2
    jmp short .return_flags

.check_append:
    cmp al, 0x61
    jne short .set_read_flag
    or bl, 0x82
    jmp short .return_flags

.set_read_flag:
    or bl, 1

.return_flags:
    mov eax, ebx

.restore_parser_registers:
    add esp, 4
    pop edx
    pop ecx
    pop ebx
    ret

__doopen_:
    push esi
    push edi
    mov esi, eax
    and byte [ecx + 0xc], 0xfc
    mov eax, edx
    call __open_flags_
    mov edi, dword [ecx + 0xc]
    or edi, eax
    xor eax, eax
    mov dword [ecx + 0xc], edi
    mov al, byte [edx]
    call tolower
    mov dl, al
    cmp al, 0x72
    jne short .prepare_write_flags
    mov dh, byte [ecx + 0xc]
    xor eax, eax
    test dh, 2
    je short .select_read_translation
    mov eax, 2

.select_read_translation:
    test byte [ecx + 0xc], 0x40
    je short .set_read_text
    or ah, 2
    jmp short .push_read_permissions

.set_read_text:
    or ah, 1

.push_read_permissions:
    push 0
    jmp short .open_descriptor

.prepare_write_flags:
    test byte [ecx + 0xc], 1
    setne al
    and eax, 0xff
    add eax, 0x21
    cmp dl, 0x61
    jne short .set_truncate_flag
    or al, 0x10
    jmp short .select_write_translation

.set_truncate_flag:
    or al, 0x40

.select_write_translation:
    test byte [ecx + 0xc], 0x40
    je short .set_write_text
    or ah, 2
    jmp short .push_write_permissions

.set_write_text:
    or ah, 1

.push_write_permissions:
    push 0x180

.open_descriptor:
    push ebx
    push eax
    push esi
    call sopen
    add esp, 0x10
    mov dword [ecx + 0x10], eax
    cmp dword [ecx + 0x10], -1
    jne short .initialize_stream
    mov eax, ecx
    call free_stream
    xor eax, eax
    pop edi
    pop esi
    ret

.initialize_stream:
    mov dword [ecx + 4], 0
    mov dword [ecx + 8], 0
    mov dword [ecx + 0x14], 0
    cmp dl, 0x61
    jne short .finish_open
    mov ebx, 2
    mov eax, ecx
    xor edx, edx
    call fseek

.finish_open:
    mov eax, ecx
    call check_tty
    mov eax, ecx
    pop edi
    pop esi
    ret

_fsopen_:
    push ecx
    push esi
    mov esi, eax
    xor eax, eax
    call allocate_stream
    mov ecx, eax
    test eax, eax
    je short .return_allocated_stream
    mov eax, esi
    call __doopen_

.return_allocated_stream:
    pop esi
    pop ecx
    ret

fopen_:
    push ebx
    xor ebx, ebx
    call _fsopen_
    pop ebx
    ret

close_file_:
    push ebx
    push ecx
    push edx
    mov ebx, eax
    mov eax, dword [open_streams]

.check_open_stream:
    test eax, eax
    je short .start_closed_stream_search
    mov edx, dword [eax + 4]
    cmp ebx, edx
    jne short .next_open_stream
    test byte [edx + 0xc], 3
    je short .return_reusable_stream
    mov eax, edx
    mov edx, 1
    call close_stream

.return_reusable_stream:
    mov eax, ebx
    pop edx
    pop ecx
    pop ebx
    ret

.next_open_stream:
    mov eax, dword [eax]
    jmp short .check_open_stream

.start_closed_stream_search:
    mov edx, closed_streams

.check_closed_stream:
    mov eax, dword [edx]
    test eax, eax
    je short .report_bad_stream
    cmp ebx, dword [eax + 4]
    jne short .next_closed_stream
    mov ecx, dword [eax]
    mov dword [edx], ecx
    mov edx, dword [open_streams]
    mov dword [open_streams], eax
    mov dword [eax], edx
    jmp short .return_reusable_stream

.next_closed_stream:
    mov edx, eax
    jmp short .check_closed_stream

.report_bad_stream:
    mov eax, 4
    call set_errno
    xor eax, eax
    pop edx
    pop ecx
    pop ebx
    ret

freopen_:
    push ecx
    push esi
    mov esi, eax
    mov eax, ebx
    call close_file_
    mov ecx, eax
    test eax, eax
    je short .return_reopened_stream
    and dword [eax + 0xc], 0x4000
    mov eax, esi
    xor ebx, ebx
    call __doopen_

.return_reopened_stream:
    pop esi
    pop ecx
    ret
