/* The original uses 32-bit wrapping addition for the color scales. */
extern unsigned long palette_red_scale, palette_blue_scale, palette_green_scale;

void adjust_palette_red(unsigned long delta)
{
    palette_red_scale += delta;
}

void adjust_palette_blue(unsigned long delta)
{
    palette_blue_scale += delta;
}

void adjust_palette_green(unsigned long delta)
{
    palette_green_scale += delta;
}

void reset_palette_color_scales(void)
{
    palette_blue_scale = palette_green_scale = palette_red_scale = 1;
}
