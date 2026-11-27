extern short text_window_top, text_window_bottom, text_window_left, text_window_right;
extern short text_rows, text_columns;
extern void initialize_graphics_once(void);
#pragma aux initialize_graphics_once modify exact [eax];
extern void set_text_home(short column, short row);
#pragma aux set_text_home "set_text_position_" parm [edx] [eax] modify exact [eax edx];

void get_text_window(short *top, short *left, short *bottom, short *right)
{
    initialize_graphics_once();
    *top = text_window_top + 1;
    *bottom = text_window_bottom + 1;
    *left = text_window_left + 1;
    *right = text_window_right + 1;
}

void set_text_window(short top, short left, short bottom, short right)
{
    short temp;
    initialize_graphics_once();
    if (top > bottom) {
        temp = top;
        top = bottom;
        bottom = temp;
    }
    if (left > right) {
        temp = left;
        left = right;
        right = temp;
    }
    --top;
    --bottom;
    --left;
    --right;
    if (top < 0)
        top = 0;
    if (left < 0)
        left = 0;
    if (bottom >= text_rows)
        bottom = text_rows - 1;
    if (right >= text_columns)
        right = text_columns - 1;
    text_window_top = top;
    text_window_bottom = bottom;
    text_window_left = left;
    text_window_right = right;
    set_text_home(1, 1);
}

extern void hide_graphics_cursor(void);
#pragma aux hide_graphics_cursor modify exact [eax];
/* Match the parameter setup order of the Watcom text writer call. */
#pragma aux write_text_window_mode_first "write_text_window_" parm [ebx] [edx] [eax] modify exact [eax edx ebx];
extern void write_text_window_mode_first(short translate_controls, short length, const char *text);
extern void restore_cursor_if_enabled(void);
#pragma aux restore_cursor_if_enabled modify exact [eax];

void output_counted_text(const char *text, short length)
{
    initialize_graphics_once();
    hide_graphics_cursor();
    write_text_window_mode_first(0, length, text);
    restore_cursor_if_enabled();
}

extern short cursor_shape;

short get_text_cursor_shape(void)
{
    initialize_graphics_once();
    return cursor_shape;
}

extern short text_cursor_row, text_cursor_column;

struct text_position {
    short row, column;
};

struct text_position get_text_position(void)
{
    struct text_position position;
    initialize_graphics_once();
    position.row = text_cursor_row - text_window_top + 1;
    position.column = text_cursor_column - text_window_left + 1;
    return position;
}

/* Match the blink-bit transfer from EAX to EDX in the text-mode path. */
extern int blink_in_edx(int blink);
#pragma aux blink_in_edx = "" parm [edx] value [edx] modify exact [];
extern int blink_in_eax(int blink);
#pragma aux blink_in_eax = "" parm [eax] value [eax] modify exact [];
extern unsigned char graphics_active, text_attribute;

short get_text_color(void)
{
    int blink;
    int color;
    if (graphics_active)
        return text_attribute;
    blink = blink_in_edx(blink_in_eax(text_attribute & 0x80));
    color = text_attribute & 0xf;
    return (blink >> 3) + color;
}

extern short palette_size;
extern short read_text_color(void);
#pragma aux read_text_color "get_text_color_" modify exact [eax];

short set_text_color(short color)
{
    short previous = read_text_color();
    if (graphics_active) {
        unsigned char mask;
        hide_graphics_cursor();
        mask = ((unsigned char)palette_size - 1) | 0x80;
        text_attribute = (unsigned char)color & mask;
        restore_cursor_if_enabled();
    } else {
        unsigned char blink = (unsigned char)color & 0x10;
        unsigned char foreground = (unsigned char)color & 0xf;
        blink <<= 3;
        text_attribute &= 0x70;
        text_attribute |= blink + foreground;
    }
    return previous;
}

extern short active_text_page;
extern struct text_position read_text_position(void);
#pragma aux read_text_position "get_text_position_" modify exact [eax];
/* The BIOS cursor service uses BX for the page and DX for the position. */
extern void set_bios_cursor(int service, short page, int reserved, short position);
#pragma aux set_bios_cursor = "push bp" "int 10h" "pop bp" parm [eax] [bx] [ecx] [dx] modify exact [eax ebx ecx edx];

struct text_position set_text_position(short row, short column)
{
    struct text_position previous;
    hide_graphics_cursor();
    previous = read_text_position();
    row += text_window_top - 1;
    column += text_window_left - 1;
    if (row < text_window_top)
        row = text_window_top;
    if (row > text_window_bottom)
        row = text_window_bottom;
    if (column < text_window_left)
        column = text_window_left;
    if (column > text_window_right)
        column = text_window_right;
    text_cursor_row = row;
    text_cursor_column = column;
    set_bios_cursor(0x200, (unsigned)active_text_page << 8, 0, ((unsigned)row << 8) + column);
    restore_cursor_if_enabled();
    return previous;
}

extern void clear_graphics_display(short mode);
#pragma aux clear_graphics_display modify exact [eax];
extern void clear_text_region(int top, int left, int bottom, int right);
#pragma aux clear_text_region modify exact [eax ebx ecx edx];

void clear_screen(short mode)
{
    initialize_graphics_once();
    hide_graphics_cursor();
    if (graphics_active) {
        clear_graphics_display(mode);
    } else {
        switch (mode) {
        case 1:
            goto done;
        case 2:
            clear_text_region(text_window_top, text_window_left, text_window_bottom, text_window_right);
            break;
        default:
            clear_text_region(0, 0, (short)(text_rows - 1), (short)(text_columns - 1));
            break;
        }
        set_text_home(1, 1);
    }
done:
    restore_cursor_if_enabled();
}

/* Hold the scroll direction in CX while computing the text-window height. */
extern short scroll_direction_in_cx(short direction);
#pragma aux scroll_direction_in_cx = "" parm [cx] value [cx] modify exact [];
extern short graphics_error;
extern void scroll_text_window(short direction, short rows);
#pragma aux scroll_text_window modify exact [eax edx];

void scroll_text_by_rows(short rows)
{
    short direction;
    if (!rows) {
        graphics_error = -4;
        return;
    }
    initialize_graphics_once();
    hide_graphics_cursor();
    if (rows < 0) {
        direction = 2;
        rows = -rows;
    } else {
        direction = 1;
    }
    if (rows >= text_window_bottom - text_window_top + 1)
        rows = 0;
    scroll_text_window(scroll_direction_in_cx(direction), rows);
    restore_cursor_if_enabled();
}

/* BIOS service 01h reads the cursor shape from CX. */
extern void set_bios_cursor_shape(short shape, int service, int reserved_dx, int reserved_bx);
#pragma aux set_bios_cursor_shape = "push bp" "int 10h" "pop bp" parm [cx] [eax] [edx] [ebx] modify exact [eax ebx ecx edx];

short set_text_cursor_shape(short shape)
{
    short previous;
    if (graphics_active) {
        graphics_error = -3;
        return -1;
    }
    previous = cursor_shape;
    cursor_shape = shape;
    set_bios_cursor_shape(shape, 0x100, 0, 0);
    return previous;
}

extern short clip_left, clip_top, clip_right, clip_bottom, pixel_width, pixel_height;
extern void clear_graphics_region(short, short, short, short);
#pragma aux clear_graphics_region modify exact [eax ebx ecx edx];
/* Clear-region arguments consume the sign-extended top and left in EDX and EAX. */
extern int text_region_left(short top, short left);
#pragma aux text_region_left = "movsx edx,ax" "movsx eax,si" parm [ax] [si] value [eax] modify exact [edx eax];
extern int text_region_top(void);
#pragma aux text_region_top = value [edx] modify exact [];
extern void clear_graphics_rectangle(int top, int left, short right, short bottom);
#pragma aux clear_graphics_rectangle "clear_graphics_region_" parm [edx] [eax] [ebx] [ecx] modify exact [eax ebx ecx edx];

void clear_graphics_display(short mode)
{
    short cell_width, cell_height;
    switch (mode) {
    case 1:
        clear_graphics_region(clip_left, clip_top, clip_right, clip_bottom);
        return;
    case 2:
        cell_width = pixel_width / text_columns;
        cell_height = pixel_height / text_rows;
        /* Watcom prepares the top while preparing the left coordinate. */
        clear_graphics_rectangle(text_region_top(),
                                 text_region_left(text_window_top * cell_height,
                                                  text_window_left * cell_width),
                                 (text_window_right + 1) * cell_width - 1,
                                 (text_window_bottom + 1) * cell_height - 1);
        break;
    default:
        clear_graphics_rectangle(0, 0, pixel_width - 1, pixel_height - 1);
        break;
    }
    set_text_home(1, 1);
}
