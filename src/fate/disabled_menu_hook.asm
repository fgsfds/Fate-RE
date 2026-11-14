; Disabled menu hook.
BITS 32
ORG 0x3a921


disabled_menu_hook:
    xor eax, eax
    ret
