extern short player_sector, player_angle;
extern long player_x, player_y, player_z, player_horizon;
extern long presentation_height, presentation_width;
extern volatile long totalclock;

extern long dispatch_ticks(long);
#pragma aux dispatch_ticks modify exact [eax];
extern void drawrooms(long, long, long, short, long, short);
#pragma aux drawrooms modify exact [eax ebx ecx edx];
extern void drawmasks(void), nextpage(void), presentation_reset(void);
#pragma aux drawmasks modify exact [eax];
#pragma aux nextpage modify exact [eax];
#pragma aux presentation_reset modify exact [eax];
extern int presentation_input(void);
#pragma aux presentation_input modify exact [eax];
extern void rotatesprite(long, long, long, short, short, signed char, unsigned char, unsigned char, long, long, long, long);
#pragma aux rotatesprite modify exact [eax ebx ecx edx];
/* This existing epilogue restores the registers saved by the intro frame. */
extern void restore_saved_registers(void);
#pragma aux restore_saved_registers aborts modify exact [];

void draw_intro_screen(void)
{
    long zoom = 256;
    long previous_tick = totalclock;
    long deadline = (long)((unsigned long)previous_tick + (unsigned long)dispatch_ticks(4));

    while (deadline > totalclock) {
        if (zoom < 65536) {
            zoom = (long)((unsigned long)zoom + (((unsigned long)totalclock - (unsigned long)previous_tick) << 8));
            previous_tick = totalclock;
            if (zoom > 65536)
                zoom = 65536;
        }
        drawrooms(player_x, player_y, player_z, player_angle, player_horizon, player_sector);
        drawmasks();
        rotatesprite(160 << 16, 100 << 16, zoom, 0, 0x83a, 0, 0, 2,
                     0, 0, presentation_width - 1, presentation_height - 1);
        nextpage();
    }
    presentation_reset();
    while (!presentation_input())
        continue;
    restore_saved_registers();
}
