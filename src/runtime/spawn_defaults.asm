; Default save/restore hooks before x87 initialization installs replacements.
BITS 32
ORG 0x17408

path_noop equ 0x6792b
    times 2 dd path_noop - 0x10000
