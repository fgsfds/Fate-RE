extern short audio_listener_index;
extern long audio_listener_x[], audio_listener_y[];
extern long labs(long);
#pragma aux labs modify exact [eax];
unsigned long audio_source_attenuation(long x, long y)
{
    long distance = labs(audio_listener_x[audio_listener_index] - x)
                  + labs(audio_listener_y[audio_listener_index] - y);
    short gain;
    if (distance < 1536)
        gain = 0x7fff;
    else if (distance > 8674)
        gain = 0x1f00;
    else
        gain = 39000 - 4 * distance;
    return ((unsigned long)gain << 16) | (unsigned long)gain;
}
