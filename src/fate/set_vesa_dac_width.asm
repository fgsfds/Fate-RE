; Set VESA DAC width.
BITS 32
ORG 0x4413c

dpmi_real_mode_interrupt equ 0x4380a
vesa_capabilities equ 0x1ec2aa

set_vesa_dac_width:
    push ebx
    push edx
    sub esp, 0x10
    test byte [vesa_capabilities], 0x1
    jnz short .branch_44151
    mov eax, 0x6
    jmp short .branch_44176

.branch_44151:
    mov edx, 0x4f08
    mov ebx, esp
    shl eax, byte 0x8
    mov [esp], dx
    mov [esp + 0x2], ax
    mov edx, esp
    mov eax, 0x10
    call dpmi_real_mode_interrupt
    xor eax, eax
    mov al, [esp + 0x3]

.branch_44176:
    add esp, 0x10
    pop edx
    pop ebx
    ret
