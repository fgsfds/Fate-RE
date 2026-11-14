; Lock and unlock the audio backend's linear code and data ranges.
BITS 32
ORG 0x65802

lock_memory_region equ 0x66391
unlock_memory_region equ 0x663ce
code_base equ 0x10000
data_base equ 0x80000

%macro apply_range 4
    mov edx, %1
    mov eax, %2
    sub eax, edx
    push eax
    mov eax, %1
    push eax
    call %3
    add esp, 8
    test eax, eax
    je short %%next
    mov dword [ebp - 4], 5
    jmp %4 .return
%%next:
%endmacro

%macro backend 1
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 4

    apply_range 0x661cd - code_base, 0x662cc - code_base, %1, near
    apply_range 0x662e1 - code_base, 0x6637b - code_base, %1, near
    apply_range 0x62429 - code_base, 0x62a82 - code_base, %1, near
    apply_range 0x6b0ea - code_base, 0x6bd4e - code_base, %1, near
    apply_range 0x6bd63 - code_base, 0x6bda2 - code_base, %1, near
    apply_range 0x6182b - code_base, 0x62185 - code_base, %1, near
    apply_range 0x65efb - code_base, 0x661b8 - code_base, %1, near
    apply_range 0x657ed - code_base, 0x65ee6 - code_base, %1, near
    apply_range 0x6219f - code_base, 0x62414 - code_base, %1, near
    apply_range 0x61768 - code_base, 0x61816 - code_base, %1, near
    apply_range 0x60b2b - code_base, 0x61258 - code_base, %1, near
    apply_range 0x66390 - code_base, 0x66b73 - code_base, %1, near
    apply_range 0x64cfc - code_base, 0x64f9d - code_base, %1, near
    apply_range 0x66b74 - code_base, 0x67005 - code_base, %1, near
    apply_range 0x6bdb8 - code_base, 0x6dcf9 - code_base, %1, near
    apply_range 0x6dcfc - code_base, 0x6e665 - code_base, %1, near
    apply_range 0x96534 - data_base, 0x96a98 - data_base, %1, near
    apply_range 0x96b0c - data_base, 0x96c02 - data_base, %1, short
    apply_range 0x944f8 - data_base, 0x96530 - data_base, %1, short
    apply_range 0x96c08 - data_base, 0x96c4c - data_base, %1, short

    mov dword [ebp - 4], 0
.return:
    mov eax, [ebp - 4]
    leave
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
%endmacro

initialize_audio_backend:
    backend lock_memory_region

shutdown_audio_backend:
    backend unlock_memory_region
