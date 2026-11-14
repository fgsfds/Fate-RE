; Split and assemble DOS paths and adapt spawn arguments.
BITS 32
ORG 0x6785e

spawnve equ 0x64087
search_and_spawn equ 0x6e7a1
errno_value equ 0x289258
dos_error_value equ 0x289254
environment_vector equ 0x173d8

copy_path_part:
    push esi
    push edi
    mov esi, ebx
    test eax, eax
    jne short measure_part
    mov eax, edx
    pop edi
    pop esi
    ret

measure_part:
    mov ebx, ecx
    sub ebx, esi
    mov dword [eax], edx
    cmp ebx, strict dword 0x93
    jb short copy_part
    mov ebx, 0x92

copy_part:
    mov edi, edx
    mov ecx, ebx
    push es
    mov eax, ds
    mov es, eax
    push edi
    mov eax, ecx
    shr ecx, 2
    db 0xf2 ; Original repeat prefix.
    movsd
    db 0x8a, 0xc8 ; MOV CL, AL uses the register-destination opcode.
    and cl, 3
    db 0xf2 ; Original repeat prefix.
    movsb
    pop edi
    pop es
    lea eax, [edx + ebx]
    mov byte [eax], 0
    inc eax
    pop edi
    pop esi
    ret

split_path:
    push esi
    push edi
    push ebp
    mov esi, eax
    cmp byte [eax], 0
    je short write_empty_drive
    cmp byte [esi + 1], 0x3a
    jne short write_empty_drive
    test ebx, ebx
    je short skip_drive
    mov dword [ebx], edx
    mov al, byte [esi]
    mov byte [edx + 1], 0x3a
    mov byte [edx + 2], 0
    mov byte [edx], al
    add edx, 3

skip_drive:
    add esi, 2
    jmp short start_scan

write_empty_drive:
    test ebx, ebx
    je short start_scan
    mov dword [ebx], edx
    mov byte [edx], 0
    inc edx

start_scan:
    mov ebp, esi
    mov ebx, esi

reset_extension:
    xor edi, edi

scan_path:
    mov al, byte [esi]
    test al, al
    je short copy_directory
    cmp al, 0x2e
    jne short check_separator
    mov edi, esi
    inc esi
    jmp short scan_path

check_separator:
    inc esi
    cmp al, 0x5c
    je short advance_directory_end
    cmp al, 0x2f
    jne short scan_path

advance_directory_end:
    mov ebp, esi
    jmp short reset_extension

copy_directory:
    mov eax, ecx
    mov ecx, ebp
    call copy_path_part
    mov edx, eax
    test edi, edi
    jne short copy_basename
    mov edi, esi

copy_basename:
    mov eax, dword [esp + 0x10]
    mov ebx, ebp
    mov ecx, edi
    call copy_path_part
    mov edx, eax
    mov ebx, edi
    mov ecx, esi
    mov eax, dword [esp + 0x14]
    call copy_path_part
    pop ebp
    pop edi
    pop esi
    ret 8

path_noop:
    ret

normalize_separator:
    cmp al, 0x5c
    je short check_saved_separator
    cmp al, 0x2f
    jne short return_separator

check_saved_separator:
    cmp byte [edx], 0
    jne short use_saved_separator
    mov byte [edx], al

use_saved_separator:
    mov al, byte [edx]

return_separator:
    ret

make_path:
    push esi
    push edi
    sub esp, 4
    mov edi, dword [esp + 0x10]
    mov esi, eax
    xor ah, ah
    mov byte [esp], ah
    test edx, edx
    je short terminate_drive
    mov al, byte [edx]
    test al, al
    je short terminate_drive
    mov byte [esi], al
    inc esi
    mov byte [esi], 0x3a
    inc esi

terminate_drive:
    mov byte [esi], 0
    test ebx, ebx
    je short check_separator_default
    cmp byte [ebx], 0
    je short check_separator_default

copy_directory_byte:
    xor eax, eax
    mov edx, esp
    mov al, byte [ebx]
    inc ebx
    call normalize_separator
    mov byte [esi], al
    mov dl, byte [ebx]
    inc esi
    test dl, dl
    jne short copy_directory_byte
    cmp byte [esp], 0
    jne short match_directory_separator
    mov byte [esp], 0x5c

match_directory_separator:
    mov bh, byte [esp]
    cmp bh, byte [esi - 1]
    jne short append_separator
    dec esi
    jmp short check_separator_default

append_separator:
    mov byte [esi], bh

check_separator_default:
    cmp byte [esp], 0
    jne short check_basename
    mov byte [esp], 0x5c

check_basename:
    lea ebx, [esi + 1]
    test ecx, ecx
    je short skip_basename
    xor eax, eax
    mov edx, esp
    mov al, byte [ecx]
    call normalize_separator
    mov dh, byte [esp]
    cmp al, dh
    je short scan_basename
    cmp dh, byte [esi]
    jne short scan_basename
    mov esi, ebx

scan_basename:
    mov dl, byte [ecx]
    test dl, dl
    je short check_extension
    xor eax, eax
    mov al, dl
    mov edx, esp
    inc ecx
    call normalize_separator
    mov byte [esi], al
    inc esi
    jmp short scan_basename

skip_basename:
    mov dl, byte [esp]
    cmp dl, byte [esi]
    jne short check_extension
    mov esi, ebx

check_extension:
    test edi, edi
    je short terminate_path
    mov dh, byte [edi]
    test dh, dh
    je short terminate_path
    cmp dh, 0x2e
    je short copy_extension
    mov byte [esi], 0x2e

advance_extension_output:
    inc esi

copy_extension:
    mov bh, byte [edi]
    test bh, bh
    je short terminate_path
    inc edi
    mov byte [esi], bh
    jmp short advance_extension_output

terminate_path:
    mov byte [esi], 0
    add esp, 4
    pop edi
    pop esi
    ret 4

get_errno_address:
    mov eax, errno_value
    ret

get_dos_error_address:
    mov eax, dos_error_value
    ret

spawn_with_arguments:
    push ebx
    push ecx
    push edx
    mov eax, dword [esp + 0x10]
    mov edx, dword [esp + 0x14]
    lea ebx, [esp + 0x18]
    mov ecx, dword [environment_vector]
    call spawnve
    pop edx
    pop ecx
    pop ebx
    ret

spawn_with_path_search:
    push ecx
    mov ecx, dword [environment_vector]
    call search_and_spawn
    pop ecx
    ret
