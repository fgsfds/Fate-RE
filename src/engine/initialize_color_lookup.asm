; Initialize weighted RGB distance tables and the palette color buckets.
BITS 32
ORG 0x59582

pow2char equ 0x14029
restore_stack_eax_ebp_edi_esi_ecx equ 0x4bd3e
frame_state_191360 equ 0x191360
frame_state_196350 equ 0x196350
frame_state_27c39d equ 0x27c39d
engine_2863cc equ 0x2863cc
frame_state_286404 equ 0x286404
frame_state_286438 equ 0x286438
frame_state_28643c equ 0x28643c
frame_state_286640 equ 0x286640
frame_state_286844 equ 0x286844
frame_state_289158 equ 0x289158

initialize_color_lookup:
    push ecx
    push esi
    push edi
    push ebp
    push eax
    mov esi, edx
    mov ebp, ebx
    mov edx, 0x40
    xor edi, edi
    jmp short .branch_595e2

.branch_59594:
    mov ebx, [esp]
    imul ebx, edi
    mov ecx, edi
    imul ecx, esi
    mov eax, 0x80
    sub eax, edx
    mov [nosplit eax*4 + frame_state_286844], ecx
    mov [nosplit edx*4 + frame_state_286844], ecx
    mov ecx, edi
    imul ecx, ebp
    mov [nosplit eax*4 + frame_state_28643c], ebx
    mov [nosplit edx*4 + frame_state_28643c], ebx
    mov ebx, 0x81
    mov [nosplit eax*4 + frame_state_286640], ecx
    lea eax, [edx + edx]
    mov [nosplit edx*4 + frame_state_286640], ecx
    sub ebx, eax
    dec edx
    add edi, ebx

.branch_595e2:
    test edx, edx
    jnl short .branch_59594
    mov ecx, 0x7d
    mov edi, frame_state_289158
    xor eax, eax
    cmp ecx, 0x4
    jnc short .branch_59604
    test cl, 0x1
    jz short .branch_595fd
    stosb

.branch_595fd:
    shr ecx, 1
    db 0xf3  ; REP precedes the operand-size override.
    stosw
    jmp short .branch_5962f

.branch_59604:
    test edi, 0x1
    jz short .branch_5960e
    stosb
    dec ecx

.branch_5960e:
    test edi, 0x2
    jz short .branch_5961b
    stosw
    sub ecx, 0x2

.branch_5961b:
    mov ebx, ecx
    shr ecx, byte 0x2
    rep stosd
    test bl, 0x2
    jz short .branch_59629
    stosw

.branch_59629:
    test bl, 0x1
    jz short .branch_5962f
    stosb

.branch_5962f:
    mov ecx, 0x3e8
    mov edi, frame_state_191360
    xor eax, eax
    mov edx, 0xff
    cmp ecx, 0x4
    jnc short .branch_59652
    test cl, 0x1
    jz short .branch_5964b
    stosb

.branch_5964b:
    shr ecx, 1
    db 0xf3  ; REP precedes the operand-size override.
    stosw
    jmp short .branch_5967d

.branch_59652:
    test edi, 0x1
    jz short .branch_5965c
    stosb
    dec ecx

.branch_5965c:
    test edi, 0x2
    jz short .branch_59669
    stosw
    sub ecx, 0x2

.branch_59669:
    mov ebx, ecx
    shr ecx, byte 0x2
    rep stosd
    test bl, 0x2
    jz short .branch_59677
    stosw

.branch_59677:
    test bl, 0x1
    jz short .branch_5967d
    stosb

.branch_5967d:
    mov eax, frame_state_27c39d
    jmp near .branch_5970e

.branch_59687:
    xor ebx, ebx
    mov bl, [eax + 0x1]
    mov ecx, ebx
    xor ebx, ebx
    mov bl, [eax]
    sar ecx, byte 0x3
    sar ebx, byte 0x3
    shl ecx, byte 0x3
    shl ebx, byte 0x6
    add ecx, ebx
    xor ebx, ebx
    mov bl, [eax + 0x2]
    sar ebx, byte 0x3
    lea edi, [ecx + ebx + 0x49]
    mov ebx, edi
    sar ebx, byte 0x3
    xor ecx, ecx
    mov cl, [ebx + frame_state_289158]
    mov ebx, edi
    and ebx, 0x7
    movzx esi, byte [ebx + pow2char]
    mov ebx, edx
    shl ebx, byte 0x2
    test ecx, esi
    jz short .branch_596de
    xor ecx, ecx
    mov cl, [edi + frame_state_191360]
    mov [ebx + frame_state_196350], ecx
    jmp short .branch_596e8

.branch_596de:
    mov dword [ebx + frame_state_196350], 0xffffffff

.branch_596e8:
    mov ebx, edi
    mov [edi + frame_state_191360], dl
    and edi, 0x7
    sar ebx, byte 0x3
    mov cl, [edi + pow2char]
    mov ch, [ebx + frame_state_289158]
    sub eax, 0x3
    or ch, cl
    dec edx
    mov [ebx + frame_state_289158], ch

.branch_5970e:
    test edx, edx
    jnl near .branch_59687
    mov edi, 0xffffffc0
    xor edx, edx
    jmp short .branch_5974c

.branch_5971f:
    mov esi, 0xfffffff8
    jmp short .branch_59744

.branch_59726:
    mov eax, 0xffffffff
    lea ebx, [edi + esi]
    jmp short .branch_5973c

.branch_59730:
    inc edx
    lea ecx, [ebx + eax]
    inc eax
    mov [nosplit edx*4 + engine_2863cc], ecx

.branch_5973c:
    cmp eax, 0x1
    jng short .branch_59730
    add esi, 0x8

.branch_59744:
    cmp esi, 0x8
    jng short .branch_59726
    add edi, 0x40

.branch_5974c:
    cmp edi, 0x40
    jng short .branch_5971f
    mov eax, [frame_state_286438]
    mov edx, [frame_state_286404]
    mov [frame_state_286404], eax
    mov [frame_state_286438], edx
    jmp near restore_stack_eax_ebp_edi_esi_ecx
