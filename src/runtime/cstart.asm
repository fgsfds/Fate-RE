; DOS extender startup, command-line setup and runtime dispatch.
BITS 32
ORG 0x5ff08

initial_stack_top equ 0x14480
memory_limit equ 0x1446c
psp_selector equ 0x14478
dos_major equ 0x144a3
dos_minor equ 0x144a4
extender_info equ 0x14194
zero_base_selector equ 0x14198
extender_type equ 0x1449a
extender_subtype equ 0x1449b
environment_offset equ 0x1449d
environment_selector equ 0x144a1
bss_end equ 0x2892f4
no87_count equ 0x14498
program_path equ 0x1447c
stack_low equ 0x14468
bss_start equ 0x199e4
command_line equ 0x14470
environment equ 0x14474
getds_selector_offset equ 0x501dd
init_routines equ 0x6337a
c_main equ 0x6332b
fini_routines equ 0x633c5

_cstart_:
    jmp short .initialize
    db "WATCOM C/C++32 Run-Time system. (c) Copyright by "
    db "WATCOM International Corp. 1988-1994. All rights reserved."
    lea eax, [byte eax + 0]
    dd 3                           ; CODE-object offset of the null-code sentinel.
console_name:
    db "con", 0

_cstart_.initialize:
    sti
    and esp, 0xfffffffc
    mov ebx, esp
    mov dword [initial_stack_top], ebx
    mov dword [memory_limit], ebx
    mov ax, 0x24
    mov word [psp_selector], ax
    mov ebx, 0x50484152
    sub eax, eax
    mov ah, 0x30
    int 0x21
    mov byte [dos_major], al
    mov byte [dos_minor], ah
    mov ecx, eax
    sub esi, esi
    mov edi, 0x81
    shr eax, 0x10
    cmp ax, 0x4458
    jne short .check_codebuilder
    sub bl, 0x30
    mov al, bl
    mov ah, 0
    push eax
    o16 mov es, word [psp_selector]
    mov ebx, dword es:[0x5c]
    add ebx, 0xfff
    and ebx, 0xfffff000
    mov dword [memory_limit], ebx
    shr ebx, 0xc
    mov ax, ds
    mov es, eax
    mov ah, 0x4a
    int 0x21
    pop eax
    mov bx, ds
    mov cx, 0x2c
    jmp short .join_extender_init

.check_codebuilder:
    cmp ax, 0x4243
    jne short .probe_dos4g
    mov dword [extender_info], edx
    mov esi, edx
    mov edx, dword [esi + 0x1c]
    mov ebx, esp
    sub ebx, edx
    mov ah, 0x4a
    int 0x21
    mov bx, ds
    o16 mov word [psp_selector], ds
    mov eax, dword [esi + 0x10]
    add edi, eax
    sub esi, esi
    mov si, word [eax + 0x2c]
    shl esi, 4
    mov cx, ds
    mov al, 9
    mov ah, 0

.join_extender_init:
    jmp short .record_extender_state

.probe_dos4g:
    mov dx, 0x78
    mov ax, 0xff00
    int 0x21
    cmp al, 0
    je short .fallback_selectors
    mov ax, gs
    cmp ax, 0
    je short .read_data_selector_base
    mov word [zero_base_selector], ax

.read_data_selector_base:
    mov ax, 6
    mov bx, ds
    int 0x31
    mov al, 1
    mov ah, 0
    or dx, cx
    je short .record_psp_selector
    mov ah, 1

.record_psp_selector:
    o16 mov word [psp_selector], es
    db 0x66, 0x26                 ; Operand size precedes ES; use the ModRM form.
    db 0x8b, 0x0d
    dd 0x2c
    jmp short .record_extender_state

.fallback_selectors:
    mov dx, ds
    mov cx, 0x24
    mov ds, ecx
    mov cx, 0x2c
    mov ds, edx
    mov bx, 0x17
    mov al, 0
    mov ah, 0

.record_extender_state:
    mov byte [extender_type], al
    mov byte [extender_subtype], ah
    mov es, ebx
    db 0x66                       ; Operand size precedes ES.
    mov word es:[getds_selector_offset], ds
    mov dword [environment_offset], esi
    mov word [environment_selector], cx
    push esi
    o16 mov es, word [psp_selector]
    ds mov edx, bss_end
    add edx, 0xf
    and dl, 0xf0
    sub ecx, ecx
    mov cl, byte es:[edi - 1]
    cld
    mov al, 0x20
    repe scasb
    lea esi, [edi - 1]
    mov edi, edx
    mov bx, es
    mov dx, ds
    mov ds, ebx
    mov es, edx
    je short .terminate_command_line
    inc ecx
    rep movsb

.terminate_command_line:
    sub al, al
    stosb
    stosb
    pop esi
    dec edi
    push edi
    push edx
    db 0x26                       ; ES precedes the operand-size prefix.
    o16 mov ds, word [environment_selector]
    sub ebp, ebp

.check_environment_entry:
    mov eax, dword [esi]
    or eax, 0x20202020
    cmp eax, 0x37386f6e
    jne short .skip_environment_entry
    cmp byte [esi + 4], 0x3d
    jne short .skip_environment_entry
    inc ebp

.skip_environment_entry:
    cmp byte [esi], 0
    lodsb
    jne short .skip_environment_entry
    cmp byte [esi], 0
    jne short .check_environment_entry
    lodsb
    inc esi
    inc esi

.copy_program_path:
    cmp byte [esi], 0
    movsb
    jne short .copy_program_path
    pop ds
    pop esi
    mov ebx, esp
    mov word [no87_count], bp
    mov dword [program_path], edi
    mov dword [stack_low], ebx
    ds mov ecx, bss_end
    ds mov edi, bss_start
    sub ecx, edi
    cmp byte [extender_type], 1
    jne short .clear_bss
    cmp ecx, 0x1000
    jbe short .clear_bss
    mov ecx, 0x1000

.clear_bss:
    mov dl, cl
    shr ecx, 2
    sub eax, eax
    rep stosd
    mov cl, dl
    and cl, 3
    rep stosb
    ds mov eax, bss_end
    add eax, 0xf
    and al, 0xf0
    mov dword [command_line], eax
    mov dword [environment], esi
    mov eax, 0xff
    call init_routines
    sub ebp, ebp
    call c_main
    jmp short .terminate_process

.write_console_error:
    push edx
    push eax
    mov edx, console_name - 0x10000
    mov ax, 0x3d01
    int 0x21
    mov bx, ax
    pop edx
    mov esi, edx
    cld

.find_message_end:
    lodsb
    cmp al, 0
    jne short .find_message_end
    mov ecx, esi
    sub ecx, edx
    dec ecx
    mov ah, 0x40
    int 0x21
    pop eax

.terminate_process:
    push eax
    mov eax, 0
    mov edx, 0xff
    call fini_routines
    pop eax
    mov ah, 0x4c
    int 0x21
    lea eax, [byte eax + 0]
