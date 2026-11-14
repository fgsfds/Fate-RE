; Program the VGA sequencer and CRT controller for planar Mode X.
BITS 32
ORG 0x5c7a1

presentation_width equ 0x287e90
presentation_height equ 0x287e8c

misc_output_write equ 0x3c2
sequencer_index equ 0x3c4
misc_output_read equ 0x3cc
crtc_index equ 0x3d4
crtc_data equ 0x3d5

setxmode_:
    ; Unlock the protected CRTC registers and disable chained addressing.
    push ebx
    mov  eax, 0x11
    mov  edx, crtc_index
    out  dx, al
    mov  edx, crtc_data
    in   al, dx
    and  eax, 0x7f
    out  dx, al
    mov  eax, 0x14
    mov  edx, crtc_index
    out  dx, ax
    mov  eax, 0xe317
    out  dx, ax
    mov  eax, 0x604
    mov  edx, sequencer_index
    out  dx, ax
    mov  eax, [presentation_width]
    cmp  eax, 0x140
    jb   short .check_width_256
    jbe  short .width_320
    cmp  eax, 0x168
    jb   near .unsupported_width
    jbe  near .width_360
    cmp  eax, 0x190
    je   near .width_400
    jmp  near .unsupported_width

.check_width_256:
    cmp  eax, 0x100
    jne  near .unsupported_width
    out  dx, ax
    mov  edx, misc_output_read
    in   al, dx
    mov  edx, misc_output_write
    and  eax, 0xf3
    out  dx, al
    mov  eax, 0x300
    mov  edx, sequencer_index
    out  dx, ax
    mov  eax, 0x5f00
    mov  edx, crtc_index
    out  dx, ax
    mov  eax, 0x8203
    out  dx, ax
    mov  eax, 0x4e04
    out  dx, ax
    mov  eax, 0x9605

.write_horizontal_sync_end:
    out  dx, ax
    jmp  near .set_horizontal_geometry

.width_320:
    mov  eax, 0x100
    out  dx, ax
    mov  edx, misc_output_read
    in   al, dx
    mov  edx, misc_output_write
    and  eax, 0xf3
    out  dx, al
    mov  eax, 0x300
    mov  edx, sequencer_index
    out  dx, ax
    mov  eax, 0x5f00
    mov  edx, crtc_index
    out  dx, ax
    mov  eax, 0x8203
    out  dx, ax
    mov  eax, 0x5404
    out  dx, ax
    mov  eax, 0x8005
    jmp  short .write_horizontal_sync_end

.width_360:
    mov  eax, 0x100
    out  dx, ax
    mov  edx, misc_output_read
    in   al, dx
    and  eax, 0xf3
    mov  edx, misc_output_write
    or   al, 4
    out  dx, al
    mov  eax, 0x300
    mov  edx, sequencer_index
    out  dx, ax
    mov  eax, 0x6b00
    mov  edx, crtc_index
    out  dx, ax
    mov  eax, 0x8e03
    out  dx, ax
    mov  eax, 0x5e04
    out  dx, ax
    mov  eax, 0x8a05
    jmp  near .write_horizontal_sync_end

.width_400:
    mov  eax, 0x100
    out  dx, ax
    mov  edx, misc_output_read
    in   al, dx
    and  eax, 0xf3
    mov  edx, misc_output_write
    or   al, 4
    out  dx, al
    mov  eax, 0x300
    mov  edx, sequencer_index
    out  dx, ax
    mov  eax, 0x7400
    mov  edx, crtc_index
    out  dx, ax
    mov  eax, 0x9203
    out  dx, ax
    mov  eax, 0x6504
    out  dx, ax
    mov  eax, 0x6c04
    out  dx, ax
    mov  eax, 0x8105
    jmp  near .write_horizontal_sync_end

.unsupported_width:
    mov  eax, 0xffffffff
    pop  ebx
    ret

.set_horizontal_geometry:
    mov  eax, [presentation_width]
    sar  eax, 2
    shl  eax, 8
    mov  edx, crtc_index
    sub  eax, 0xff
    out  dx, ax
    mov  eax, [presentation_width]
    sar  eax, 2
    shl  eax, 8
    add  eax, 2
    out  dx, ax
    mov  eax, [presentation_width]
    sar  eax, 3
    shl  eax, 8
    add  eax, 0x13
    out  dx, ax
    mov  eax, [presentation_height]
    cmp  eax, 0x15e
    jb   short .check_heights_below_350
    jbe  near .timing_350
    cmp  eax, 0x1e0
    jb   short .check_heights_360_and_400
    jbe  near .timing_240_or_480
    cmp  eax, 0x200
    jb   near .select_scanline_repeat
    jbe  near .timing_256_or_512
    cmp  eax, 0x21c
    je   near .timing_270_or_540
    jmp  near .select_scanline_repeat

.check_heights_360_and_400:
    cmp  eax, 0x168
    jb   near .select_scanline_repeat
    jbe  near .timing_360
    cmp  eax, 0x190
    je   near .timing_200_or_400
    jmp  near .select_scanline_repeat

.check_heights_below_350:
    cmp  eax, 0x100
    jb   short .check_heights_below_256
    jbe  near .timing_256_or_512
    cmp  eax, 0x10e
    jb   near .select_scanline_repeat
    jbe  near .timing_270_or_540
    cmp  eax, 0x12c
    je   short .timing_300
    jmp  near .select_scanline_repeat

.check_heights_below_256:
    cmp  eax, 0xc8
    jb   near .select_scanline_repeat
    jbe  near .timing_200_or_400
    cmp  eax, 0xf0
    je   near .timing_240_or_480
    jmp  near .select_scanline_repeat

.timing_300:
    mov  eax, 0x100
    mov  edx, sequencer_index
    out  dx, ax
    mov  edx, misc_output_read
    in   al, dx
    and  eax, 0x3f
    mov  edx, misc_output_write
    or   al, 0x80
    out  dx, al
    mov  eax, 0x300
    mov  edx, sequencer_index
    out  dx, ax
    mov  eax, 0x4606
    mov  edx, crtc_index
    out  dx, ax
    mov  eax, 0x1f07
    out  dx, ax
    mov  eax, 0x4009
    out  dx, ax
    mov  eax, 0x3110
    out  dx, ax
    mov  eax, 0x8011
    out  dx, ax
    mov  eax, 0x2b12
    out  dx, ax
    mov  eax, 0x2f15
    out  dx, ax
    mov  eax, 0x4416
    jmp  near .write_vertical_blank_end

.timing_350:
    mov  eax, 0x100
    mov  edx, sequencer_index
    out  dx, ax
    mov  edx, misc_output_read
    in   al, dx
    and  eax, 0x3f
    mov  edx, misc_output_write
    or   al, 0x80
    out  dx, al
    mov  eax, 0x300
    mov  edx, sequencer_index
    out  dx, ax
    mov  eax, 0x7c06
    mov  edx, crtc_index
    out  dx, ax
    mov  eax, 0x1f07
    out  dx, ax
    mov  eax, 0x4009
    out  dx, ax
    mov  eax, 0x6210
    out  dx, ax
    mov  eax, 0x8011
    out  dx, ax
    mov  eax, 0x5d12
    out  dx, ax
    mov  eax, 0x5d15
    out  dx, ax
    mov  eax, 0x7a16
    jmp  near .write_vertical_blank_end

.timing_360:
    mov  eax, 0x100
    mov  edx, sequencer_index
    out  dx, ax
    mov  edx, misc_output_read
    in   al, dx
    and  eax, 0x3f
    mov  edx, misc_output_write
    or   al, 0x40
    out  dx, al
    mov  eax, 0x300
    mov  edx, sequencer_index
    out  dx, ax
    mov  eax, 0xbf06
    mov  edx, crtc_index
    out  dx, ax
    mov  eax, 0x1f07
    out  dx, ax
    mov  eax, 0x4009
    out  dx, ax
    mov  eax, 0x8810
    out  dx, ax
    mov  eax, 0x8511
    out  dx, ax
    mov  eax, 0x6712
    out  dx, ax
    mov  eax, 0x6d15
    out  dx, ax
    mov  eax, 0xba16
    jmp  near .write_vertical_blank_end

.timing_200_or_400:
    mov  eax, 0x100
    mov  edx, sequencer_index
    out  dx, ax
    mov  edx, misc_output_read
    in   al, dx
    and  eax, 0x3f
    mov  edx, misc_output_write
    or   al, 0x40
    out  dx, al
    mov  eax, 0x300
    mov  edx, sequencer_index
    out  dx, ax
    mov  eax, 0xbf06
    mov  edx, crtc_index
    out  dx, ax
    mov  eax, 0x1f07
    out  dx, ax
    mov  eax, 0x4009
    out  dx, ax
    mov  eax, 0x9c10
    out  dx, ax
    mov  eax, 0x8e11
    out  dx, ax
    mov  eax, 0x8f12
    out  dx, ax
    mov  eax, 0x9615
    out  dx, ax
    mov  eax, 0xb916
    jmp  near .write_vertical_blank_end

.timing_240_or_480:
    mov  eax, 0x100
    mov  edx, sequencer_index
    out  dx, ax
    mov  edx, misc_output_read
    in   al, dx
    and  eax, 0x3f
    mov  edx, misc_output_write
    or   al, 0xc0
    out  dx, al
    mov  eax, 0x300
    mov  edx, sequencer_index
    out  dx, ax
    mov  eax, 0xd06
    mov  edx, crtc_index
    out  dx, ax
    mov  eax, 0x3e07
    out  dx, ax
    mov  eax, 0x4009
    out  dx, ax
    mov  eax, 0xea10
    out  dx, ax
    mov  eax, 0xac11
    out  dx, ax
    mov  eax, 0xdf12
    out  dx, ax
    mov  eax, 0xe715
    out  dx, ax
    mov  eax, 0x616
    jmp  near .write_vertical_blank_end

.timing_256_or_512:
    mov  eax, 0x100
    mov  edx, sequencer_index
    out  dx, ax
    mov  edx, misc_output_read
    in   al, dx
    and  eax, 0x3f
    mov  edx, misc_output_write
    or   al, 0xc0
    out  dx, al
    mov  eax, 0x300
    mov  edx, sequencer_index
    out  dx, ax
    mov  eax, 0x2306
    mov  edx, crtc_index
    out  dx, ax
    mov  eax, 0xb207
    out  dx, ax
    mov  eax, 0x6009
    out  dx, ax
    mov  eax, 0xa10
    out  dx, ax
    mov  eax, 0xac11
    out  dx, ax
    mov  eax, 0xff12
    out  dx, ax
    mov  eax, 0x715
    out  dx, ax
    mov  eax, 0x1a16
    jmp  short .write_vertical_blank_end

.timing_270_or_540:
    mov  eax, 0x100
    mov  edx, sequencer_index
    out  dx, ax
    mov  edx, misc_output_read
    in   al, dx
    and  eax, 0x3f
    mov  edx, misc_output_write
    or   al, 0xc0
    out  dx, al
    mov  eax, 0x300
    mov  edx, sequencer_index
    out  dx, ax
    mov  eax, 0x3006
    mov  edx, crtc_index
    out  dx, ax
    mov  eax, 0xf007
    out  dx, ax
    mov  eax, 0x6009
    out  dx, ax
    mov  eax, 0x2010
    out  dx, ax
    mov  eax, 0xa911
    out  dx, ax
    mov  eax, 0x1b12
    out  dx, ax
    mov  eax, 0x1f15
    out  dx, ax
    mov  eax, 0x2f16

.write_vertical_blank_end:
    out  dx, ax

.select_scanline_repeat:
    mov  eax, [presentation_height]
    cmp  eax, 0x15e
    jb   short .repeat_check_below_350
    jbe  near .single_scanline
    cmp  eax, 0x1e0
    jb   short .repeat_check_360_and_400
    jbe  near .single_scanline
    cmp  eax, 0x200
    jb   near .write_max_scanline
    jbe  short .single_scanline
    cmp  eax, 0x21c

.check_equal_for_single_scanline:
    je   short .single_scanline
    jmp  short .write_max_scanline

.repeat_check_360_and_400:
    cmp  eax, 0x168
    jb   short .write_max_scanline
    jbe  short .single_scanline
    cmp  eax, 0x190
    jmp  short .check_equal_for_single_scanline

.repeat_check_below_350:
    cmp  eax, 0x100
    jb   short .repeat_check_below_256
    jbe  short .double_scanline
    cmp  eax, 0x10e
    jb   short .write_max_scanline
    jbe  short .double_scanline
    cmp  eax, 0x12c
    jmp  short .check_equal_for_single_scanline

.repeat_check_below_256:
    cmp  eax, 0xc8
    jb   short .write_max_scanline
    jbe  short .double_scanline
    cmp  eax, 0xf0
    jne  short .write_max_scanline

.double_scanline:
    mov  ebx, 1
    jmp  short .write_max_scanline

.single_scanline:
    xor  ebx, ebx

.write_max_scanline:
    mov  eax, 9
    mov  edx, crtc_index
    out  dx, al
    mov  edx, crtc_data
    in   al, dx
    mov  edx, eax
    mov  eax, ebx
    and  edx, 0xe0
    and  eax, 0x1f
    or   eax, edx
    mov  edx, crtc_data
    out  dx, al
    xor  eax, eax
    pop  ebx
    ret
