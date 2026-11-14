; Fill memory, flush streams, format strings and handle console text.
BITS 32
ORG 0x62dce

token_resume equ 0x14250
bit_masks equ 0x2024
open_streams equ 0x2891e0
pending_console_char equ 0x1448c
build_delimiter_map equ 0x67058
flush_stream equ 0x64b31
format_engine equ 0x635bb

toupper_:
    cmp eax, 0x61
    jl short .branch_62ddb
    cmp eax, 0x7a
    jg short .branch_62ddb
    sub eax, 0x20

.branch_62ddb:
    ret

toupper_padding:
    times 4 db 0

fill_byte_pattern:
    or ecx, ecx
    je short .return
    cmp byte [eax], dl

.align_byte_destination:
    test al, 3
    je short .fill_words
    mov byte [eax], dl
    inc eax
    ror edx, 8
    dec ecx
    jne short .align_byte_destination

.fill_words:
    push ecx
    shr ecx, 2
    call fill_dword_pattern
    pop ecx
    and ecx, 3
    je short .return
    mov byte [eax], dl
    dec ecx
    je short .return
    mov byte [eax + 1], dh
    dec ecx
    je short .return
    mov byte [eax + 2], dl

.return:
    ret

fill_alignment:
    times 6 nop

fill_dword_pattern:
    or ecx, ecx
    je short .return

.align_dword_destination:
    test al, 0x1f
    je short .fill_blocks
    mov dword [eax], edx
    lea eax, [eax + 4]
    dec ecx
    jne short .align_dword_destination

.fill_blocks:
    push ecx
    shr ecx, 2
    je short .store_tail
    dec ecx
    je short .store_four_dwords

.store_dword_pairs:
    mov dword [eax], edx
    mov dword [eax + 4], edx
    dec ecx
    mov dword [eax + 8], edx
    mov dword [eax + 0xc], edx
    je short .advance_half_block
    cmp byte [eax + 0x20], dl
    mov dword [eax + 0x10], edx
    mov dword [eax + 0x14], edx
    dec ecx
    mov dword [eax + 0x18], edx
    mov dword [eax + 0x1c], edx
    lea eax, [eax + 0x20]
    jne short .store_dword_pairs
    lea eax, [eax - 0x10]

.advance_half_block:
    lea eax, [eax + 0x10]

.store_four_dwords:
    mov dword [eax], edx
    mov dword [eax + 4], edx
    mov dword [eax + 8], edx
    mov dword [eax + 0xc], edx
    lea eax, [eax + 0x10]

.store_tail:
    pop ecx
    and ecx, 3
    je short .return
    mov dword [eax], edx
    lea eax, [eax + 4]
    dec ecx
    je short .return
    mov dword [eax], edx
    lea eax, [eax + 4]
    dec ecx
    je short .return
    mov dword [eax], edx
    lea eax, [eax + 4]

.return:
    ret

flushall_:
    mov eax, 0xffffffff

flush_matching_streams:
    push ebx
    push ecx
    push edx
    mov ecx, eax
    mov edx, dword [open_streams]
    xor ebx, ebx
    jmp short .check_stream_link

.check_stream_flags:
    mov eax, dword [edx + 4]
    test dword [eax + 0xc], ecx
    je short .advance_stream
    inc ebx
    test byte [eax + 0xd], 0x10
    je short .advance_stream
    call flush_stream

.advance_stream:
    mov edx, dword [edx]

.check_stream_link:
    test edx, edx
    jne short .check_stream_flags
    mov eax, ebx
    pop edx
    pop ecx
    pop ebx
    ret

vsprintf_putc:
    push ebx
    push ecx
    mov bl, dl
    mov edx, dword [eax]
    lea ecx, [edx + 1]
    mov dword [eax], ecx
    mov byte [edx], bl
    inc dword [eax + 0x10]
    pop ecx
    pop ebx
    ret

vsprintf_:
    push ecx
    push esi
    mov esi, eax
    mov ecx, vsprintf_putc - 0x10000
    call format_engine
    mov byte [esi + eax], 0
    pop esi
    pop ecx
    ret

getch_:
    push edx
    xor edx, edx
    mov eax, dword [pending_console_char]
    mov dword [pending_console_char], edx
    test eax, eax
    jne short .return_character
    mov ah, 8
    int 0x21
    and eax, 0xff

.return_character:
    pop edx
    ret

strupr_:
    push ebx
    push edx
    mov ebx, eax

.check_character:
    mov dl, byte [eax]
    test dl, dl
    je short .return_string
    sub dl, 0x61
    cmp dl, 0x19
    ja short .advance_character
    add dl, 0x41
    mov byte [eax], dl

.advance_character:
    inc eax
    jmp short .check_character

.return_string:
    mov eax, ebx
    pop edx
    pop ebx
    ret

strstr_:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 4
    mov esi, eax
    mov ebx, edx
    cmp byte [edx], 0
    jne short .branch_62f33

.branch_62f2c:
    mov eax, esi
    jmp near .branch_62fd4

.branch_62f33:
    cmp byte [edx + 1], 0
    jne short .branch_62f59
    mov dl, byte [ebx]

.branch_62f3b:
    mov al, byte [esi]
    db 0x3a, 0xc2 ; CMP AL, DL uses the register-destination opcode.
    je short .branch_62f57
    cmp al, 0
    je near .branch_62f55
    inc esi
    mov al, byte [esi]
    db 0x3a, 0xc2 ; CMP AL, DL uses the register-destination opcode.
    je short .branch_62f57
    inc esi
    cmp al, 0
    jne short .branch_62f3b

.branch_62f55:
    db 0x2b, 0xf6 ; SUB ESI, ESI uses the register-destination opcode.

.branch_62f57:
    jmp short .branch_62f2c

.branch_62f59:
    mov ecx, 0xffffffff
    mov edi, esi
    xor al, al
    push es
    jecxz .branch_62f70
    mov edx, ds
    mov es, edx
    repne scasb
    jne short .branch_62f70
    dec edi
    db 0x66, 0xa9 ; Fallthrough tests AX; the branch enters the MOV.
.branch_62f70:
    mov edi, ecx
    pop es
    mov dword [esp], edi
    mov edi, ebx
    push es
    mov eax, ds
    mov es, eax
    sub ecx, ecx
    dec ecx
    xor eax, eax
    repne scasb
    not ecx
    dec ecx
    pop es
    mov ebp, ecx

.branch_62f8a:
    mov ecx, dword [esp]
    sub ecx, esi
    cmp ecx, ebp
    jl short .branch_62fd2
    mov edi, esi
    mov al, byte [ebx]
    push es
    jecxz .branch_62fa5
    mov edx, ds
    mov es, edx
    repne scasb
    jne short .branch_62fa5
    dec edi
    db 0x66, 0xa9 ; Fallthrough tests AX; the branch enters the MOV.
.branch_62fa5:
    mov edi, ecx
    pop es
    mov edx, edi
    test edi, edi
    je short .branch_62fd2
    mov esi, edi
    mov ecx, ebp
    mov edi, ebx
    push es
    mov eax, ds
    mov es, eax
    xor eax, eax
    repe cmpsb
    je short .branch_62fc4
    sbb eax, eax
    sbb eax, -1

.branch_62fc4:
    pop es
    test eax, eax
    jne short .branch_62fcd
    mov eax, edx
    jmp short .branch_62fd4

.branch_62fcd:
    lea esi, [edx + 1]
    jmp short .branch_62f8a

.branch_62fd2:
    xor eax, eax

.branch_62fd4:
    add esp, 4
    pop ebp
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

strtok_:
    push ebx
    push ecx
    sub esp, 0x20
    mov ebx, eax
    test eax, eax
    jne short .branch_62ff6
    mov ebx, dword [token_resume]
    test ebx, ebx
    je near .branch_6306c

.branch_62ff6:
    mov eax, esp
    call build_delimiter_map
    jmp short .branch_6301f

.branch_62fff:
    mov edx, eax
    shr edx, 3
    xor ecx, ecx
    mov cl, byte [esp + edx]
    mov edx, eax
    and edx, 7
    mov dl, byte [edx + bit_masks]
    and edx, 0xff
    test ecx, edx
    je short .branch_63027
    inc ebx

.branch_6301f:
    xor eax, eax
    mov al, byte [ebx]
    test eax, eax
    jne short .branch_62fff

.branch_63027:
    test eax, eax
    je short .branch_6306c
    mov eax, ebx
    jmp short .branch_6305c

.branch_6302f:
    mov ecx, edx
    shr ecx, 3
    mov cl, byte [esp + ecx]
    and edx, 7
    and ecx, 0xff
    mov dl, byte [edx + bit_masks]
    and edx, 0xff
    test ecx, edx
    je short .branch_6305b
    mov byte [eax], 0
    inc eax
    mov dword [token_resume], eax
    jmp short .branch_6306a

.branch_6305b:
    inc eax

.branch_6305c:
    xor edx, edx
    mov dl, byte [eax]
    test edx, edx
    jne short .branch_6302f
    mov dword [token_resume], edx

.branch_6306a:
    mov eax, ebx

.branch_6306c:
    add esp, 0x20
    pop ecx
    pop ebx
    ret
