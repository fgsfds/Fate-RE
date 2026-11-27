extern void rotatesprite(long, long, long, short, short, signed char, unsigned char,
                         unsigned char, long, long, long, long);
#pragma aux rotatesprite modify exact [eax ebx ecx edx];

extern short tilesizx[], tilesizy[];
void draw_view_border(long, long, short, signed char, long, long, long, long, unsigned char);
#pragma aux draw_view_border parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
void draw_view_border(long unused_x, long unused_y, short tile, signed char shade,
                      long left, long top, long right, long bottom, unsigned char palette)
{
    long x, y, width, height;
    volatile long limit_y, limit_x, first_y;
    (void)unused_x;
    (void)unused_y;
    width = tilesizx[tile];
    x = left / width;
    limit_x = right / width;
    height = tilesizy[tile];
    first_y = top / height;
    limit_y = bottom / height;
    for (; x <= limit_x; ++x) {
        for (y = first_y; y <= limit_y;) {
            rotatesprite(x * width * 65536L, y++ * height * 65536L, 65536, 0, tile, shade, palette, 0xd8,
                         left, top, right, bottom);
        }
    }
}
