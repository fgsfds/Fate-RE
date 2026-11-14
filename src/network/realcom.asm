; Reconstructed 16-bit serial IRQ handler stored in MULTI's initialized DATA.
; Behavior follows Ken Silverman's MULTI.C realcom buffer and the pinned image.
; See ../engine/BUILDLIC.TXT. No opaque executable initializer is copied here.
BITS 16
ORG 0
COMBUFSIZ equ 16384
COMCODEBYTES equ 384
ESC1 equ 0x83
ESC2 equ 0x8f

; Shared state precedes the entry point. installbicomhandlers assigns pointers
; into this header and allocates receive/transmit rings following the buffer.
inbufplc: dw 0
inbufend: dw 0
outbufplc: dw 0
outbufend: dw 0
comport: dw 0
comtype: db 0
comerror: db 0
comresend: db 0
incnt: db 0
handler:
    push ax
    push bx
    push ecx
    push dx
.interrupt_identification:
    mov dx, [cs:comport]
    add dx, 2
    in al, dx
    and al, 7
    ; MOV r8,r/m8 encoding: destination AH=4, source AL=0.
    ; Preserve the historical opcode direction, without copying a code block.
    db 0x8a, 0xc0 | (4 << 3) | 0
    cmp ah, 2
    je .transmit
    cmp ah, 4
    je .receive
    jmp .acknowledge
.transmit:
    mov dx, [cs:comport]
    mov cl, [cs:comtype]
.next_transmit:
    sub cl, 1
    js .acknowledge
    cmp byte [cs:comresend], 1
    jl .error
    je .resend_last
    mov al, ESC1
    jmp .resend_write
.resend_last:
    mov al, ESC2
.resend_write:
    out dx, al
    dec byte [cs:comresend]
    jmp .next_transmit
.error:
    cmp byte [cs:comerror], 1
    jl .queued
    je .error_last
    mov al, ESC1
    jmp .error_write
.error_last:
    mov al, [cs:incnt]
.error_write:
    out dx, al
    dec byte [cs:comerror]
    jmp .next_transmit
.queued:
    mov bx, [cs:outbufplc]
    cmp bx, [cs:outbufend]
    je .acknowledge
    mov al, [cs:bx+COMCODEBYTES+COMBUFSIZ]
    out dx, al
    inc bx
    and bx, COMBUFSIZ-1
    mov [cs:outbufplc], bx
    jmp .next_transmit
.receive:
    mov dx, [cs:comport]
    in al, dx
    mov bx, [cs:inbufend]
    mov [cs:bx+COMCODEBYTES], al
    inc bx
    and bx, COMBUFSIZ-1
    mov [cs:inbufend], bx
    cmp byte [cs:comtype], 16
    jne .acknowledge
    add dx, 5
    in al, dx
    test al, 1
    jne .receive
.acknowledge:
    test ah, 1
    je near .interrupt_identification
    mov al, 0x20
    out 0x20, al
    pop dx
    pop ecx
    pop bx
    pop ax
    iret
handler_end:
; MULTI declares a 384-byte initialized char array; C initializes the remaining
; elements to zero. This storage extent is not instruction alignment padding.
times COMCODEBYTES-($-$$) db 0
