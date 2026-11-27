#include "sndslot.h"

typedef void (*SampleCallback)(void);
typedef struct AudioSample AudioSample;

typedef struct {
    unsigned long entry_tag;
    long offset;
    unsigned long length;
} SoundArchiveEntry;

typedef struct {
    unsigned char *sample;
    int sound;
} SoundCacheEntry;

typedef struct {
    unsigned char *sample;
    unsigned char format_header[8];
    unsigned long length, status;
    unsigned char client_header[8];
    int slot;
    unsigned char client_data[12];
    long volume, loop_count;
    unsigned long rate, sample_bits, channels, pitch, pan;
    unsigned char callback_fields[0x14];
    SampleCallback on_start, on_done, on_loop;
    unsigned char tail[0x88];
} PlaybackDescriptor;

typedef struct {
    volatile unsigned archive_index_bytes;
    volatile long x;
} PlaybackScratch;

extern unsigned char audio_enabled;
extern unsigned long frame_state_12cd4, frame_state_12cd8;
extern int audio_driver;
extern char error_buffer[];
extern const char invalid_sound_number[];
extern volatile int frame_state_17160b, frame_state_17160f;
extern long frame_state_12cec;
extern int sound_archive_handle;
extern SoundCacheEntry frame_state_16fdac[16];
extern SoundArchiveEntry *frame_state_16fb18[165];
extern unsigned char frame_state_1705dc[16][240];

extern int sound_error_format(char *, const char *, ...);
#pragma aux sound_error_format "sprintf_" parm caller [] modify exact [eax];
extern void clear_playback_descriptor(void *, int, unsigned);
#pragma aux clear_playback_descriptor "memset_" parm [eax] [edx] [ebx] modify exact [edx];
extern long lseek(int, long, int);
#pragma aux lseek parm [eax] [edx] [ebx] modify exact [eax edx ebx];
extern int read(int, void *, unsigned);
#pragma aux read parm [eax] [edx] [ebx] modify exact [eax edx ebx];
extern long audio_pan(long, long);
#pragma aux audio_pan parm [eax] [edx] modify exact [eax edx];
extern unsigned long audio_volume(long, long);
#pragma aux audio_volume parm [eax] [edx] modify exact [eax edx];
extern long queue_audio_sample(unsigned, const AudioSample *);
#pragma aux queue_audio_sample parm [eax] [edx] modify exact [eax edx gs];
extern void sound_callback_return_offset(void);
extern void sound_sample_done_offset(void);

extern int sound_id_edi(int);
#pragma aux sound_id_edi = "" parm [edi] value [edi] modify exact [eax];
/* The original caller passes Y in EBX. The entry spill does not change EBX. */
extern long incoming_y_ebx(void);
#pragma aux incoming_y_ebx = "" parm [] value [ebx] modify exact [];
extern PlaybackDescriptor *descriptor_esi(PlaybackDescriptor *);
#pragma aux descriptor_esi = "" parm nomemory [esi] value [esi] modify exact nomemory [];
extern int echo_eax(int);
#pragma aux echo_eax = "" parm nomemory [eax] value [eax] modify exact nomemory [];
extern SoundSlot *slot_eax(SoundSlot *);
#pragma aux slot_eax = "" parm nomemory [eax] value [eax] modify exact nomemory [];

#define ARCHIVE_ENTRY(offset) \
    (*(SoundArchiveEntry **)((unsigned char *)&frame_state_16fb18 + ((offset) + 4U)))
#define SELECTED_SLOT() slot_eax(sound_slots[echo_eax(frame_state_17160f)])

/* Private compiler context. The hidden Y input is the actual incoming EBX value. */
int playback_complete_context(int, long, unsigned long);
#pragma aux playback_complete_context parm [eax] [edx] [ecx] value [eax] modify exact [eax ebx ecx edx gs];
int playback_complete_context(int sound, long x, unsigned long flags)
{
    PlaybackScratch scratch;
    PlaybackDescriptor *descriptor;
    unsigned char *sample;
    SoundArchiveEntry *entry;
    SoundSlot *slot;
    int index;
    int result;
    long y;

    sound = sound_id_edi(sound);
    scratch.x = x;
    y = incoming_y_ebx();
    if (!*(volatile unsigned char *)&audio_enabled) {
    failed:
        return -1;
    }
    if (!frame_state_12cd4 || !frame_state_12cd8)
        goto failed;
    if (sound > 163) {
        sound_error_format(error_buffer, invalid_sound_number);
        return -1;
    }

    frame_state_17160f = echo_eax(0);
    do {
        slot = SELECTED_SLOT();
        if (slot->handle == -1) {
            descriptor = descriptor_esi((PlaybackDescriptor *)frame_state_1705dc[frame_state_17160f]);
            clear_playback_descriptor(descriptor, 0, sizeof(*descriptor));
            break;
        }
        if ((flags & 4) && sound == slot->sound_id)
            goto failed;
        index = echo_eax(frame_state_17160f + 1);
        frame_state_17160f = index;
    } while (index < 16);

    index = frame_state_17160f;
    if (index == 16)
        goto failed;
    if (frame_state_16fdac[index].sound != -1) {
        frame_state_17160b = 0;
        do {
            index = frame_state_17160b;
            if (frame_state_16fdac[index].sound == sound) {
                sample = frame_state_16fdac[index].sample;
                goto describe;
            }
            index = frame_state_17160b + 1;
            frame_state_17160b = index;
        } while (index < 16);
    }
    if (frame_state_17160f == 16)
        goto failed;

    scratch.archive_index_bytes = (unsigned)sound << 2;
    entry = ARCHIVE_ENTRY(scratch.archive_index_bytes);
    lseek(sound_archive_handle, entry->offset, 0);
    entry = ARCHIVE_ENTRY(scratch.archive_index_bytes);
    result = read(sound_archive_handle, frame_state_16fdac[frame_state_17160f].sample, entry->length);
    entry = ARCHIVE_ENTRY(scratch.archive_index_bytes);
    frame_state_12cec = result;
    if ((unsigned)result != entry->length)
        goto failed;
    index = frame_state_17160f;
    frame_state_16fdac[index].sound = sound;
    sample = frame_state_16fdac[index].sample;

describe:
    descriptor->sample = sample;
    descriptor->length = frame_state_16fb18[(unsigned)sound + 1U]->length;
    descriptor->status = 0;
    descriptor->slot = frame_state_17160f;
    descriptor->loop_count = 0;
    descriptor->rate = 11025;
    descriptor->sample_bits = 8;
    descriptor->channels = 1;
    descriptor->pitch = 32768;
    if (!scratch.x && !y) {
        descriptor->pan = 32768;
        descriptor->volume = 0x7fff7fffL;
    } else {
        descriptor->pan = audio_pan(scratch.x, y);
        if (flags & 4)
            descriptor->volume = 0x6fff6fffL;
        else
            descriptor->volume = audio_volume(scratch.x, y);
    }
    descriptor->on_done = sound_sample_done_offset;
    descriptor->on_start = sound_callback_return_offset;
    descriptor->on_loop = sound_callback_return_offset;
    if (flags & 1) {
        SELECTED_SLOT()->sprite = (short)(flags >> 16);
        descriptor->loop_count = -1;
    }
    if ((flags & 8) || (flags & 16)) {
        descriptor->loop_count = -1;
        descriptor->volume = 0;
    }
    SELECTED_SLOT()->sound_id = sound;
    SELECTED_SLOT()->flags = flags;
    SELECTED_SLOT()->x = scratch.x;
    SELECTED_SLOT()->y = y;
    result = queue_audio_sample((unsigned)audio_driver, (const AudioSample *)descriptor);
    SELECTED_SLOT()->handle = result;
    result = SELECTED_SLOT()->handle;
    if (result == -1) {
        SELECTED_SLOT()->sprite = 0;
        SELECTED_SLOT()->flags = 0;
        return echo_eax(result);
    }
    return echo_eax(frame_state_17160f);
}
