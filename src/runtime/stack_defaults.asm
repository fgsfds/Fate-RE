BITS 32
ORG 0x16c50

initial_stack_selector: dw 0
overflow_message: db "Stack Overflow!", 13, 10, 0
