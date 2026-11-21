enum { PALETTE_BYTES = 256 * 3, FULL_BRIGHTNESS = 255 };

extern unsigned char saved_palette[PALETTE_BYTES];
extern unsigned char brightness_palette[PALETTE_BYTES];
extern long fade_level, fade_last_tick, totalclock;
extern long fade_in_active, fade_out_active, fade_speed;

extern void *memmove(void *destination, const void *source, unsigned count);
extern void build_palette_fade_tables(void);

void capture_fade_palette(void)
{
    memmove(saved_palette, brightness_palette, PALETTE_BYTES);
    build_palette_fade_tables();
    fade_last_tick = totalclock;
}

void scale_fade_palette(long level)
{
    int i = 0;
    do {
        /* Watcom keeps the low 32 bits of the product, then shifts it right. */
        long scaled = (long)(saved_palette[i] * (unsigned long)level);
        ++i;
        brightness_palette[i - 1] = (unsigned char)(scaled >> 8);
    } while (i < (int)PALETTE_BYTES);
}

int palette_is_dimmed(void)
{
    return fade_level != FULL_BRIGHTNESS;
}

void reset_palette_fade(void)
{
    fade_speed = fade_in_active = fade_out_active = 0;
}
