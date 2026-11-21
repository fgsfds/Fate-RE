; Maintain near heaps and allocate or resize their DOS and DPMI backing blocks.
BITS 32
ORG 0x65151

free_ equ 0x6170a
near_heap_head equ 0x141b8
near_heap_rover equ 0x141bc
memory_limit equ 0x1446c
extender_type equ 0x1449a
extender_flags equ 0x1449c
dos_reserve_bytes equ 0x2892dc
dos_reserve_high_word equ 0x2892de

unlink_near_heap equ 0x65151
link_and_initialize_heap equ 0x652f1

    times 63 db 0    ; unlink_near_heap is supplied by C.

release_empty_heaps equ 0x65190
    times 94 db 0    ; release_empty_heaps is supplied by C.

    times 259 db 0   ; resize_dpmi_heap is supplied by C.

    times 116 db 0   ; link_and_initialize_heap is supplied by C.

    times 78 db 0    ; free_space_at_break is supplied by C.

allocate_dpmi_heap equ 0x653b3
    times 211 db 0   ; allocate_dpmi_heap is supplied by C.
