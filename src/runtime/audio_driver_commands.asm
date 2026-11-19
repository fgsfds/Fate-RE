; HMI command wrappers for the mapped driver and its parameter table.
BITS 32
ORG 0x66641

driver_parameter_ax equ 0x16bf0
driver_parameter_cl equ 0x16bf4
driver_parameter_ch equ 0x16bf8
driver_parameter_dx equ 0x16bfc

%macro save_registers 0
    push ebp
    db 0x8b, 0xec ; MOV EBP, ESP, register-destination encoding.
    push esi
    push edi
    push ebx
    push ecx
    push fs
    push gs
    push es
%endmacro

%macro restore_registers 0
    pop es
    pop gs
    pop fs
    pop ecx
    pop ebx
    pop edi
    pop esi
    pop ebp
    ret
%endmacro

driver_command_5 equ 0x66641
    times 35 db 0    ; driver_command_5 is supplied by C.
driver_command_0 equ 0x66664
    times 35 db 0    ; driver_command_0 is supplied by C.

read_driver_parameters equ 0x66687
    times 68 db 0    ; read_driver_parameters is supplied by C.

read_driver_command_table:
    save_registers
    push es
    mov eax, 2
    lfs edi, [ebp + 0x10]
    call far [ebp + 8]
    push ds
    push ds
    pop es
    mov edi, dword [ebp + 0x18]
    lds esi, [ebp + 0x10]
    db 0x8b, 0xf2 ; MOV ESI, EDX, register-destination encoding.
    mov ecx, 0x6a
    cld
    rep movsb
    pop ds
    pop es
    push ds
    push es
    push ds
    pop es
    mov edi, dword [ebp + 0x18]
    mov ds, word [ebp + 0x14]
    db 0x66, 0x26 ; Operand-size and ES prefixes in original order.
    mov [edi + 0x44], ds
    db 0x66, 0x26 ; Operand-size and ES prefixes in original order.
    mov [edi + 0x4c], ds
    db 0x66, 0x26 ; Operand-size and ES prefixes in original order.
    mov [edi + 0x54], ds
    db 0x66, 0x26 ; Operand-size and ES prefixes in original order.
    mov [edi + 0x5c], ds
    pop es
    pop ds
    restore_registers

driver_command_3 equ 0x66724
    times 48 db 0    ; driver_command_3 is supplied by C.
driver_secondary_command_1 equ 0x66754
    times 35 db 0    ; driver_secondary_command_1 is supplied by C.
driver_configure_secondary equ 0x66777
    times 53 db 0    ; driver_configure_secondary is supplied by C.
driver_secondary_command_4 equ 0x667ac
    times 41 db 0    ; driver_secondary_command_4 is supplied by C.
driver_secondary_command_2 equ 0x667d5
    times 38 db 0    ; driver_secondary_command_2 is supplied by C.
driver_secondary_command_3 equ 0x667fb
    times 39 db 0    ; driver_secondary_command_3 is supplied by C.

probe_windows_driver_value:
    save_registers
    mov ax, 0x1600
    int 0x2f
    cmp ax, 0xa03
    mov eax, dword [ebp + 0x14]
    jne short .return
    nop
    nop
    nop
    nop
.return:
    restore_registers

windows_driver_interrupt equ 0x6684c
    times 53 db 0    ; windows_driver_interrupt is supplied by C.

driver_records equ 0x16b60
driver_records_selector equ 0x16b64
driver_callbacks equ 0x16b68
driver_callbacks_selector equ 0x16b6c
copied_driver_record equ 0x16b10
dpmi_memory_info equ 0x16b70

windows_driver_interrupt_stop:
    save_registers
    mov ax, 0x1600
    int 0x2f
    cmp al, 3
    jne short .return
    nop
    nop
    nop
    nop
    mov ah, 0x81
    mov al, 0xc
    mov ebx, dword [ebp + 8]
    db 0x66, 0x33, 0xd2 ; XOR DX, DX, register-destination encoding.
    int 0x4b
    mov ax, 0
.return:
    restore_registers

get_driver_tables:
    save_registers
    lfs edi, [ebp + 0x10]
    mov eax, 4
    call far [ebp + 8]
    mov dword [driver_records], esi
    mov dword [driver_callbacks], edi
    mov ax, word [ebp + 0x14]
    mov word [driver_records_selector], ax
    mov word [driver_callbacks_selector], ax
    restore_registers

copy_driver_record:
    save_registers
    push ds
    push ds
    pop es
    mov edi, copied_driver_record
    mov ebx, dword [ebp + 8]
    lds esi, [driver_records]
    mov esi, dword [esi + ebx*4]
    cmp esi, -1
    jne short .copy_record
    nop
    nop
    nop
    nop
    db 0x33, 0xc0 ; XOR EAX, EAX, register-destination encoding.
    pop ds
    jmp short .return
    nop
    nop
    nop
.copy_record:
    mov ecx, 0x50
    cld
    repne movsb
    pop ds
    mov eax, copied_driver_record
.return:
    restore_registers

set_driver_callback:
    save_registers
    les esi, [driver_callbacks]
    mov eax, dword [ebp + 8]
    db 0x8b, 0xd8 ; MOV EBX, EAX, register-destination encoding.
    shl eax, 1
    shl ebx, 2
    db 0x03, 0xd8 ; ADD EBX, EAX, register-destination encoding.
    mov eax, dword [ebp + 0xc]
    mov [es:nosplit esi + ebx], eax
    db 0x66, 0x26 ; Operand-size and ES prefixes in original order.
    mov [nosplit esi + ebx + 4], ds
    restore_registers

query_dpmi_memory:
    save_registers
    mov ax, 0x500
    int 0x31
    push ds
    pop es
    mov edi, dpmi_memory_info
    int 0x31
    mov eax, dword [dpmi_memory_info]
    restore_registers

query_windows_version:
    save_registers
    mov ax, 0x1600
    int 0x2f
    restore_registers

allocate_dos_paragraphs:
    save_registers
    mov ax, 0x100
    mov ebx, dword [ebp + 8]
    int 0x31
    jae short .store_allocation
    nop
    nop
    nop
    nop
    mov eax, 1
    jmp short .return
    nop
    nop
    nop
.store_allocation:
    mov esi, dword [ebp + 0xc]
    mov word [esi], dx
    mov esi, dword [ebp + 0x10]
    mov word [esi], ax
    mov eax, 0
.return:
    restore_registers

release_dos_selector:
    mov ax, ds
    mov gs, ax
    mov fs, ax
    mov es, ax
    save_registers
    mov ax, 0x101
    mov dx, word [ebp + 8]
    int 0x31
    mov ax, 0
    restore_registers

real_mode_audio_registers equ 0x16ba0

start_real_mode_audio_service:
    save_registers
    mov esi, real_mode_audio_registers
    mov dword [esi + 0x1c], 0x8107
    mov dword [esi + 0x14], 0
    mov ax, word [ebp + 8]
    mov word [esi + 0x22], ax
    mov dword [esi], 0
    mov ax, 0x300
    mov bl, 0x4b
    mov bh, 0
    mov cx, 0
    mov edi, real_mode_audio_registers
    push ds
    pop es
    int 0x31
    mov esi, real_mode_audio_registers
    and word [esi + 0x20], 1
    jne short .failed
    nop
    nop
    nop
    nop
    mov eax, 0
    jmp short .return
    nop
    nop
    nop
.failed:
    mov eax, 1
.return:
    restore_registers

stop_real_mode_audio_service:
    save_registers
    mov esi, real_mode_audio_registers
    mov dword [esi + 0x1c], 0x8108
    mov dword [esi + 0x14], 0
    mov ax, word [ebp + 8]
    mov word [esi + 0x22], ax
    mov dword [esi], 0
    mov ax, 0x300
    mov bl, 0x4b
    mov bh, 0
    mov cx, 0
    mov edi, real_mode_audio_registers
    push ds
    pop es
    int 0x31
    restore_registers

map_audio_physical_region:
    save_registers
    mov ax, 0x800
    mov bx, word [ebp + 0xa]
    mov cx, word [ebp + 8]
    mov si, 0
    mov di, 0x4000
    int 0x31
    db 0x66, 0x8b, 0xc3 ; MOV AX, BX, register-destination encoding.
    shl eax, 0x10
    db 0x66, 0x8b, 0xc1 ; MOV AX, CX, register-destination encoding.
    restore_registers

free_audio_selector:
    mov ax, ds
    mov gs, ax
    mov fs, ax
    mov es, ax
    save_registers
    mov ax, 1
    mov bx, word [ebp + 8]
    int 0x31
    restore_registers

driver_command_11:
    save_registers
    push esi
    push es
    mov ax, 0xb
    lfs edi, [ebp + 0x10]
    call far [ebp + 8]
    pop es
    pop esi
    restore_registers

get_audio_data_selector:
    mov ax, ds
    ret

get_audio_code_selector:
    mov ax, cs
    ret

audio_helper_region_end_c_slot:
    db 0 ; Byte supplied by timer_vector_noop.c.
