; Real-mode IPX receive callback copied into a DOS memory block.
BITS 16
ORG 0

packet_length_hi equ 0x62
packet_length_lo equ 0x63
packet_data equ 0xa0
ring_write equ 0x6e2
ring_data equ 0x6e4
ring_mask equ 0x3fff
ipx_header_size equ 30

    sti
    mov ah, [cs:packet_length_hi]
    mov al, [cs:packet_length_lo]
    sub ax, byte ipx_header_size
    mov bx, [cs:ring_write]
    mov [cs:bx + ring_data], al
    inc bx
    and bx, strict word ring_mask
    mov [cs:bx + ring_data], ah
    inc bx
    and bx, strict word ring_mask
    db 0x33, 0xf6                ; XOR SI, SI, register-destination encoding.
.copy_packet:
    mov cl, [cs:si + packet_data]
    inc si
    mov [cs:bx + ring_data], cl
    inc bx
    and bx, strict word ring_mask
    db 0x3b, 0xf0                ; CMP SI, AX, register-destination encoding.
    jb short .copy_packet
    mov [cs:ring_write], bx
    mov bx, 4
    mov ax, cs
    mov es, ax
    mov si, 0
    int 0x7a
    retf
    times 384 - ($ - $$) db 0
