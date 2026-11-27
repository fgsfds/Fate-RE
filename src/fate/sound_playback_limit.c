int playback_sound_limit(int);
#pragma aux playback_sound_limit parm [edi] value [eax] modify exact [eax gs];
int playback_sound_limit(int sound)
{
    return sound > 163;
}
