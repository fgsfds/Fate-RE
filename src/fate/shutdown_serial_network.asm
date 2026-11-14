; Shutdown serial network.
BITS 32
ORG 0x41cde

frame_state_13cdd equ 0x13cdd
start_serial_output equ 0x4204f
remove_serial_interrupts equ 0x43243
disable_interrupts equ 0x603dc
enable_interrupts equ 0x60409
write_index equ 0x18fdd0
read_index equ 0x18fdd8
frame_state_18fde8 equ 0x18fde8
frame_state_18fe04 equ 0x18fe04

shutdown_serial_network:
    push ebx
    push ecx
    push edx
    mov edx, 0x100000

.branch_41ce6:
    mov eax, [read_index]
    mov ebx, [write_index]
    mov ax, [eax]
    cmp ax, [ebx]
    jz short .branch_41d05
    test edx, edx
    jl short .branch_41d05
    call start_serial_output
    dec edx
    jmp short .branch_41ce6

.branch_41d05:
    call disable_interrupts
    mov ebx, 0x1
    mov ecx, [frame_state_18fe04]
    mov edx, 0x21
    and ecx, 0x7
    in al, dx
    shl ebx, cl
    mov edx, 0x21
    or eax, ebx
    out dx, al
    cmp byte [frame_state_13cdd], 0x0
    jz short .branch_41d4b
    mov eax, [frame_state_18fde8]
    movsx edx, word [eax]
    inc edx
    xor eax, eax
    out dx, al
    mov eax, [frame_state_18fde8]
    movsx edx, word [eax]
    add edx, 0x4
    xor eax, eax
    out dx, al

.branch_41d4b:
    call enable_interrupts
    call remove_serial_interrupts
    pop edx
    pop ecx
    pop ebx
    ret
