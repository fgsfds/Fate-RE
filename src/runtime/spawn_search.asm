; Try the requested executable, then search DOS PATH entries.
BITS 32
ORG 0x6e7a1

check_stack equ 0x67018
spawnve equ 0x64087
get_errno_address equ 0x67a09
getenv equ 0x63fb5
strlen equ 0x60381
strchr equ 0x6e8f8
set_errno equ 0x6468e
set_runtime_error equ 0x646b1
memcpy equ 0x63245
path_variable equ 0x1f18

search_and_spawn:
    push strict dword 0xb4
    call check_stack
    push esi
    push edi
    enter 0xa0, 0
    push eax
    sub ebp, strict dword 0x82
    mov esi, edx
    mov dword [ebp + 0x7a], ebx
    mov dword [ebp + 0x76], ecx
    call spawnve
    mov ecx, eax
    mov edx, eax
    cmp eax, -1
    jne near return_result
    call get_errno_address
    cmp dword [eax], 1
    jne near return_result
    cmp byte [esi], 0x5c
    je near return_result
    cmp byte [esi], 0
    je near return_result
    cmp byte [esi + 1], 0x3a
    je near return_result
    mov eax, path_variable
    call getenv
    mov ebx, eax
    test eax, eax
    jne short measure_program_name
    mov eax, ecx
    jmp near restore_frame

measure_program_name:
    mov eax, esi
    call strlen
    inc eax
    mov dword [ebp + 0x7e], eax
    mov eax, 0x90
    sub eax, dword [ebp + 0x7e]
    mov dword [ebp + 0x72], eax

check_path_component:
    cmp byte [ebx], 0
    je near return_result
    mov edx, 0x3b
    mov eax, ebx
    call strchr
    mov edi, eax
    test eax, eax
    jne short measure_path_component
    mov eax, ebx
    call strlen
    lea edi, [ebx + eax]

measure_path_component:
    mov ecx, edi
    sub ecx, ebx
    cmp ecx, dword [ebp + 0x72]
    jbe short copy_directory
    mov eax, 2
    call set_errno
    mov eax, 0xa
    call set_runtime_error
    mov eax, 0xffffffff
    jmp short restore_frame

copy_directory:
    lea eax, [ebp - 0x1e]
    mov edx, ebx
    mov ebx, ecx
    call memcpy
    lea eax, [ebp - 0x1e]
    add eax, ecx
    cmp byte [eax - 1], 0x5c
    je short append_program_name
    mov byte [eax], 0x5c
    inc eax

append_program_name:
    mov ebx, dword [ebp + 0x7e]
    mov edx, esi
    mov ecx, dword [ebp + 0x76]
    call memcpy
    mov eax, dword [ebp - 0x22]
    lea edx, [ebp - 0x1e]
    mov ebx, dword [ebp + 0x7a]
    call spawnve
    mov edx, eax
    cmp eax, -1
    jne short return_result
    call get_errno_address
    cmp dword [eax], 1
    jne short return_result
    cmp byte [edi], 0x3b
    jne short return_result
    lea ebx, [edi + 1]
    jmp near check_path_component

return_result:
    mov eax, edx

restore_frame:
    lea esp, [dword ebp + 0x82]
    pop ebp
    pop edi
    pop esi
    ret
