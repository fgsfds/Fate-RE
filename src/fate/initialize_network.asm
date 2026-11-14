; Initialize network.
BITS 32
ORG 0x4152a

frame_state_18cc equ 0x18cc
frame_state_18e2 equ 0x18e2
transport equ 0x13cde
frame_state_13cdf equ 0x13cdf
player_count equ 0x13ce0
print_runtime_message equ 0x40bb4
initialize_interrupt_network equ 0x41694
initialize_serial_network equ 0x41a56
initialize_crc_table equ 0x42f1a
runtime_exit equ 0x60353
frame_state_186d4c equ 0x186d4c
frame_state_18fd7a equ 0x18fd7a
frame_state_18fe0c equ 0x18fe0c
frame_state_18fe10 equ 0x18fe10
frame_state_18fe28 equ 0x18fe28
first_player equ 0x19028a

baud_dispatch:
    dd initialize_network.baud_case_415b7 - 0x10000
    dd initialize_network.baud_case_415c3 - 0x10000
    dd initialize_network.baud_case_415cf - 0x10000
    dd initialize_network.baud_case_415db - 0x10000
    dd initialize_network.baud_case_415e7 - 0x10000
    dd initialize_network.baud_case_415f3 - 0x10000

initialize_network:
    push ecx
    mov cl, dl
    mov [frame_state_13cdf], dl
    xor edx, edx
    mov [transport], al
    mov [first_player], dx
    mov edx, 0xf
    jmp short .branch_41576

.branch_41560:
    dec edx
    mov word [nosplit edx*2 + frame_state_18fd7a], 0xffff
    mov dword [nosplit edx*4 + frame_state_186d4c], 0x7fffffff

.branch_41576:
    test edx, edx
    jnl short .branch_41560
    xor eax, eax
    mov al, bl
    mov [frame_state_18fe0c], eax
    call initialize_crc_table
    xor eax, eax
    mov al, [transport]
    cmp eax, 0x1
    jl near .branch_41602
    cmp eax, 0x4
    jg short .branch_41602
    mov [frame_state_18fe10], eax
    mov al, cl
    and al, 0xf
    cmp al, 0x5
    ja short .branch_415fd
    and eax, strict dword 0xff
    jmp dword near [cs:eax*4 + baud_dispatch - 0x10000]
.baud_case_415b7:
    mov dword [frame_state_18fe28], 0x960
    jmp short .branch_415fd
.baud_case_415c3:
    mov dword [frame_state_18fe28], 0x12c0
    jmp short .branch_415fd
.baud_case_415cf:
    mov dword [frame_state_18fe28], 0x2580
    jmp short .branch_415fd
.baud_case_415db:
    mov dword [frame_state_18fe28], 0x3840
    jmp short .branch_415fd
.baud_case_415e7:
    mov dword [frame_state_18fe28], 0x4b00
    jmp short .branch_415fd
.baud_case_415f3:
    mov dword [frame_state_18fe28], 0x7080

.branch_415fd:
    call initialize_serial_network

.branch_41602:
    xor eax, eax
    mov al, [transport]
    cmp eax, 0x5
    jl short .branch_41644
    call initialize_interrupt_network
    mov edx, eax
    test eax, eax
    jz short .branch_41644
    cmp eax, -1
    jnz short .branch_4162b
    push strict dword frame_state_18cc
    call print_runtime_message
    add esp, 0x4

.branch_4162b:
    cmp edx, 0xfffffffffffffffe
    jnz short .branch_4163d
    push strict dword frame_state_18e2
    call print_runtime_message
    add esp, 0x4

.branch_4163d:
    xor eax, eax
    call runtime_exit

.branch_41644:
    mov word [player_count], 0x1
    pop ecx
    ret
