; Reconstructed from FATE's relocation-free code at object 1 + 0x3c1b2.
; Watcom register ABI: x=EAX, y=EDX, x1=EBX, y1=ECX;
; stack arguments: x2, y2, walldist. Callee removes 12 argument bytes.
; Returns 0 outside, 1 front intersection, or 2 back intersection.
; Arithmetic is signed 32-bit, with wrapping products preserved.
BITS 32
clipinsideboxline_:
    push esi
    push edi
    push ebp
    sub esp, 8
    push eax
    mov edi, edx
    mov edx, [esp+28]
    mov eax, [esp+32]
    mov ebp, [esp+36]
    mov esi, [esp+36]
    sub ebp, [esp]
    add esi, esi                 ; square width = 2 * walldist
    add ebx, ebp                 ; translate horizontal endpoints
    add edx, ebp
    test ebx, ebx
    jge .right_bound
    test edx, edx
    jge .right_bound
.outside:
    xor eax, eax
    jmp near .return
.right_bound:
    cmp ebx, esi
    jl .translate_y
    cmp edx, esi
    jge .outside
.translate_y:
    mov ebp, [esp+36]
    sub ebp, edi
    add ecx, ebp
    add eax, ebp
    test ecx, ecx
    jge .bottom_bound
    test eax, eax
    jl .outside
.bottom_bound:
    cmp ecx, esi
    jl .orientation
    cmp eax, esi
    jge .outside
.orientation:
    sub edx, ebx                 ; dx
    mov edi, [esp+36]
    mov ebp, edx
    sub edi, ecx
    imul ebp, edi
    sub eax, ecx                 ; dy
    mov edi, [esp+36]
    mov [esp+4], ebp
    mov ebp, eax
    sub edi, ebx
    imul ebp, edi
    mov edi, esi
    sub edi, ecx
    imul edi, edx                ; dx * (width - y1)
    mov [esp+8], ebp
    mov ebp, [esp+4]
    cmp ebp, [esp+8]
    jl .back
    test edx, edx
    jle .front_negative_dx
    neg ecx
    imul edx, ecx
    jmp short .front_y
.front_negative_dx:
    mov edx, edi
.front_y:
    test eax, eax
    jle .front_negative_dy
    sub esi, ebx
    imul eax, esi
    jmp short .front_result
.front_negative_dy:
    neg ebx
    imul eax, ebx
.front_result:
    cmp edx, eax
    setl al
    and eax, 255
    jmp short .return
.back:
    test edx, edx
    jle .back_negative_dx
    mov edx, edi
    jmp short .back_y
.back_negative_dx:
    neg ecx
    imul edx, ecx
.back_y:
    test eax, eax
    jle .back_negative_dy
    neg ebx
    imul eax, ebx
    jmp short .back_result
.back_negative_dy:
    sub esi, ebx
    imul eax, esi
.back_result:
    cmp edx, eax
    setge al
    and eax, 255
    add eax, eax
.return:
    add esp, 12
    pop ebp
    pop edi
    pop esi
    ret 12
