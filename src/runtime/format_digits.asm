; Convert a 32-bit integer to a NUL-terminated string in the requested radix.
BITS 32
ORG 0x67491

format_digits:
    db "0123456789abcdefghijklmnopqrstuvwxyz", 0
