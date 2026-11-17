#include "dosio.h"

extern const char video_settings_filename[];
extern long text_mode, text_width, text_height;
extern long video_settings_record[3];

int save_video_settings(int descriptor, long seek_status);
#pragma aux save_video_settings parm [eax] [edx] modify exact [eax];

int save_video_settings(int descriptor, long seek_status)
{
    int opened_here = 0;

    video_settings_record[0] = text_width;
    video_settings_record[1] = text_height;
    video_settings_record[2] = text_mode;
    if (descriptor == 0) {
        opened_here = 1;
        descriptor = dos_open(video_settings_filename, 0x222, 0x180);
        if (descriptor == -1)
            return descriptor;
        seek_status = lseek(descriptor, 0, 0);
    }
    if (seek_status == -1) {
        close(descriptor);
        return seek_status;
    }
    if (write(descriptor, video_settings_record, sizeof(video_settings_record)) != sizeof(video_settings_record)) {
        close(descriptor);
        return -1;
    }
    if (opened_here) {
        close(descriptor);
        flushall();
    }
    return 1;
}
