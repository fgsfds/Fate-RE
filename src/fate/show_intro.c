extern long status_right_tenths, presentation_height, presentation_width;
extern unsigned char menu_redraw_pending;
extern volatile long totalclock;
extern void presentation_reset(void);
#pragma aux presentation_reset modify exact [eax];
extern int presentation_input(void);
#pragma aux presentation_input modify exact [eax];
extern void draw_intro_screen(void);
#pragma aux draw_intro_screen modify exact [eax];
extern void draw_animated_intro(void);
#pragma aux draw_animated_intro modify exact [eax];
extern void nextpage(void);
#pragma aux nextpage modify exact [eax];
extern long dispatch_ticks(long);
#pragma aux dispatch_ticks modify exact [eax];
extern void rotatesprite(long, long, long, short, short, signed char, unsigned char,
                         unsigned char, long, long, long, long);
#pragma aux rotatesprite modify exact [eax ebx ecx edx];

void show_intro(void)
{
    long deadline, start;
    if (status_right_tenths <= 0) {
        presentation_reset();
        draw_animated_intro();
    } else if (menu_redraw_pending) {
        presentation_reset();
        draw_intro_screen();
    }
    presentation_reset();
    rotatesprite(0, 0, 65536, 0, 0x838, 0, 0, 0x92,
                 0, 0, presentation_width-1, presentation_height-1);
    nextpage();
    start = totalclock;
    deadline = dispatch_ticks(1) + start;
    while (deadline > totalclock) { }
    while (!presentation_input()) { }
}
