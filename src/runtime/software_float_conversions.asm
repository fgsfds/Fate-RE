; Software floating-point conversions and the adjacent result helpers.
BITS 32
ORG 0x73ec4

%macro float_to_integer 2
%1:
    push ecx
    mov cl, %2
    call truncate_float
    pop ecx
    ret
%endmacro

float_to_integer float_to_i32, 0x9e
float_to_integer float_to_u32, 0x9f
float_to_integer float_to_i16, 0x8e
float_to_integer float_to_u16, 0x8f
float_to_integer float_to_i8, 0x86
float_to_integer float_to_u8, 0x87

truncate_float:
    or eax, eax
    jns short .magnitude
    call .magnitude
    neg eax
    ret

.magnitude:
    or eax, eax
    jz short .zero
    add eax, eax
    rol eax, 8
    cmp al, 0x7f
    jb short .zero
    mov ch, al
    stc
    rcr eax, 1
    shr eax, 8
    cmp ch, cl
    jae short .limit
    sub ch, 0x96
    jae short .shift_left
    xchg cl, ch
    neg cl
    shr eax, cl
    ret

.shift_left:
    jz short .unchanged
    mov cl, ch
    shl eax, cl
.unchanged:
    ret

.limit:
    mov eax, 0xffffffff
    sub cl, 0x9f
    neg cl
    shr eax, cl
    ret

.zero:
    sub eax, eax
    ret

u32_to_float:
    or eax, eax
    jz short .done
    push ecx
    bsr ecx, eax
    mov ch, cl
    neg cl
    add cl, 0x17
    and cl, 0x1f
    rol eax, cl
    and eax, 0x7fffff
    mov cl, ch
    add cl, 0x7f
    and ecx, strict dword 0xff
    shl ecx, 0x17
    or eax, ecx
    pop ecx
.done:
    ret

i32_to_float:
    or eax, eax
    jns short u32_to_float
    neg eax
    call u32_to_float
    or eax, 0x80000000
    ret

float_to_double:
    mov edx, eax
    and edx, 0x7fffffff
    jne short .nonzero
    jmp short .done

.nonzero:
    cmp edx, 0x7f800000
    jne short .finite_or_nan
    mov edx, eax
    or edx, 0x7ff00000
    sub eax, eax
    jmp short .done

.finite_or_nan:
    test edx, 0x7f800000
    jnz short .pack
    xor eax, edx
    push ecx
    sub ecx, ecx
.normalize:
    add ecx, 0x800000
    add edx, edx
    test edx, 0x800000
    jz short .normalize
    or eax, edx
    sub edx, ecx
    pop ecx

.pack:
    sar edx, 2
    add eax, eax
    rcr edx, 1
    and eax, 0xe
    ror eax, 4
    add edx, 0x38000000
.done:
    ret

float_positive_zero:
    xor eax, eax
    ret

float_largest_finite:
    and eax, 0x80000000
    or eax, 0x7f7fffff
    ret
