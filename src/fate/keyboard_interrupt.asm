; Handle a DOS keyboard interrupt and queue new key presses.
BITS 32
ORG 0x2f27e

reload_runtime_ds equ 0x601d4
key_fifo equ 0x678fc
key_state equ 0x6793c
keyboard_port_scratch equ 0x7f875
scan_code equ 0x7f876
key_fifo_write equ 0x7f878
extended_scan_offset equ 0x7f879
previous_scan_code equ 0x7f87a

keyboard_interrupt:
    pushad
    push ds
    push es
    push fs
    push gs
    mov ebp, esp
    cld
    call reload_runtime_ds
    mov eax, 0x20
    mov edx, eax
    out dx, al
    mov al, [scan_code]
    mov [previous_scan_code], al
    mov edx, 0x60
    in al, dx
    mov [scan_code], al
    mov edx, 0x61
    in al, dx
    mov [keyboard_port_scratch], al
    mov al, [keyboard_port_scratch]
    or al, 0x80
    and eax, strict dword 0xff
    out dx, al
    mov al, [keyboard_port_scratch]
    and al, 0x7f
    and eax, strict dword 0xff
    out dx, al
    mov al, [scan_code]
    or al, 0x1
    and eax, strict dword 0xff
    cmp eax, strict dword 0xe1
    jnz short .branch_2f2ee
    mov byte [extended_scan_offset], 0x80
    jmp near .branch_2f3c6

.branch_2f2ee:
    mov al, [previous_scan_code]
    cmp al, [scan_code]
    jz near .branch_2f3bf
    mov al, [scan_code]
    and al, 0x80
    and eax, strict dword 0xff
    jnz short .branch_2f368
    mov al, [scan_code]
    mov bl, [extended_scan_offset]
    add al, bl
    mov [keyboard_port_scratch], al
    xor eax, eax
    mov al, [keyboard_port_scratch]
    cmp byte [eax + key_state], 0x0
    jnz near .branch_2f3bf
    xor eax, eax
    mov al, [keyboard_port_scratch]
    mov cl, 0x1
    mov [eax + key_state], cl
    xor eax, eax
    mov al, [key_fifo_write]
    mov dl, [keyboard_port_scratch]
    mov [eax + key_fifo], dl
    xor eax, eax
    mov al, [key_fifo_write]
    inc eax
    and eax, 0x3f
    mov [eax + key_fifo], cl
    jmp short .branch_2f3b1

.branch_2f368:
    mov al, [scan_code]
    and al, 0x7f
    mov ah, [extended_scan_offset]
    add al, ah
    mov [keyboard_port_scratch], al
    xor eax, eax
    mov al, [keyboard_port_scratch]
    xor dl, dl
    mov [eax + key_state], dl
    xor eax, eax
    mov al, [key_fifo_write]
    mov dl, [keyboard_port_scratch]
    mov [eax + key_fifo], dl
    xor eax, eax
    mov al, [key_fifo_write]
    inc eax
    and eax, 0x3f
    xor dh, dh
    mov [eax + key_fifo], dh

.branch_2f3b1:
    mov al, [key_fifo_write]
    add al, 0x2
    and al, 0x3f
    mov [key_fifo_write], al

.branch_2f3bf:
    xor al, al
    mov [extended_scan_offset], al

.branch_2f3c6:
    pop gs
    pop fs
    pop es
    pop ds
    popad
    iretd
