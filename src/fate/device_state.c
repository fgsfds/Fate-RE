extern void stop_cd_driver_playback(void);
extern int request_cd_disk_info(int);
extern void read_cd_track_info(int);
extern void read_cd_track_start(int, unsigned char);
extern short cd_device_handle, first_cd_track, last_cd_track;
extern int selected_cd_track;
extern short active_cd_track, cd_playback_pending;
extern const char cd_stopped_message[], cd_reset_message[];
extern char cd_status_buffer[];
extern int format_cd_status(char *, const char *, ...);
#pragma aux format_cd_status "sprintf_" parm caller [] modify exact [eax];
extern int close(int);

void stop_cd_music(void)
{
    stop_cd_driver_playback();
    format_cd_status(cd_status_buffer, cd_stopped_message);
}

int shutdown_cd_audio(void)
{
    stop_cd_driver_playback();
    request_cd_disk_info(cd_device_handle);
    return close(cd_device_handle);
}

void reset_cd_disc_state(void)
{
    int track;
    request_cd_disk_info(cd_device_handle);
    read_cd_track_info(cd_device_handle);
    for (track = first_cd_track; track <= last_cd_track; ++track)
        read_cd_track_start(cd_device_handle, track);
    selected_cd_track = first_cd_track;
    cd_playback_pending = active_cd_track = 0;
    format_cd_status(cd_status_buffer, cd_reset_message);
}

extern int text_archive_handle, text_archive_open;
int close_text_archive(void)
{
    if (text_archive_handle != -1)
        close(text_archive_handle);
    text_archive_open = 0;
    return 1;
}

extern volatile unsigned long totalclock;
extern int outp(unsigned, unsigned);
void advance_timer_clock(void)
{
    totalclock++;
    outp(0x20, 0x20);
}
