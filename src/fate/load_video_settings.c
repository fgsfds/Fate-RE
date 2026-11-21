#include "dosio.h"

extern const char video_settings_filename[];
extern long text_mode, text_width, text_height;
extern long video_settings_record[3];
extern long video_setup_pending;
extern void apply_video_mode(void);
#pragma aux apply_video_mode modify exact [eax];

/* Keep the descriptor test in its incoming register with no emitted code. */
extern unsigned keep_descriptor(unsigned);
#pragma aux keep_descriptor = "" parm [eax] value [eax] modify exact [];

int load_video_settings(int descriptor, long seek_status);
#pragma aux load_video_settings parm [eax] [edx] modify exact [eax];

int load_video_settings(int descriptor, long seek_status)
{
    int opened_here = 0;

    if (!keep_descriptor(descriptor)) {
        opened_here = 1;
        descriptor = dos_open(video_settings_filename, 0x202);
        if (descriptor == -1) {
            video_setup_pending = opened_here;
            goto finish;
        }
        seek_status = lseek(descriptor, 0, 0);
    }
    if (seek_status == -1) {
        close(descriptor);
        video_setup_pending = 1;
        goto finish;
    }
    if (read(descriptor, video_settings_record, sizeof(video_settings_record))
            != sizeof(video_settings_record)) {
        close(descriptor);
        video_setup_pending = 1;
        goto finish;
    }
    if (opened_here)
        close(descriptor);
    text_width = video_settings_record[0];
    text_height = video_settings_record[1];
    text_mode = video_settings_record[2];

finish:
    if (video_setup_pending)
        apply_video_mode();
    return 1;
}
