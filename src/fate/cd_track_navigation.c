extern int selected_cd_track;
extern short first_cd_track, last_cd_track, active_cd_track, cd_playback_pending;
extern int play_cd_track(unsigned char);
#pragma aux play_cd_track modify exact [eax];

void next_cd_track(void)
{
    if (++selected_cd_track > last_cd_track)
        selected_cd_track = first_cd_track;
    play_cd_track((unsigned char)selected_cd_track);
    cd_playback_pending = 0;
    active_cd_track = (short)selected_cd_track;
}

void previous_cd_track(void)
{
    if (--selected_cd_track < first_cd_track)
        selected_cd_track = last_cd_track;
    play_cd_track((unsigned char)selected_cd_track);
    cd_playback_pending = 0;
    active_cd_track = (short)selected_cd_track;
}
