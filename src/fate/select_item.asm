; Select item.
BITS 32
ORG 0x380d8

text_seek_error equ 0xbc5
text_read_error equ 0xbe6
text_archive_open equ 0x12d94
text_archive_handle equ 0x12d98
frame_state_12d9c equ 0x12d9c
frame_state_12da0 equ 0x12da0
frame_state_12da4 equ 0x12da4
frame_state_12da8 equ 0x12da8
report_error equ 0x26a03
dispatch_ticks equ 0x35415
lseek equ 0x615b6
read equ 0x615f7
weapon_state_77108 equ 0x77108
frame_state_7711c equ 0x7711c
totalclock equ 0x287e88

select_item:
    push ebx
    push ecx
    push edx
    push ebp
    mov ecx, eax
    mov ebx, [text_archive_open]
    mov edx, 0x1
    test ebx, ebx
    jnz short .branch_380f2
    mov edx, 0xffffffff

.branch_380f2:
    test ecx, ecx
    jnl short .branch_380fb
    mov edx, 0xffffffff

.branch_380fb:
    cmp ecx, [frame_state_12da0]
    jng short .branch_38108
    mov edx, 0xffffffff

.branch_38108:
    cmp edx, -1
    jz short .branch_3815e
    cmp ecx, [frame_state_12d9c]
    jz short .branch_3815e
    mov [frame_state_12d9c], ecx
    imul edx, ecx, 0x2e
    mov eax, [text_archive_handle]
    xor ebx, ebx
    call lseek
    cmp eax, -1
    jnz short .branch_38139
    mov eax, text_seek_error
    call report_error

.branch_38139:
    mov ebx, 0x2e
    mov edx, frame_state_12da4
    mov eax, [text_archive_handle]
    call read
    cmp eax, 0x2e
    jz short .branch_3815c
    mov eax, text_read_error
    call report_error

.branch_3815c:
    mov edx, ecx

.branch_3815e:
    cmp edx, -1
    jz short .branch_38185
    mov ebp, frame_state_12da8
    mov eax, 0x3
    mov [frame_state_7711c], ebp
    call dispatch_ticks
    mov ecx, [totalclock]
    add eax, ecx
    mov [weapon_state_77108], eax

.branch_38185:
    mov eax, edx
    pop ebp
    pop edx
    pop ecx
    pop ebx
    ret
