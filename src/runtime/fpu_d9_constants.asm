; D9 register operations for sign, classification, and constant loads.
BITS 32
ORG 0x68ac8

decode_next equ 0x67e50
skip_register equ 0x68984
compare_extended equ 0x6973a
update_flags equ 0x68044
classify_value equ 0x6a2ea
zero_constant equ 0x67a44 - 0x10000
previous_top equ 0x67a50 - 0x10000
top_bits equ 0x67a52 - 0x10000
tag_clear equ 0x67a9e - 0x10000
tag_zero equ 0x67aa0 - 0x10000

dispatch_sign_test:
    jmp dword cs:[ebx*4 + sign_test_table - 0x10000]

sign_test_table:
    dd fchs - 0x10000, fabs - 0x10000
    times 2 dd skip_register - 0x10000
    dd ftst - 0x10000, fxam - 0x10000
    times 2 dd skip_register - 0x10000

fchs:
    lea eax, [edi + ebp + 0x1c]
    xor byte [eax + 9], 0x80
    jmp near decode_next

fabs:
    lea eax, [edi + ebp + 0x1c]
    and byte [eax + 9], 0x7f
    jmp near decode_next

ftst:
    mov eax, cs:[zero_constant]
    mov ds:[ebp + 0x6c], eax
    mov eax, cs:[zero_constant + 4]
    mov ds:[ebp + 0x70], eax
    mov ax, word cs:[zero_constant + 8]
    mov word ds:[ebp + 0x74], ax
    lea eax, [edi + ebp + 0x1c]
    lea edx, [ebp + 0x6c]
    call compare_extended
    jmp near update_flags

fxam:
    lea eax, [edi + ebp + 0x1c]
    call classify_value
    jmp near decode_next

dispatch_constant:
    jmp dword cs:[ebx*4 + constant_table - 0x10000]

constant_table:
    dd fld1 - 0x10000, fldl2t - 0x10000, fldl2e - 0x10000, fldpi - 0x10000
    dd fldlg2 - 0x10000, fldln2 - 0x10000, fldz - 0x10000, skip_register - 0x10000

%macro push_slot 0
    movzx edi, word cs:[edi + previous_top]
    mov bx, word cs:[edi + top_bits]
    and word ds:[ebp + 4], 0xc7ff
    or word ds:[ebp + 4], bx
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    lea esi, [edi + ebp + 0x1c]
%endmacro

fld1:
    push_slot
    db 0x2b, 0xc0 ; SUB EAX, EAX uses the register-destination opcode.
    mov [esi], eax
    mov dword [esi + 4], 0x80000000
    mov word [esi + 8], 0x3fff
    jmp near decode_next

%macro load_constant 4
%1:
    push_slot
    mov dword [esi], %2
    mov dword [esi + 4], %3
    mov word [esi + 8], %4
    jmp near decode_next
%endmacro

load_constant fldl2t, 0xcd1b8afe, 0xd49a784b, 0x4000
load_constant fldl2e, 0x5c17f0bc, 0xb8aa3b29, 0x3fff
load_constant fldpi,  0x2168c235, 0xc900daa2, 0x4000
load_constant fldlg2, 0xfbcff799, 0x9a209a84, 0x3ffd
load_constant fldln2, 0xd1cf79ac, 0xb17217f7, 0x3ffe

fldz:
    push_slot
    db 0x2b, 0xc0 ; SUB EAX, EAX uses the register-destination opcode.
    mov [esi], eax
    mov [esi + 4], eax
    mov [esi + 8], ax
    mov bx, word cs:[edi + tag_clear]
    and word ds:[ebp + 8], bx
    mov bx, word cs:[edi + tag_zero]
    or word ds:[ebp + 8], bx
    jmp near decode_next
