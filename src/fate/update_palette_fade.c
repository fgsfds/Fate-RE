/* Advance palette fades and flash timers, then display the current palette. */
extern long fade_level, qsetmode, totalclock;
extern long palette_fade_up, palette_fade_down, palette_fade_step, palette_fade_last_tick;
extern long palette_tint_a_ticks, palette_tint_b_ticks, palette_tint_c_ticks;
extern unsigned char palette_tint_a[], palette_tint_b[], palette_tint_c[], brightness_palette[];

extern void scale_fade_palette(long);
#pragma aux scale_fade_palette parm [eax] modify exact [eax edx];
extern void palette_fade_shared_return(void);
#pragma aux palette_fade_shared_return aborts modify exact [];
extern void wait_vertical_retrace(long);
#pragma aux wait_vertical_retrace parm [ecx] modify exact [eax edx];
extern void write_vga_palette(void);
#pragma aux write_vga_palette modify exact [eax ecx edx];

/* The shared fade return restores the caller registers saved here. */
extern void begin_palette_fade(void);
#pragma aux begin_palette_fade = "push ebx" "push ecx" "push edx" "push esi" "push edi" "push ebp" modify exact [];
extern void load_fade_down(void);
#pragma aux load_fade_down = "mov ebp,dword ptr [palette_fade_down]" modify exact [];
extern void load_fade_level(void);
#pragma aux load_fade_level = "mov ebp,dword ptr [fade_level]" modify exact [];
extern void load_tint_a_timer(void);
#pragma aux load_tint_a_timer = "mov ebp,dword ptr [palette_tint_a_ticks]" modify exact [];
extern void load_tint_b_timer(void);
#pragma aux load_tint_b_timer = "mov ebp,dword ptr [palette_tint_b_ticks]" modify exact [];
extern void load_tint_c_timer(void);
#pragma aux load_tint_c_timer = "mov ebp,dword ptr [palette_tint_c_ticks]" modify exact [];
extern void leave_without_tint(void);
#pragma aux leave_without_tint = "cmp dword ptr [palette_tint_c_ticks],0" "jle near palette_fade_shared_return" modify exact [];
extern void leave_without_vga_palette(void);
#pragma aux leave_without_vga_palette = "cmp dword ptr [qsetmode],200" "jne near palette_fade_shared_return" modify exact [];

/* Keep the Watcom register assignments without emitting instructions. */
extern long in_eax(long);
#pragma aux in_eax = parm [eax] value [eax] modify exact [];
extern long in_ebx(long);
#pragma aux in_ebx = parm [ebx] value [ebx] modify exact [];
extern long in_ecx(long);
#pragma aux in_ecx = parm [ecx] value [ecx] modify exact [];
extern long in_edx(long);
#pragma aux in_edx = parm [edx] value [edx] modify exact [];
extern long in_esi(long);
#pragma aux in_esi = parm [esi] value [esi] modify exact [];
extern long in_edi(long);
#pragma aux in_edi = parm [edi] value [edi] modify exact [];
extern long eax_value(void);
#pragma aux eax_value = value [eax] modify exact [];
extern long ebx_value(void);
#pragma aux ebx_value = value [ebx] modify exact [];
extern long ecx_value(void);
#pragma aux ecx_value = value [ecx] modify exact [];
extern long edx_value(void);
#pragma aux edx_value = value [edx] modify exact [];
extern long esi_value(void);
#pragma aux esi_value = value [esi] modify exact [];
extern long edi_value(void);
#pragma aux edi_value = value [edi] modify exact [];
extern long ebp_value(void);
#pragma aux ebp_value = value [ebp] modify exact [];

extern long increase_eax_fade(long);
#pragma aux increase_eax_fade = "lea edx,[eax+ebp]" parm [eax] value [edx] modify exact [edx];
extern void keep_tint_c_live(long);
#pragma aux keep_tint_c_live = parm [esi] modify exact [];

/* Keep the EBP comparison and the original short jump to the tint stage. */
extern void stop_completed_fade_up(void);
#pragma aux stop_completed_fade_up = \
    "cmp ebp,255" "jne unfinished" "mov [palette_fade_up],ebx" \
    "db 0ebh, 23h" /* marker-rel8 +1,+2 */ "unfinished:" modify exact [];

extern void palette_fade_changed_address(void);
extern void finish_completed_fade_down(void);
#pragma aux finish_completed_fade_down = "jmp near palette_fade_changed_address" modify exact [];
void update_palette_fade(void);
#pragma aux update_palette_fade modify exact [eax ebx ecx edx esi edi];

void update_palette_fade(void)
{
    long delta, value, numerator, divisor;

    begin_palette_fade();
    in_ebx(0);
    in_edi(0);
    in_esi(0);
    in_eax(0);
    in_ecx(totalclock - palette_fade_last_tick);
    in_edx(totalclock);
    load_fade_down();
    palette_fade_last_tick = edx_value();
    /* Display the current level before advancing either fade direction. */
    if (ebp_value()) {
        scale_fade_palette(fade_level);
        load_fade_level();
        if (!ebp_value()) {
            palette_fade_down = ebx_value();
            finish_completed_fade_down();
        }
        delta = in_eax(palette_fade_step * ecx_value());
        value = in_edx(ebp_value() - delta);
        fade_level = value;
        if (value >= 0)
            goto fade_changed;
        fade_level = ebx_value();
        goto fade_changed;
    }
    if (!palette_fade_up)
        goto check_tints;
    scale_fade_palette(fade_level);
    load_fade_level();
    stop_completed_fade_up();
    delta = in_eax(palette_fade_step * ecx_value());
    value = increase_eax_fade(delta);
    fade_level = value;
    if (value > 255)
        fade_level = 255;
fade_changed:
    in_eax(1);
check_tints:
    if (!eax_value() && palette_tint_a_ticks <= 0 && palette_tint_b_ticks <= 0)
        leave_without_tint();
    /* Convert remaining tint ticks to palette rows, capped at row three. */
    load_tint_a_timer();
    if (ebp_value() > 0) {
        value = in_eax(ebp_value() - ecx_value());
        palette_tint_a_ticks = value;
        if (value < 0) {
            in_ebx(0);
            palette_tint_a_ticks = ebx_value();
        }
        /* The original high dividend word was only this long's sign extension. */
        value = palette_tint_a_ticks / 10L;
        in_ebx(value);
        if (value >= 4)
            in_ebx(3);
    }
    load_tint_b_timer();
    if (ebp_value() > 0) {
        value = in_eax(ebp_value() - ecx_value());
        palette_tint_b_ticks = value;
        if (value < 0) {
            in_edi(0);
            palette_tint_b_ticks = edi_value();
        }
        /* Tint A remains live in EBX; use EDI for B's divisor and row. */
        numerator = in_eax(palette_tint_b_ticks);
        divisor = in_edi(10);
        value = numerator / divisor;
        in_edi(value);
        if (value >= 4)
            in_edi(3);
    }
    load_tint_c_timer();
    if (ebp_value() > 0) {
        value = in_eax(ebp_value() - ecx_value());
        palette_tint_c_ticks = value;
        if (value < 0) {
            in_ecx(0);
            palette_tint_c_ticks = ecx_value();
        }
        /* Both earlier rows remain live; ECX is free after the last timer. */
        numerator = in_eax(palette_tint_c_ticks);
        divisor = in_ecx(10);
        value = numerator / divisor;
        in_esi(value);
        if (value >= 4)
            in_esi(3);
    }
    /* The first active tint takes priority in VGA palette mode. */
    if (ebx_value() > 0 && qsetmode == 200) {
        wait_vertical_retrace(1);
        in_eax(in_eax(ebx_value()) * 4 - ebx_value());
        keep_tint_c_live(esi_value());
        in_esi((long)palette_tint_a);
palette_row:
        in_eax(eax_value() * 256);
        in_esi(esi_value() + eax_value());
        goto flush;
    }
    if (edi_value() > 0 && qsetmode == 200) {
        wait_vertical_retrace(1);
        in_eax(in_eax(edi_value()) * 4 - edi_value());
        keep_tint_c_live(esi_value());
        in_esi((long)palette_tint_b);
        goto palette_row;
    }
    if (esi_value() > 0 && qsetmode == 200) {
        wait_vertical_retrace(1);
        in_eax(in_eax(esi_value()) * 4 - esi_value());
        in_esi((long)palette_tint_c);
        goto palette_row;
    }
    leave_without_vga_palette();
    in_ecx(1);
    in_esi((long)brightness_palette);
    wait_vertical_retrace(ecx_value());
flush:
    write_vga_palette();
    palette_fade_shared_return();
}
