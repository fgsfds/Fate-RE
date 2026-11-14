; Initialize serial network.
BITS 32
ORG 0x41a45

frame_state_13cdf equ 0x13cdf
restore_network_registers equ 0x41a3f
install_serial_interrupts equ 0x430cc
disable_interrupts equ 0x603dc
enable_interrupts equ 0x60409
inp equ 0x6326a
frame_state_18fdbc equ 0x18fdbc
write_index equ 0x18fdd0
read_index equ 0x18fdd8
frame_state_18fde8 equ 0x18fde8
frame_state_18fdf0 equ 0x18fdf0
frame_state_18fdf4 equ 0x18fdf4
frame_state_18fdf8 equ 0x18fdf8
frame_state_18fdfc equ 0x18fdfc
frame_state_18fe00 equ 0x18fe00
frame_state_18fe04 equ 0x18fe04
frame_state_18fe10 equ 0x18fe10
frame_state_18fe14 equ 0x18fe14
frame_state_18fe1c equ 0x18fe1c
frame_state_18fe28 equ 0x18fe28
frame_state_18fe2c equ 0x18fe2c
frame_state_18fe38 equ 0x18fe38

    nop

serial_port_dispatch:
    dd initialize_serial_network.com_port_1 - 0x10000
    dd initialize_serial_network.com_port_2 - 0x10000
    dd initialize_serial_network.com_port_3 - 0x10000
    dd initialize_serial_network.com_port_4 - 0x10000

initialize_serial_network:
    push ebx
    push ecx
    push edx
    push esi
    push ebp
    mov edx, [frame_state_18fe10]
    cmp edx, 0x1
    jl short .branch_41a6b
    cmp edx, 0x4
    jng short .branch_41a72

.branch_41a6b:
    mov eax, 0xffffffff
    jmp short restore_network_registers

.branch_41a72:
    xor eax, eax
    mov al, [frame_state_13cdf]
    sar eax, byte 0x4
    add eax, 0xa
    mov [frame_state_18fe04], eax
    call install_serial_interrupts
    mov eax, [frame_state_18fe00]
    mov byte [eax], 0x0
    xor ecx, ecx
    mov eax, [frame_state_18fdbc]
    mov [frame_state_18fe14], ecx
    mov word [eax], 0x0
    mov eax, [frame_state_18fdf0]
    mov word [eax], 0x0
    mov eax, [read_index]
    mov word [eax], 0x0
    mov eax, [write_index]
    mov word [eax], 0x0
    mov eax, [frame_state_18fe10]
    dec eax
    add eax, eax
    add eax, strict dword 0x400
    mov edx, [frame_state_18fde8]
    mov ax, [eax]
    mov [edx], ax
    mov eax, edx
    cmp word [edx], 0x0
    jnz short .branch_41b37
    mov edx, [frame_state_18fe10]
    dec edx
    cmp edx, 0x3
    ja short .branch_41b10
    jmp dword near [cs:edx*4 + serial_port_dispatch - 0x10000]
.com_port_1:
    mov word [eax], 0x3f8
    jmp short .branch_41b10
.com_port_2:
    mov word [eax], 0x2f8
    jmp short .branch_41b10
.com_port_3:
    mov word [eax], 0x3e8
    jmp short .branch_41b10
.com_port_4:
    mov word [eax], 0x2e8

.branch_41b10:
    mov eax, [frame_state_18fde8]
    movsx eax, word [eax]
    add eax, 0x5
    call inp
    and eax, 0x60
    cmp eax, 0x60
    jz short .branch_41b37
    mov eax, [frame_state_18fde8]
    mov word [eax], 0x0
    jmp near .branch_41a6b

.branch_41b37:
    mov esi, [frame_state_18fe28]
    test esi, esi
    jng near .branch_41a6b
    cmp esi, strict dword 0x1c200
    jg near .branch_41a6b
    call disable_interrupts
    mov eax, [frame_state_18fde8]
    movsx edx, word [eax]
    mov eax, 0x80
    add edx, 0x3
    out dx, al
    mov eax, 0x1c200
    mov edx, eax
    mov ebp, [frame_state_18fe28]
    sar edx, byte 0x1f
    idiv ebp
    mov edx, [frame_state_18fde8]
    mov ecx, eax
    and eax, strict dword 0xff
    movsx edx, word [edx]
    out dx, al
    mov eax, ecx
    mov edx, [frame_state_18fde8]
    sar eax, byte 0x8
    movsx edx, word [edx]
    inc edx
    out dx, al
    mov eax, [frame_state_18fde8]
    movsx edx, word [eax]
    mov eax, 0x3
    add edx, 0x3
    out dx, al
    mov eax, [frame_state_18fde8]
    movsx edx, word [eax]
    mov eax, 0x87
    add edx, 0x2
    out dx, al
    mov eax, [frame_state_18fde8]
    movsx edx, word [eax]
    add edx, 0x2
    in al, dx
    and eax, strict dword 0xf8
    cmp eax, strict dword 0xc0
    jnz short .branch_41bde
    mov eax, [frame_state_18fdf8]
    mov byte [eax], 0x10
    jmp short .branch_41bf4

.branch_41bde:
    mov eax, [frame_state_18fdf8]
    mov byte [eax], 0x1
    mov eax, [frame_state_18fde8]
    movsx edx, word [eax]
    add edx, 0x2
    xor eax, eax
    out dx, al

.branch_41bf4:
    mov ecx, [frame_state_18fdf8]
    mov cl, [ecx]
    and ecx, strict dword 0xff

.branch_41c02:
    mov eax, [frame_state_18fde8]
    movsx edx, word [eax]
    add edx, 0x5
    in al, dx
    and eax, 0x1
    test eax, eax
    jng short .branch_41c28
    test ecx, ecx
    jng short .branch_41c28
    mov eax, [frame_state_18fde8]
    mov ax, [eax]
    movsx edx, ax
    in al, dx
    dec ecx
    jmp short .branch_41c02

.branch_41c28:
    mov eax, [frame_state_18fde8]
    movsx edx, word [eax]
    mov eax, 0xb
    add edx, 0x4
    out dx, al
    mov eax, [frame_state_18fde8]
    movsx edx, word [eax]
    inc edx
    xor eax, eax
    out dx, al
    mov ecx, [frame_state_18fe04]
    mov eax, 0x1
    and ecx, 0x7
    shl eax, cl
    mov ecx, 0xff
    mov edx, 0x21
    sub ecx, eax
    in al, dx
    mov edx, 0x21
    and eax, ecx
    out dx, al
    mov eax, [frame_state_18fde8]
    movsx edx, word [eax]
    add edx, 0x6
    in al, dx
    mov eax, [frame_state_18fde8]
    movsx edx, word [eax]
    add edx, 0x5
    in al, dx
    mov eax, [frame_state_18fde8]
    movsx edx, word [eax]
    in al, dx
    mov eax, [frame_state_18fde8]
    movsx edx, word [eax]
    add edx, 0x2
    in al, dx
    mov eax, [frame_state_18fde8]
    movsx edx, word [eax]
    mov eax, 0x3
    inc edx
    out dx, al
    mov eax, 0x20
    mov edx, eax
    out dx, al
    xor eax, eax
    mov [frame_state_18fdfc], eax
    mov [frame_state_18fe2c], eax
    mov eax, [frame_state_18fe1c]
    mov byte [eax], 0x0
    mov eax, [frame_state_18fdf4]
    mov byte [eax], 0x0
    call enable_interrupts
    xor ebx, ebx
    xor eax, eax
    mov [frame_state_18fe38], ebx
    jmp near restore_network_registers
