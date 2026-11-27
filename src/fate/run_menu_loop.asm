; Register and stack setup for the compiled menu-loop body.
BITS 32
ORG 0x3963b

run_menu_loop_entry:
    push esi
    push edi
    push ebp
    sub esp, 0x8
    mov esi, [esp + 0x18]
    mov [esp], edx
    mov edi, ebx
    mov ebp, ecx
