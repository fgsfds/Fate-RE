BITS 32

float_support_missing equ 0x6747f

    times 2 dd float_support_missing - 0x10000
