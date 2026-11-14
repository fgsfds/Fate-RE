; CODE-relative bank selector pointers for adapter IDs 1 through 12.
BITS 32

select_vbe_bank equ 0x7286a
select_sequencer_bank equ 0x72897
select_graphics_controller_bank equ 0x72912
select_indexed_b2_bank equ 0x72936
select_segment_bank_3cd_shift3 equ 0x72963
select_segment_bank_3cd equ 0x72986
select_segment_bank_3df equ 0x729a9
select_sequencer_0e_bank equ 0x729cc
select_extended_10_bank equ 0x729f2
select_sequencer_06_bank equ 0x72a20
select_crtc_35_bank equ 0x72a4d

    dd select_vbe_bank - 0x10000
    dd select_sequencer_bank - 0x10000
    dd select_graphics_controller_bank - 0x10000
    dd select_indexed_b2_bank - 0x10000
    dd select_segment_bank_3cd_shift3 - 0x10000
    dd select_segment_bank_3cd - 0x10000
    dd select_segment_bank_3df - 0x10000
    dd select_sequencer_0e_bank - 0x10000
    dd select_extended_10_bank - 0x10000
    dd select_sequencer_06_bank - 0x10000
    dd select_crtc_35_bank - 0x10000
    dd select_graphics_controller_bank - 0x10000
