; Open DOS handles, set binary mode and seek.
BITS 32
ORG 0x6138c

file_creation_mask equ 0x16ab0
default_file_mode equ 0x1445d
isatty equ 0x656f3
set_errno equ 0x6468e
set_dos_errno equ 0x6571d
get_io_mode equ 0x65783
set_io_mode equ 0x657d8

sopen_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    sub esp, 0xc
    mov esi, dword [esp + 0x24]

.skip_leading_spaces:
    cmp byte [esi], 0x20
    jne short .open_existing_file
    inc esi
    jmp short .skip_leading_spaces

.open_existing_file:
    mov eax, dword [esp + 0x28]
    and eax, 0x83
    mov dword [esp], eax
    mov dl, byte [esp + 0x2c]
    mov al, byte [esp]
    or al, dl
    mov edx, esi
    mov edi, 0xffffffff
    mov ah, 0x3d
    int 0x21
    rcl eax, 1
    ror eax, 1
    mov dword [esp + 4], eax
    test eax, eax
    jl short .check_existing_handle
    xor edi, edi
    mov di, word [esp + 4]

.check_existing_handle:
    mov dh, byte [esp + 0x28]
    test dh, 3
    je near .check_create
    cmp edi, -1
    je short .check_create
    mov eax, edi
    call isatty
    test eax, eax
    jne short .check_create
    test byte [esp + 0x29], 4
    je short .check_truncate
    mov ebx, edi
    mov ah, 0x3e
    int 0x21
    rcl eax, 1
    ror eax, 1
    mov eax, 7
    call set_errno
    mov eax, 0xffffffff
    jmp near .restore_registers

.check_truncate:
    test dh, 0x40
    je short .check_create
    lea edx, [esp + 8]
    mov ebx, edi
    xor ecx, ecx
    mov ah, 0x40
    int 0x21
    rcl eax, 1
    ror eax, 1
    mov dword [esp + 4], eax
    test eax, eax
    jge short .check_create
    mov ebx, edi
    mov ah, 0x3e
    int 0x21
    rcl eax, 1
    ror eax, 1

.report_dos_error:
    xor eax, eax
    mov ax, word [esp + 4]
    call set_dos_errno
    jmp near .restore_registers

.check_create:
    cmp edi, -1
    jne near .read_handle_mode
    test byte [esp + 0x28], 0x20
    je short .report_dos_error
    cmp word [esp + 4], 2
    jne short .report_dos_error
    lea eax, [esp + 0x30]
    add eax, 4
    mov eax, dword [eax - 4]
    test eax, eax
    jne short .apply_creation_mask
    mov eax, 0x180

.apply_creation_mask:
    xor eax, dword [file_creation_mask]
    xor ecx, ecx
    test al, 0x80
    jne short .create_file
    mov ecx, 1

.create_file:
    mov edx, esi
    and ecx, strict dword 0xff
    mov ah, 0x3c
    int 0x21
    rcl eax, 1
    ror eax, 1
    mov dword [esp + 4], eax
    test eax, eax
    jl short .report_dos_error
    mov ebx, dword [esp + 4]
    mov ah, 0x3e
    int 0x21
    rcl eax, 1
    ror eax, 1
    mov dword [esp + 4], eax
    test eax, eax
    jl short .report_dos_error
    mov al, byte [esp]
    mov ch, byte [esp + 0x2c]
    mov edx, esi
    or al, ch
    mov ah, 0x3d
    int 0x21
    rcl eax, 1
    ror eax, 1
    mov dword [esp + 4], eax
    test eax, eax
    jl near .report_dos_error
    xor edi, edi
    mov di, word [esp + 4]

.read_handle_mode:
    mov eax, edi
    call get_io_mode
    and al, 0x3c
    mov edx, eax
    mov eax, edi
    call isatty
    test eax, eax
    je short .apply_access_mode
    or dh, 0x20

.apply_access_mode:
    and byte [esp], 0x7f
    cmp dword [esp], 2
    jne short .branch_61501
    or dl, 3

.branch_61501:
    cmp dword [esp], 0
    jne short .branch_6150a
    or dl, 1

.branch_6150a:
    cmp dword [esp], 1
    jne short .branch_61513
    or dl, 2

.branch_61513:
    test byte [esp + 0x28], 0x10
    je short .branch_6151d
    or dl, 0x80

.branch_6151d:
    mov eax, edx
    mov bl, byte [esp + 0x29]
    or al, 0x40
    test bl, 3
    je short .branch_61531
    test bl, 2
    je short .store_handle_mode
    jmp short .use_binary_mode

.branch_61531:
    cmp dword [default_file_mode], 0x200
    jne short .store_handle_mode

.use_binary_mode:
    mov edx, eax

.store_handle_mode:
    mov eax, edi
    call set_io_mode
    mov eax, edi

.restore_registers:
    add esp, 0xc
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

__set_binary_ equ 0x61551
    times 101 db 0   ; __set_binary_ is supplied by C.

    times 65 db 0    ; lseek is supplied by C.
