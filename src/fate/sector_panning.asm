; The original CODE-relative dispatch table used by update_sector_panning.
BITS 32
ORG 0x11e5e

pan_entry equ 0x11e8e - 0x10000
sector_panning_dispatch:
    dd pan_entry + 0x68  ; slow floor X
    dd pan_entry + 0x76  ; normal floor X
    dd pan_entry + 0x6b  ; fast floor X
    dd pan_entry + 0x81  ; slow floor Y
    dd pan_entry + 0x8c  ; normal floor Y
    dd pan_entry + 0x94  ; fast floor Y
    dd pan_entry + 0x9a  ; slow ceiling X
    dd pan_entry + 0xc2  ; normal ceiling X
    dd pan_entry + 0xca  ; fast ceiling X
    dd pan_entry + 0xd2  ; slow ceiling Y
    dd pan_entry + 0xfe  ; normal ceiling Y
    dd pan_entry + 0xe1  ; fast ceiling Y
