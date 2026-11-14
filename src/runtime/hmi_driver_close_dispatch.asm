; CODE-relative entries called by the HMI driver initialization path.
BITS 32
ORG 0x16a84

code_base equ 0x10000
    dd 0x620d6 - code_base, 0x620f9 - code_base, 0x6211c - code_base
    dd 0x6213f - code_base, 0x62162 - code_base
