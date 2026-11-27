#include "sndslot.h"

typedef void (*SampleCallback)(void);
typedef struct {
    unsigned char prior_fields[0x2c];
    long volume;
    long loop_count;
    unsigned char sample_fields[0x28];
    SampleCallback on_start;
    SampleCallback on_done;
    SampleCallback on_loop;
} PlaybackDescriptor;

extern void sound_callback_return_offset(void);
extern void sound_sample_done_offset(void);
extern volatile int frame_state_17160f;

extern long in_eax(long);
#pragma aux in_eax = parm nomemory [eax] value [eax] modify exact nomemory [];
extern long in_edx(long);
#pragma aux in_edx = parm nomemory [edx] value [edx] modify exact nomemory [];
extern SoundSlot *slot_in_eax(SoundSlot *);
#pragma aux slot_in_eax = parm nomemory [eax] value [eax] modify exact nomemory [];

/* Entry and fallthrough keep the descriptor and playback flags live. */
void playback_options(PlaybackDescriptor *, long);
#pragma aux playback_options parm [esi] [ecx] modify exact [eax edx];
void playback_options(PlaybackDescriptor *descriptor, long flags)
{
    descriptor->on_done = sound_sample_done_offset;
    descriptor->on_start = sound_callback_return_offset;
    descriptor->on_loop = sound_callback_return_offset;
    if (flags & 1) {
        long sprite = in_edx(in_eax(in_eax(flags) >> 16));
        SoundSlot *slot = slot_in_eax(sound_slots[in_eax(frame_state_17160f)]);
        slot->sprite = (short)sprite;
        descriptor->loop_count = -1;
    }
    if ((flags & 8) || (flags & 16)) {
        descriptor->loop_count = -1;
        descriptor->volume = 0;
    }
}
