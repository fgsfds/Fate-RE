enum { FULL_BRIGHTNESS = 255 };

extern long fade_level, fade_in_active, fade_out_active, fade_speed;
extern long dispatch_play;
extern void update_palette_fade(void);
#pragma aux update_palette_fade modify exact [eax];

void start_fade_out(long speed)
{
    if (fade_level > 0) {
        fade_speed = speed;
        fade_out_active = 1;
        fade_in_active = 0;
    }
    if (dispatch_play)
        update_palette_fade();
}

void start_fade_in(long speed)
{
    if (fade_level < FULL_BRIGHTNESS) {
        fade_speed = speed;
        fade_in_active = 1;
        fade_out_active = 0;
    }
    if (dispatch_play)
        update_palette_fade();
}
