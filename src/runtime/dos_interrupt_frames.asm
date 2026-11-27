; Build a delimiter bitmap and dispatch DOS interrupt register frames.
BITS 32
ORG 0x67058

interrupt_vectors equ 0x67174 - 0x10000

    times 62 db 0    ; build_delimiter_map is supplied by C.

dispatch_interrupt_registers:
    push ebp
    push es
    push ebx
    push ds
    push edx
    call load_interrupt_registers
    push ds
    push edi
    mov ebp, esp
    mov edi, dword [ebp + 8]
    mov ds, word [ebp + 0xc]
    mov dword [edi], eax
    mov dword [edi + 4], ebx
    mov dword [edi + 8], ecx
    mov dword [edi + 0xc], edx
    mov dword [edi + 0x10], esi
    pop dword [edi + 0x14]
    sbb eax, eax
    mov dword [edi + 0x18], eax
    pop eax
    pop ebx
    pop ebx
    pop ebx
    mov word [ebx + 6], ax
    db 0x66 ; Preserve the original operand-size prefix.
    mov [ebx], es
    pop es
    pop ebp
    ret

load_interrupt_registers:
    lea esi, [esi + esi*2]
    lea eax, [cs:esi + interrupt_vectors]
    push eax
    mov es, word [ebx]
    mov bp, word [ebx + 6]
    mov eax, dword [edi]
    mov ebx, dword [edi + 4]
    mov ecx, dword [edi + 8]
    mov edx, dword [edi + 0xc]
    mov esi, dword [edi + 0x10]
    mov edi, dword [edi + 0x14]
    mov ds, bp
    ret

dispatch_interrupt_extended:
    pushad
    push gs
    push fs
    push es
    push ds
    push edx
    call load_interrupt_extended
    push ebx
    push ds
    push ebp
    mov ebp, esp
    mov ebx, dword [ebp + 0xc]
    mov ds, word [ebp + 0x10]
    mov dword [ebx], eax
    pushfd
    pop eax
    mov word [ebx + 0x24], ax
    mov dword [ebx + 8], ecx
    mov dword [ebx + 0xc], edx
    mov dword [ebx + 0x14], esi
    mov dword [ebx + 0x18], edi
    pop dword [ebx + 0x10]
    pop eax
    mov word [ebx + 0x1c], ax
    pop dword [ebx + 4]
    db 0x66 ; Preserve the original operand-size prefix.
    mov [ebx + 0x1e], es
    db 0x66 ; Preserve the original operand-size prefix.
    mov [ebx + 0x20], fs
    db 0x66 ; Preserve the original operand-size prefix.
    mov [ebx + 0x22], gs
    add esp, 8
    pop es
    pop fs
    pop gs
    popad
    ret

load_interrupt_extended:
    and eax, 0xff
    lea eax, [nosplit eax + eax*2]
    lea eax, [cs:eax + interrupt_vectors]
    push eax
    mov ebx, edx
    push dword [ebx + 0x1c]
    mov eax, dword [ebx]
    mov ecx, dword [ebx + 8]
    mov edx, dword [ebx + 0xc]
    mov esi, dword [ebx + 0x14]
    mov edi, dword [ebx + 0x18]
    mov ebp, dword [ebx + 0x10]
    mov es, word [ebx + 0x1e]
    mov fs, word [ebx + 0x20]
    mov gs, word [ebx + 0x22]
    mov ebx, dword [ebx + 4]
    pop ds
    ret

interrupt_vector_thunks:
%assign vector 0
%rep 256
%if vector = 3
    int3
    nop
%else
    int vector
%endif
    ret
%assign vector vector + 1
%endrep
