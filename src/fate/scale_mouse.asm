; Scale signed mouse deltas and narrow the truncated results to words.
BITS 32
ORG 0x3a96d
scale_x equ 0x13a81
scale_y equ 0x13a85
truncate_st0 equ 0x60304

scale_mouse_:
    push ebx
    sub esp,4
    fild word [eax]
    fld st0
    fmul dword [scale_x]
    fstp st1
    call truncate_st0
    fistp dword [esp]
    mov ebx,[esp]
    mov [eax],bx
    fild word [edx]
    fld st0
    fmul dword [scale_y]
    fstp st1
    call truncate_st0
    fistp dword [esp]
    mov eax,[esp]
    mov [edx],ax
    add esp,4
    pop ebx
    ret
