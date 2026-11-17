typedef struct { short x, y; } PixelPoint;
extern short viewport_origin_x, viewport_origin_y;
extern short graphics_available(void);
#pragma aux graphics_available modify exact [eax];
extern long map_first_coordinate(double);
#pragma aux map_first_coordinate modify exact [eax edx];
extern short map_second_coordinate(double);
#pragma aux map_second_coordinate modify exact [eax edx];
extern PixelPoint map_coordinate_pair(double, double);
#pragma aux map_coordinate_pair value struct [eax] modify exact [eax edx ebx ecx];

PixelPoint map_coordinate_pair(double x, double y)
{
    PixelPoint point;
    short second;
    if (graphics_available()) {
        point.x = (short)map_first_coordinate(x) - viewport_origin_x;
        second = map_second_coordinate(y) - viewport_origin_y;
    } else {
        point.x = second = 0;
    }
    point.y = second;
    return point;
}

extern PixelPoint map_coordinate_pair_reversed(double y, double x);
#pragma aux map_coordinate_pair_reversed "map_coordinate_pair_" parm [ebx ecx] [eax edx] value struct [eax] modify exact [eax edx ebx ecx];
extern PixelPoint map_pair_stack(double, double);
#pragma aux map_pair_stack parm routine [] value struct [eax] modify exact [eax];
PixelPoint map_pair_stack(double x, double y)
{
    return map_coordinate_pair_reversed(y, x);
}

typedef union {
    struct { double x, y; } point;
    struct { unsigned long x_low, x_high, y_low, y_high; } words;
} WorldPoint;
/* Watcom passes the two doubles as four words in these registers. */
extern PixelPoint map_pair_words(unsigned long x_high, unsigned long y_low,
                                 unsigned long x_low, unsigned long y_high);
#pragma aux map_pair_words "map_coordinate_pair_" parm [edx] [ebx] [eax] [ecx] value struct [eax] modify exact [eax edx ebx ecx];
extern PixelPoint map_pair_from_pointer(const WorldPoint *source);
#pragma aux map_pair_from_pointer value struct [eax] modify exact [eax];

PixelPoint map_pair_from_pointer(const WorldPoint *source)
{
    unsigned long y_low = source->words.y_low;
    return map_pair_words(source->words.x_high, y_low, source->words.x_low, source->words.y_high);
}
