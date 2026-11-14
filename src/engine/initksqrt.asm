; FATE square-root table initialization, using the Build algorithm.
; Build Engine & Tools Copyright (c) 1993-1997 Ken Silverman.
; See BUILDLIC.TXT. This reconstruction differs from the released source.
BITS 32
ORG 0x4caaa
sqrtable_bias equ 0x1dfa5e ; DS:sqrtable minus one word for the incremented index
shared_return equ 0x4abbf

initksqrt_:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    xor edi, edi
    jmp near .test_index
.entry:
    mov esi, edi
    mov ecx, 128
    shl esi, 20
.newton:
    mov eax, esi
    xor edx, edx
    div ecx
    mov ebx, ecx
    add ecx, eax
    shr ecx, 1
    mov eax, ebx
    sub eax, ecx
    inc eax
    cmp eax, 2
    ja .newton
    mov ebx, ecx
    imul ebx, ecx
    sub ebx, esi
.round_down:
    mov eax, ebx
    lea edx, [ecx+ecx]
    sub eax, edx
    inc eax
    test eax, eax
    jns .lower_abs
    neg eax
.lower_abs:
    mov esi, eax
    mov eax, ebx
    test eax, eax
    jns .error_abs_down
    neg eax
.error_abs_down:
    cmp esi, eax
    jge .round_up
    mov eax, edx
    neg eax
    inc eax
    dec ecx
    add ebx, eax
    jmp .round_down
.round_up:
    lea esi, [ecx+ecx]
    lea eax, [ebx+esi+1]
    test eax, eax
    jns .upper_abs
    neg eax
.upper_abs:
    mov edx, eax
    mov eax, ebx
    test eax, eax
    jns .error_abs_up
    neg eax
.error_abs_up:
    cmp edx, eax
    jge .store
    inc esi
    inc ecx
    add ebx, esi
    jmp .round_up
.store:
    inc edi
    mov [nosplit edi*2+sqrtable_bias], cx
.test_index:
    cmp edi, 2048
    jb short .entry
    jmp near shared_return
