; CODE-relative entries for page present dispatch.
BITS 32
ORG 0x4b47e

code_base equ 0x10000
case_4b624 equ 0x4b624
case_4b874 equ 0x4b874
case_4b8df equ 0x4b8df
case_4b8f3 equ 0x4b8f3
case_4b91b equ 0x4b91b
case_4b93d equ 0x4b93d

page_present_dispatch:
    dd case_4b624 - code_base
    dd case_4b874 - code_base
    dd case_4b8df - code_base
    dd case_4b8f3 - code_base
    dd case_4b91b - code_base
    dd case_4b93d - code_base
