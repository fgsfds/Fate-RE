extern long audio_level_a, audio_level_b;

/* The setters keep the original store and clamp order. */
long get_audio_level_a(void)
{
    return audio_level_a;
}

void set_audio_level_a(long level)
{
    audio_level_a = level;
    if (level > 16)
        audio_level_a = 16;
    if (audio_level_a < 0)
        audio_level_a = 0;
}

long get_audio_level_b(void)
{
    return audio_level_b;
}

void set_audio_level_b(long level)
{
    audio_level_b = level;
    if (level > 16)
        audio_level_b = 16;
    if (audio_level_b < 0)
        audio_level_b = 0;
}
