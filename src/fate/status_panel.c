/* The matching 608-byte tail and initial top store supply production C
 * phases. The entry setup comes from status_panel_entry.c. */
/* Draw the fixed status panel and its numeric fields and optional icons. */
extern const char number_format[];
extern short show_left_icon, show_middle_icon, show_right_icon;
extern short status_left_value, status_left_tenths, status_right_index;
extern short status_right_values[];
extern long status_right_tenths, panel_top;
extern long window_bottom, window_top, window_right, window_left;

extern int format_string(char *, const char *, ...);
#pragma aux format_string parm caller [] value [eax] modify exact [eax];
extern void draw_number_text(long, long, long, const char *, long);
#pragma aux draw_number_text parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void draw_tile(long, long, long, long, long, long, long, long, long, long, long, long);
#pragma aux draw_tile parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];

extern long initial_panel_top(long);
#pragma aux initial_panel_top = "" parm nomemory [edx] value [edx] modify exact [];

#define PANEL_Y(extra) ((long)(((unsigned long)panel_top + (extra)) << 16))
#define CLIP window_left, window_top, window_right, window_bottom
#define NUMBER(input, style, x, y) do { \
    value = (input); \
    if (value < 0) value = 0; \
    format_string(text, number_format, value); \
    draw_number_text(x, (long)((unsigned long)panel_top + (y)), style, text, 0); \
} while (0)

void draw_status_panel(void);
#pragma aux draw_status_panel modify exact [eax];
void draw_status_panel(void)
{
    /* Normal status fields have at most three digits, plus the terminator. */
    char text[4];
    long value, first_top;

    first_top = initial_panel_top(4);
    draw_tile(0x50000L, 0x40000L, 0x10000L, 0,
              (panel_top = first_top, 0x828), 0, 0, 0x82, CLIP);
    draw_tile(0x1060000L, PANEL_Y(0), 0x10000L, 0,
              0x82c, 0, 0, 0x82, CLIP);
    NUMBER(status_left_value, -1, 27, 13);
    if (status_right_index >= 0)
        value = status_right_values[status_right_index];
    else
        value = 0;
    NUMBER(value, 1, 27, 31);
    NUMBER(status_left_tenths / 10, -1, 284, 13);
    NUMBER(status_right_tenths / 10, 1, 284, 31);

    if (show_left_icon != 0)
        draw_tile(0x90000L, PANEL_Y(2), 0x10000L, 0,
                  0x82a, 0, 0, 0x82, CLIP);
    if (show_middle_icon != 0)
        draw_tile(0x1a0000L, PANEL_Y(2), 0x10000L, 0,
                  0x829, 0, 0, 0x82, CLIP);
    if (show_right_icon != 0)
        draw_tile(0x2a0000L, PANEL_Y(2), 0x10000L, 0,
                  0x82b, 0, 0, 0x82, CLIP);
}
