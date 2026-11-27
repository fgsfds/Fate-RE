extern long totalclock;
extern unsigned long menu_animation_clock;
extern long menu_tile_frame, menu_color_frame;
extern long dispatch_period(long);
#pragma aux dispatch_period modify exact [eax];

/* Keep the original Watcom register assignments for frame and clock updates. */
extern unsigned long reset_tile_frame(unsigned long);
#pragma aux reset_tile_frame = parm [esi] value [esi] modify exact [];
extern long final_menu_clock(long);
#pragma aux final_menu_clock = parm [edx] value [edx] modify exact [];

/* Preserve EDI across the color reset so Watcom allocates the zero in EBP. */
extern long keep_incoming_edi(void);
#pragma aux keep_incoming_edi = value [edi] modify exact [];
extern void keep_edi_live(long);
#pragma aux keep_edi_live = parm [edi] modify exact [];

int advance_menu_animation(void)
{
    int changed;
    if (totalclock > (long)menu_animation_clock) {
        long tile = menu_tile_frame + 0x825;
        ++menu_color_frame;
        ++menu_tile_frame;
        if (tile >= 0x827)
            menu_tile_frame = reset_tile_frame(0);
        if (menu_color_frame >= 4) {
            long saved_edi = keep_incoming_edi();
            menu_color_frame = 0;
            keep_edi_live(saved_edi);
        }
        menu_animation_clock = dispatch_period(16) + final_menu_clock(totalclock);
        changed = 1;
    } else {
        changed = 0;
    }
    return changed;
}
