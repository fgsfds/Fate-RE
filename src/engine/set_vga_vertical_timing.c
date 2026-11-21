/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

/* Preserve the timing arguments and the registers restored by the shared return. */
extern void begin_vertical_timing(long total, long blank_start, long blank_end);
#pragma aux begin_vertical_timing = "push esi" "push edi" "push ebp" "mov esi,eax" \
    "mov edi,edx" "mov ebp,ebx" parm [eax] [edx] [ebx] modify exact [esi edi];
extern void select_vga_crtc(long index);
#pragma aux select_vga_crtc = "mov edx,3d4h" "out dx,al" parm [eax] modify exact [edx];
extern long read_vga_crtc(void);
#pragma aux read_vga_crtc = "mov edx,3d5h" "in al,dx" value [eax] modify exact [eax edx];
extern void write_vga_crtc(long value);
#pragma aux write_vga_crtc = "out dx,al" parm [eax] modify exact [];
extern void write_vga_crtc_low_byte(long value);
#pragma aux write_vga_crtc_low_byte = "mov edx,3d5h" "and eax,0ffh" "out dx,al" parm [eax] modify exact [eax edx];
extern long vertical_total(void);
#pragma aux vertical_total = value [esi] modify exact [];
extern long vertical_blank_start(void);
#pragma aux vertical_blank_start = value [edi] modify exact [];
extern long vertical_blank_end(void);
#pragma aux vertical_blank_end = value [ebp] modify exact [];
extern long vertical_retrace_start(void);
#pragma aux vertical_retrace_start = value [ecx] modify exact [];
extern long vertical_display_end(void);
#pragma aux vertical_display_end = "mov eax,[esp+14h]" value [eax] modify exact [eax];

extern void start_vga_overflow(long bit);
#pragma aux start_vga_overflow = "mov bl,al" parm [eax] modify exact [ebx];
extern void add_vga_overflow(long bit);
#pragma aux add_vga_overflow = "and ebx,0ffh" "add ebx,eax" parm [eax] modify exact [ebx];
extern void finish_vga_overflow(long bit);
#pragma aux finish_vga_overflow = "and ebx,0ffh" "mov edx,3d4h" "add ebx,eax" "mov eax,7" \
    "out dx,al" "mov edx,3d5h" "in al,dx" "mov esi,eax" "xor eax,eax" "and esi,10h" \
    "mov al,bl" "or eax,esi" "out dx,al" parm [eax] modify exact [eax ebx edx esi];

extern void preserve_scanline_register(long old_value);
#pragma aux preserve_scanline_register = "mov ebx,eax" parm [eax] modify exact [ebx];
extern long clear_old_blank_high_bit(long blank);
#pragma aux clear_old_blank_high_bit = "and ebx,0dfh" parm [eax] value [eax] modify exact [ebx];
extern long saved_scanline_register(void);
#pragma aux saved_scanline_register = value [ebx] modify exact [];
extern long read_retrace_end_crtc(long index);
#pragma aux read_retrace_end_crtc = "mov edx,3d4h" "mov ebx,[esp+10h]" "out dx,al" \
    "mov edx,3d5h" "and ebx,0fh" "in al,dx" parm [eax] value [eax] modify exact [eax ebx edx];
extern long retrace_end_low_bits(void);
#pragma aux retrace_end_low_bits = value [ebx] modify exact [];
extern void finish_vertical_timing(void);
#pragma aux finish_vertical_timing aborts modify exact [];
#pragma aux set_vga_vertical_timing modify exact [eax ebx ecx edx esi edi];

void set_vga_vertical_timing(long total, long blank_start, long blank_end,
                             long retrace_start, long retrace_end, long display_end)
{
    long old_value, blank_high, retrace;

    begin_vertical_timing(total, blank_start, blank_end);
    /* Unlock the protected vertical timing registers. */
    select_vga_crtc(0x11);
    write_vga_crtc(read_vga_crtc() & 0x7f);

    select_vga_crtc(0x06);
    write_vga_crtc_low_byte(vertical_total());

    /* Pack bits 8 and 9 from the timing values into the CRTC overflow register. */
    start_vga_overflow((vertical_total() & 0x100) >> 8);
    add_vga_overflow((vertical_display_end() & 0x100) >> 7);
    add_vga_overflow((vertical_retrace_start() & 0x100) >> 6);
    add_vga_overflow((vertical_blank_start() & 0x100) >> 5);
    add_vga_overflow((vertical_total() & 0x200) >> 4);
    add_vga_overflow((vertical_display_end() & 0x200) >> 3);
    finish_vga_overflow((vertical_retrace_start() & 0x200) >> 2);

    /* The high bit of vertical blank start lives in the scanline register. */
    select_vga_crtc(0x09);
    old_value = read_vga_crtc();
    preserve_scanline_register(old_value);
    blank_high = clear_old_blank_high_bit(vertical_blank_start() & 0x200) >> 4;
    write_vga_crtc(blank_high | saved_scanline_register());

    select_vga_crtc(0x10);
    write_vga_crtc_low_byte(vertical_retrace_start());
    retrace = read_retrace_end_crtc(0x11) & 0xf0;
    write_vga_crtc(retrace + retrace_end_low_bits());
    select_vga_crtc(0x12);
    write_vga_crtc_low_byte(vertical_display_end());
    select_vga_crtc(0x15);
    write_vga_crtc_low_byte(vertical_blank_start());
    select_vga_crtc(0x16);
    write_vga_crtc_low_byte(vertical_blank_end());
    select_vga_crtc(0x09);
    write_vga_crtc(read_vga_crtc() & 0xfe);
    finish_vertical_timing();
}
