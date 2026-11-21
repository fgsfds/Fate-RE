#include "sndslot.h"

extern unsigned char audio_enabled;
extern volatile int audio_timer_handle;
extern int audio_driver, sound_archive_handle;
extern int timer_remove_callback(int);
#pragma aux timer_remove_callback modify exact [eax edx];
extern void audio_driver_shutdown(int, int);
#pragma aux audio_driver_shutdown modify exact [eax edx];
extern void audio_system_shutdown(void);
#pragma aux audio_system_shutdown modify exact [eax];
extern void close_sound_archive(int);
#pragma aux close_sound_archive "close_" modify exact [eax];
/* Keep the release flag in EBX across the timer callback removal. */
extern int keep_close_flag(int);
#pragma aux keep_close_flag = "" parm [ebx] value [ebx] modify exact [];

void shutdown_game_audio(void)
{
    if (audio_enabled) {
        int from_timer = audio_timer_handle;
        int release = keep_close_flag(1);
        timer_remove_callback(from_timer);
        audio_driver_shutdown(audio_driver, release);
        audio_system_shutdown();
        if (sound_archive_handle != -1)
            close_sound_archive(sound_archive_handle);
    }
}

#pragma pack(push, 1)
typedef struct {
    char opaque[0x1c];
    int slot;
} CompletedSample;
#pragma pack(pop)

extern const char sample_callback_overflow[];
extern void report_game_error(const char *);
#pragma aux report_game_error modify exact [eax];

/* Preserve the callback's original allocation of its slot and table index. */
extern int keep_completed_index(int);
#pragma aux keep_completed_index = "" parm [ebx] value [ebx] modify exact [];
extern SoundSlot *keep_first_slot(SoundSlot *);
#pragma aux keep_first_slot = "" parm [ebx] value [ebx] modify exact [];
extern SoundSlot *keep_second_slot(SoundSlot *);
#pragma aux keep_second_slot = "" parm [ebx] value [ebx] modify exact [];
extern const CompletedSample *hold_sample_exclusive(const CompletedSample *);
#pragma aux hold_sample_exclusive = "" parm [edx] value [edx] modify exact [ebx];

void sound_sample_done(const CompletedSample *);
#pragma aux sound_sample_done parm caller [] modify exact [eax ebx ecx edx];

void sound_sample_done(const CompletedSample *sample)
{
    int index;

    sample = hold_sample_exclusive(sample);
    for (index = 0; index < 16; ++index) {
        int completed = keep_completed_index(sample->slot);
        if (index != completed)
            continue;
        keep_first_slot(sound_slots[keep_completed_index(completed)])->handle = -1;
        keep_second_slot(sound_slots[index])->sprite = 0;
        sound_slots[index]->flags = 0;
        break;
    }
    if (index == 16)
        report_game_error(sample_callback_overflow);
}
