; Prepare cd request buffers.
BITS 32
ORG 0x3771a

simulate_real_mode_interrupt equ 0x375e9
allocate_dos_memory equ 0x37659
memset equ 0x61350
real_mode_registers equ 0x173f56
frame_state_173f66 equ 0x173f66
frame_state_173f72 equ 0x173f72
frame_state_173f78 equ 0x173f78
frame_state_173f88 equ 0x173f88
frame_state_173f8c equ 0x173f8c
frame_state_173f90 equ 0x173f90
frame_state_173f9c equ 0x173f9c
frame_state_173fa0 equ 0x173fa0
cd_drive_letter equ 0x173fa6
frame_state_173fa8 equ 0x173fa8

prepare_cd_request_buffers:
    push ebx
    push edx
    imul ax, [cd_drive_letter], 0x5
    cwde
    call allocate_dos_memory
    test eax, eax
    jnz short .branch_37733
    test dx, dx
    jz short .branch_37760

.branch_37733:
    mov ax, [frame_state_173fa0]
    mov dx, [frame_state_173f90]
    mov [frame_state_173fa8], ax
    mov [frame_state_173f9c], dx
    and eax, strict dword 0xffff
    shl eax, byte 0x4
    mov word [frame_state_173f8c], ds
    mov [frame_state_173f88], eax

.branch_37760:
    mov ebx, 0x32
    mov eax, real_mode_registers
    xor edx, edx
    call memset
    xor eax, eax
    mov edx, 0x1501
    mov ax, [frame_state_173f9c]
    mov [frame_state_173f72], edx
    mov [frame_state_173f66], eax
    mov ax, [frame_state_173fa8]
    mov edx, real_mode_registers
    mov [frame_state_173f78], ax
    mov eax, 0x2f
    call simulate_real_mode_interrupt
    pop edx
    pop ebx
    ret
