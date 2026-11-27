extern short bitmap_bits_per_pixel;
extern unsigned char bitmap_layout_flags;
short bitmap_row_bytes(short width)
{
    if (bitmap_layout_flags & 1)
        return ((width + 7) / 8) * bitmap_bits_per_pixel;
    return (width * bitmap_bits_per_pixel + 7) / 8;
}

extern long labs(long value);
#pragma intrinsic(labs)
/* The historical caller sign-extends the width into EAX. */
extern short measure_bitmap_row(int width);
#pragma aux measure_bitmap_row "bitmap_row_bytes_" modify exact [eax];

extern long long_in_eax(long value);
#pragma aux long_in_eax = "" parm [eax] value [eax] modify exact [];
extern long long_in_edx(long value);
#pragma aux long_in_edx = "" parm [edx] value [edx] modify exact [];
extern short x_in_si(short x);
#pragma aux x_in_si = "" parm [si] value [si] modify exact [];
extern short y_in_di(short y);
#pragma aux y_in_di = "" parm [di] value [di] modify exact [];
extern short width_in_bx(short width);
#pragma aux width_in_bx = "" parm [bx] value [bx] modify exact [];
extern short height_in_cx(short height);
#pragma aux height_in_cx = "" parm [cx] value [cx] modify exact [];

/* Include the last column after the height difference is in EAX. */
extern short include_last_column(short width, long rise);
#pragma aux include_last_column = "inc ebx" parm [bx] [eax] value [bx] modify exact [ebx];

long bitmap_rectangle_size(short x1, short y1, short x2, short y2)
{
    short columns, rows, row_bytes;
    long rise;
    int width;
    x1 = x_in_si(x1);
    y1 = y_in_di(y1);
    columns = width_in_bx(labs(long_in_eax(x2) - x1));
    rise = (long)y2 - y1;
    columns = include_last_column(columns, rise);
    rows = height_in_cx(labs(long_in_eax(rise))) + 1;
    width = columns;
    row_bytes = measure_bitmap_row(width);
    return rows * long_in_edx(row_bytes) + 6;
}
