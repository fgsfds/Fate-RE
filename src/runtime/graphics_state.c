extern short graphics_word_a7, graphics_word_a9;
extern short graphics_word_a1, graphics_word_a3, graphics_error;
extern short graphics_word_a5, graphics_word_ab, graphics_word_ad, graphics_word_af;

extern long labs(long);
#pragma intrinsic(labs)

void set_absolute_graphics_pair(short a, short b)
{
    graphics_word_a7 = labs((long)a);
    graphics_word_a9 = labs((long)b);
}

void set_nonzero_graphics_pair(short a, short b)
{
    if (a || b) {
        graphics_word_a1 = a;
        graphics_word_a3 = b;
    } else {
        graphics_error = -4;
    }
}

void set_graphics_word_a5(short value)
{
    graphics_word_a5 = value;
}

void set_graphics_word_ab(short value)
{
    graphics_word_ab = value;
}

void set_graphics_pair_ad(short a, short b)
{
    graphics_word_ad = a;
    graphics_word_af = b;
}

extern short drawing_color;
extern short graphics_available(void);
#pragma aux graphics_available modify exact [eax];
extern short replace_drawing_color(long);
#pragma aux replace_drawing_color modify exact [eax];

short get_drawing_color(void)
{
    return drawing_color;
}

short set_drawing_color(short color)
{
    if (graphics_available())
        return replace_drawing_color(color);
    return -1;
}

extern unsigned short palette_size;
short replace_drawing_color(long color)
{
    short previous = drawing_color;
    drawing_color = color & (palette_size - 1);
    return previous;
}

extern long background_color;

long get_background_color(void)
{
    return background_color;
}
