; Set up and draw a textured column on a sloped sector plane.
; Select the original register-load direction for equivalent x86 encodings.
%macro LOAD_FORM 4
    db %1, 0xc0 | (%2 << 3) | %3 ; %4
%endmacro
BITS 32
ORG 0x74f20

code_operand_6503a equ 0x6503a
code_operand_65033 equ 0x65033
code_operand_64f8c equ 0x64f8c
code_operand_6502b equ 0x6502b
code_operand_65028 equ 0x65028
code_operand_65023 equ 0x65023
data_286aa4 equ 0x286aa4
data_286aa8 equ 0x286aa8
data_286b3c equ 0x286b3c
data_286b2c equ 0x286b2c
code_operand_65041 equ 0x65041
data_286aac equ 0x286aac
data_286a48 equ 0x286a48
data_286a54 equ 0x286a54
data_286b20 equ 0x286b20
data_1d3160 equ 0x1d3160
data_286ab0 equ 0x286ab0

setupslopevlin_:
    mov dword [code_operand_6503a], ebx
    mov dword [code_operand_65033], ecx
    neg ecx
    mov dword [code_operand_64f8c], ecx
    mov edx, 1
    LOAD_FORM 0x8a, 1, 0, "mov cl, al"
    shl edx, cl
    dec edx
    LOAD_FORM 0x8a, 1, 4, "mov cl, ah"
    shl edx, cl
    mov dword [code_operand_6502b], edx
    neg ah
    mov byte [code_operand_65028], ah
    LOAD_FORM 0x2a, 4, 0, "sub ah, al"
    mov byte [code_operand_65023], ah
    fild dword [data_286aa4]
    fstp dword [data_286aa8]
    ret
    times 5 xchg ebx, ebx
    nop

slopevlin_:
    mov dword [data_286b3c], ebp
    mov dword [data_286b2c], esp
    LOAD_FORM 0x2b, 1, 4, "sub ecx, esp"
    mov dword [code_operand_65041], ecx
    fild dword [data_286aac]
    lea ebp, [eax - 0x77777778]
    fadd dword [data_286aa8]
    mov dword [data_286aa4], ebx
    shl ebx, 3
    mov eax, dword [data_286a48]
    mov ecx, dword [data_286a54]
    imul eax, ebx
    imul ecx, ebx
    LOAD_FORM 0x3, 6, 0, "add esi, eax"
    LOAD_FORM 0x3, 7, 1, "add edi, ecx"
    LOAD_FORM 0x8b, 3, 2, "mov ebx, edx"
    jmp short .branch_0a0
    xchg ebx, ebx
    xchg ebx, ebx
    xchg ebx, ebx
    xchg ebx, ebx

.branch_0a0:
    fst dword [data_286b20]
    mov eax, dword [data_286b20]
    LOAD_FORM 0x3, 0, 0, "add eax, eax"
    LOAD_FORM 0x1b, 2, 2, "sbb edx, edx"
    LOAD_FORM 0x8b, 1, 0, "mov ecx, eax"
    shr ecx, 0x18
    and eax, 0xffe000
    shr eax, 0xb
    sub cl, 2
    mov eax, dword [eax + data_1d3160]
    shr eax, cl
    LOAD_FORM 0x33, 0, 2, "xor eax, edx"
    mov edx, dword [data_286aa4]
    mov ecx, dword [data_286a48]
    mov dword [data_286aa4], eax
    LOAD_FORM 0x2b, 0, 2, "sub eax, edx"
    mov edx, dword [data_286a54]
    imul ecx, eax
    imul eax, edx
    fadd dword [data_286aa8]
    cmp ebx, 8
    mov dword [data_286ab0], ebx
    LOAD_FORM 0x8a, 1, 3, "mov cl, bl"
    jl short .branch_0fd
    mov cl, 8

.branch_0fd:
    LOAD_FORM 0x8b, 3, 6, "mov ebx, esi"
    LOAD_FORM 0x8b, 2, 7, "mov edx, edi"

.branch_101:
    shr ebx, 0x14
    LOAD_FORM 0x3, 6, 1, "add esi, ecx"
    shr edx, 0x1a
    and ebx, 0x88888888
    LOAD_FORM 0x3, 7, 0, "add edi, eax"
    add ebp, 0x88888888
    mov dl, byte [ebx + edx - 0x77777778]
    mov ebx, dword [esp - 0x77777778]
    sub esp, 4
    dec cl
    mov al, byte [ebx + edx]
    LOAD_FORM 0x8b, 3, 6, "mov ebx, esi"
    mov byte [ebp], al
    LOAD_FORM 0x8b, 2, 7, "mov edx, edi"
    jne short .branch_101
    mov ebx, dword [data_286ab0]
    sub ebx, 8
    jg near .branch_0a0
    wait
    ffree st0
    mov esp, dword [data_286b2c]
    mov ebp, dword [data_286b3c]
    ret
