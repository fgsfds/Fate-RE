extern int selected_cd_track;
extern short active_cd_track, cd_playback_pending;
extern int play_cd_track(unsigned char);
#pragma aux play_cd_track modify exact [eax];

extern void stop_cd_driver_playback(void);
#pragma aux stop_cd_driver_playback modify exact [eax edx];
extern void resume_cd_driver_playback(void);
#pragma aux resume_cd_driver_playback modify exact [eax];
extern int format_cd_status(char *, const char *, ...);
#pragma aux format_cd_status "sprintf_" parm caller [] modify exact [eax];
extern char cd_status_buffer[];
extern const char cd_paused_message[], cd_resumed_message[];

/* Keep the two state assignments in their original Watcom registers. */
extern unsigned paused_flag(unsigned);
#pragma aux paused_flag = parm [edx] value [edx] modify exact [];
extern unsigned resume_flag(unsigned);
#pragma aux resume_flag = parm [edi] value [edi] modify exact [];

void toggle_cd_pause(void)
{
    short track = active_cd_track;
    if (track) {
        stop_cd_driver_playback();
        {
            unsigned paused;
            int idle;
            /* Preserve the original ordering of the state stores and argument setup. */
            format_cd_status((paused = paused_flag(1),
                              idle = 0,
                              active_cd_track = idle,
                              cd_playback_pending = paused,
                              cd_status_buffer),
                             cd_paused_message);
        }
    } else if (cd_playback_pending) {
        unsigned playing = resume_flag(1);
        cd_playback_pending = track;
        active_cd_track = playing;
        resume_cd_driver_playback();
        format_cd_status(cd_status_buffer, cd_resumed_message);
    } else {
        play_cd_track((unsigned char)selected_cd_track);
        cd_playback_pending = track;
        active_cd_track = (short)selected_cd_track;
    }
}
