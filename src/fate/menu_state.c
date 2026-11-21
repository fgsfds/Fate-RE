extern unsigned long audio_flag_a, audio_flag_b;
extern unsigned long menu_animation_clock;
extern const char *video_mode_names[];

int get_audio_flag_a(void)
{
    return audio_flag_a == 1;
}

int get_audio_flag_b(void)
{
    return audio_flag_b == 1;
}

void reset_menu_animation_clock(void)
{
    menu_animation_clock = 0;
}

const char *video_mode_name(int mode)
{
    return video_mode_names[mode];
}
