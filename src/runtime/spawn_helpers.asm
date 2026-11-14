; Probe executable files and marshal arguments for the DOS spawn backend.
BITS 32
ORG 0x64035

find_first equ 0x67572
measure_argument_block equ 0x6773b
spawn_backend equ 0x67790

probe_executable:
    push ebx
    push edx
    enter 0x2c, 0
    mov edx, 7
    lea ebx, [ebp - 0x2c]
    call find_first
    test eax, eax
    sete al
    movzx eax, al
    leave
    pop edx
    pop ebx
    ret

prepare_spawn:
    push esi
    push edi
    enter 4, 0
    push eax
    mov esi, edx
    mov edi, ebx
    mov [ebp - 4], ecx
    mov eax, edx
    xor ecx, ecx
    mov edx, [ebp + 0x10]
    call measure_argument_block
    push dword [ebp + 0x10]
    push dword [ebp - 4]
    push edi
    push esi
    push dword [ebp - 8]
    call spawn_backend
    add esp, 0x14
    leave
    pop edi
    pop esi
    ret 4
