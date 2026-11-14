; Watcom stack availability, selector initialization and overflow handling.
BITS 32
ORG 0x67006

stack_bottom equ 0x1447c
initial_stack_selector equ 0x16c50
overflow_message equ 0x16c52
fatal_runtime_error equ 0x6e69c

stackavail_:
    mov eax, esp
    sub eax, [stack_bottom]
    ret

stack_helper_separator:
    db 0

save_stack_selector:
    db 0x66 ; Original redundant operand-size prefix on the segment store.
    mov [initial_stack_selector], ss
    ret

check_stack:
    xchg [esp + 4], eax
    call check_stack_space
    mov eax, [esp + 4]
    ret 4

discard_stack_check_argument:
    ret 4

check_stack_space:
    cmp eax, esp
    jae short .check_selector
    sub eax, esp
    neg eax
    cmp eax, [stack_bottom]
    jbe short .check_selector
    ret
.check_selector:
    mov ax, ss
    cmp ax, [initial_stack_selector]
    je short report_stack_overflow
    ret

report_stack_overflow:
    mov eax, overflow_message
    mov edx, 1
    call fatal_runtime_error
