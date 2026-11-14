; Read the CRT stack floor for the graphics stack-budget checks.
BITS 32
ORG 0x71b86

stack_floor equ 0x1447c

graphics_stack_limit:
    mov eax, dword [stack_floor]
    ret
