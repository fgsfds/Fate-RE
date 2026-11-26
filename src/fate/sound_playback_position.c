typedef void (*SampleCallback)(void);
typedef struct {
    unsigned char prior_fields[0x2c];
    long volume;
    unsigned char mixer_fields[0x14];
    long pan;
    unsigned char callback_fields[0x18];
    SampleCallback on_done;
} PlaybackPosition;

extern long audio_pan(long, long);
extern unsigned long audio_volume(long, long);
#pragma aux audio_pan parm [eax] [edx] modify exact [eax edx];
#pragma aux audio_volume parm [eax] [edx] modify exact [eax edx];
extern void sound_sample_done_offset(void);

/* The outer playback frame keeps Y live in EBP through both lookups. */
extern long position_y(void);
#pragma aux position_y = "" parm [] value [ebp] modify exact [];
extern long position_x(long);
#pragma aux position_x = parm nomemory [eax] value [eax] modify exact nomemory [];

void playback_position(PlaybackPosition *, long, long, volatile long);
#pragma aux playback_position parm [esi] [eax] [ecx] [] modify exact [eax edx];
void playback_position(PlaybackPosition *descriptor, long initial_x, long flags, volatile long x)
{
    if (initial_x == 0 && position_y() == 0) {
        descriptor->pan = 32768;
        descriptor->volume = 0x7fff7fffL;
    } else {
        long pan_x = position_x(x);
        long pan_y = position_y();
        descriptor->pan = audio_pan(pan_x, pan_y);
        if (flags & 4) {
            descriptor->volume = 0x6fff6fffL;
        } else {
            long volume_x = position_x(x);
            long volume_y = position_y();
            descriptor->volume = audio_volume(volume_x, volume_y);
        }
    }

    /* This shared continuation belongs to the following selected phase. */
    descriptor->on_done = sound_sample_done_offset;
}
