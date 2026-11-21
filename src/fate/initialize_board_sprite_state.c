extern short status_minimum_width;
extern long presentation_width, presentation_height;

extern void initialize_video_mode(void);
#pragma aux initialize_video_mode modify exact [eax];
extern int write_palette_port(unsigned, unsigned);
#pragma aux write_palette_port "outp_" modify exact [eax edx];
extern void setview(long, long, long, long);
#pragma aux setview modify exact [eax edx ebx ecx];
extern void draw_view_border(long, long, short, signed char, long, long, long, long, unsigned char);
#pragma aux draw_view_border parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];

/* These identities preserve Watcom register allocation without emitting code. */
extern long keep_view_minimum(long);
#pragma aux keep_view_minimum = "" parm [eax] value [eax] modify exact [];
extern long keep_view_right(long);
#pragma aux keep_view_right = "" parm [ebx] value [ebx] modify exact [];
extern long keep_height_product(long);
#pragma aux keep_height_product = "" parm [edx] value [edx] modify exact [];
extern long keep_view_quotient(long);
#pragma aux keep_view_quotient = "" parm [eax] value [eax] modify exact [];
extern long keep_divisor(long);
#pragma aux keep_divisor = "" parm [ecx] value [ecx] modify exact [];
extern long keep_full_right(long);
#pragma aux keep_full_right = "" parm [eax] value [eax] modify exact [];
extern int keep_view_start(int);
#pragma aux keep_view_start = "" parm [esi] value [esi] modify exact [];
extern long keep_screen_width(long);
#pragma aux keep_screen_width = "" parm [edx] value [edx] modify exact [];
extern long keep_border_width(long);
#pragma aux keep_border_width = "" parm [esi] value [esi] modify exact [];
extern long keep_view_height(long);
#pragma aux keep_view_height = "" parm [ecx] value [ecx] modify exact [];

void initialize_board_sprite_state(void)
{
    long width, left, right, top, bottom, viewport_width;

    initialize_video_mode();

    /* Set VGA palette entry 255 to black. */
    write_palette_port(0x3c8, 0xff);
    write_palette_port(0x3c9, 0);
    write_palette_port(0x3c9, 0);
    write_palette_port(0x3c9, 0);

    viewport_width = keep_view_minimum(status_minimum_width);
    width = keep_screen_width(presentation_width);
    if (viewport_width > width) {
        right = width - 1;
        bottom = presentation_height - 1;
        setview(0, 0, right, bottom);
    } else {
        long height, half_height, divisor;

        left = keep_view_start(width);
        height = keep_height_product(presentation_height * viewport_width);
        left -= viewport_width;
        left >>= 1;
        divisor = keep_divisor(presentation_width);
        right = keep_view_right(left + viewport_width);
        height = keep_view_quotient(height) / divisor;
        half_height = keep_view_height(height);
        top = keep_height_product(presentation_height);
        half_height >>= 1;
        top >>= 1;
        top -= half_height;
        height += top;
        bottom = height - 1;
        --right;
        setview(left, top, right, bottom);
    }

    viewport_width = keep_view_minimum(status_minimum_width);
    width = keep_border_width(presentation_width);
    if (viewport_width < width)
        draw_view_border(0, 0, 0x48, 8, 0, 0, keep_full_right(width - 1),
                         presentation_height - 1, 0);
}
