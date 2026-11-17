extern volatile short viewport_origin_x, viewport_origin_y;
extern short graphics_available(void);
#pragma aux graphics_available modify exact [eax];
extern long bitmap_rectangle_size(short, short, short, short);
#pragma aux bitmap_rectangle_size modify exact [eax edx ebx ecx];

long viewport_bitmap_size(short left, short top, short right, short bottom)
{
    if (graphics_available()) {
        bottom += viewport_origin_y;
        right += viewport_origin_x;
        top += viewport_origin_y;
        left += viewport_origin_x;
        return bitmap_rectangle_size(left, top, right, bottom);
    }
    return 0;
}
