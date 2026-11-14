; Initial CODE-relative pointers to the bitmap replacement operations.
BITS 32

replace_masked_byte equ 0x73b60
replace_byte_run equ 0x73b6f

    dd replace_masked_byte - 0x10000
    dd replace_byte_run - 0x10000
