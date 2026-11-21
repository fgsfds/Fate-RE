extern short pixel_height, pixel_width, text_rows;
extern void set_absolute_graphics_pair(short, short);
#pragma aux set_absolute_graphics_pair modify exact [eax edx];
extern void set_nonzero_graphics_pair(short, short);
#pragma aux set_nonzero_graphics_pair modify exact [eax edx];
extern void set_graphics_word_a5(short);
#pragma aux set_graphics_word_a5 modify exact [eax edx];
/* Prepare EDX for the following pair setter before calling the word setter. */
extern void set_graphics_word_ab_with_edx(short prepared_pair_value, short value);
#pragma aux set_graphics_word_ab_with_edx "set_graphics_word_ab_" parm [edx] [eax] modify exact [eax];
extern void set_graphics_pair_ad(short, short);
#pragma aux set_graphics_pair_ad modify exact [eax edx];

void reset_graphics_aspect_settings(void)
{
    long height = pixel_height;
    short x = (height * 3) / (text_rows * 2);
    short y = ((x * pixel_width) * 15) / (height * 32);
    set_absolute_graphics_pair(x, y);
    set_nonzero_graphics_pair(1, 0);
    set_graphics_word_a5(0);
    set_graphics_word_ab_with_edx(0, 0);
    set_graphics_pair_ad(0, 0);
}
