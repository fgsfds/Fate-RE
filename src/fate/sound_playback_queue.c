#include "sndslot.h"

typedef struct AudioSample AudioSample;

extern int audio_driver;
extern volatile int frame_state_17160f;
extern long queue_audio_sample(unsigned, const AudioSample *);
#pragma aux queue_audio_sample parm [eax] [edx] modify exact [eax edx gs];

/* The surrounding playback frame preserves the original Y in EBP. */
extern long playback_y(void);
#pragma aux playback_y = "" parm [] value [ebp] modify exact [];

extern int index_in_eax(int);
#pragma aux index_in_eax = parm nomemory [eax] value [eax] modify exact nomemory [];
extern SoundSlot *slot_in_eax(SoundSlot *);
#pragma aux slot_in_eax = parm nomemory [eax] value [eax] modify exact nomemory [];
extern int handle_in_edx(int);
#pragma aux handle_in_edx = parm nomemory [edx] value [edx] modify exact nomemory [];
extern long coordinate_in_edx(long);
#pragma aux coordinate_in_edx = parm nomemory [edx] value [edx] modify exact nomemory [];
extern const AudioSample *sample_in_edx(const AudioSample *);
#pragma aux sample_in_edx = parm nomemory [edx] value [edx] modify exact nomemory [];
extern unsigned driver_in_eax(unsigned);
#pragma aux driver_in_eax = parm nomemory [eax] value [eax] modify exact nomemory [];

/* Each field assignment uses a fresh selection in the original routine. */
#define SELECTED_SLOT() slot_in_eax(sound_slots[index_in_eax(frame_state_17160f)])

/* Borrow the original [ESP+4] X spill as the first private stack formal.
 * Selected slices include the handle branch and both result paths.
 * Both private RET 4 instructions are excluded and guarded; the original
 * short jump and frame epilogue remain in assembly. */
int playback_queue(const AudioSample *, int, long, volatile long);
#pragma aux playback_queue parm [esi] [edi] [ecx] [] value [eax] modify exact [eax edx gs];
int playback_queue(const AudioSample *descriptor, int sound, long flags, volatile long x)
{
    SoundSlot *slot;
    long x_coordinate;
    const AudioSample *source;
    unsigned driver;
    int handle;

    SELECTED_SLOT()->sound_id = sound;
    SELECTED_SLOT()->flags = flags;
    slot = SELECTED_SLOT();
    x_coordinate = coordinate_in_edx(x);
    slot->x = x_coordinate;
    SELECTED_SLOT()->y = playback_y();

    source = sample_in_edx(descriptor);
    driver = driver_in_eax((unsigned)audio_driver);
    handle = handle_in_edx((int)queue_audio_sample(driver, source));
    SELECTED_SLOT()->handle = handle;

    handle = handle_in_edx(SELECTED_SLOT()->handle);
    if (handle == -1) {
        SELECTED_SLOT()->sprite = 0;
        SELECTED_SLOT()->flags = 0;
        return index_in_eax(handle);
    }
    return index_in_eax(frame_state_17160f);
}
