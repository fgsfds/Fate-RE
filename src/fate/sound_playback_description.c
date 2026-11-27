typedef struct {
    unsigned long entry_tag;
    long offset;
    unsigned long length;
} SoundArchiveEntry;

typedef struct {
    unsigned char *sample;
    unsigned char format_header[8];
    unsigned long length;
    unsigned long status;
    unsigned char client_header[8];
    int slot;
    unsigned char client_data[12];
    long volume;
    long loop_count;
    unsigned long rate;
    unsigned long sample_bits;
    unsigned long channels;
    unsigned long pitch;
} PlaybackDescriptor;

/* Production loader initializes IDs 0..163 in slots 1..164.
 * Slot zero is the predecessor used only by the explicitly seeded -1 fixture. */
extern SoundArchiveEntry *frame_state_16fb18[165];
extern volatile int frame_state_17160f;

extern unsigned long length_in_eax(unsigned long);
#pragma aux length_in_eax = parm nomemory [eax] value [eax] modify exact nomemory [];
extern int index_in_eax(int);
#pragma aux index_in_eax = parm nomemory [eax] value [eax] modify exact nomemory [];
extern long x_in_eax(long);
#pragma aux x_in_eax = parm nomemory [eax] value [eax] modify exact nomemory [];

/* EAX returns the original frame's X coordinate for the positional test.
 * The private compiler return is excluded at the original fallthrough. */
long playback_description(PlaybackDescriptor *, unsigned char *, int, volatile long);
#pragma aux playback_description parm [esi] [eax] [edi] [] value [eax] modify exact [eax];
long playback_description(PlaybackDescriptor *descriptor, unsigned char *sample, int sound,
                          volatile long x)
{
    unsigned long length;
    int slot;
    long initial_x;
    descriptor->sample = sample;
    length = length_in_eax(frame_state_16fb18[(unsigned int)sound + 1U]->length);
    descriptor->status = 0;
    descriptor->length = length;
    slot = index_in_eax(frame_state_17160f);
    descriptor->loop_count = 0;
    descriptor->rate = 11025;
    descriptor->sample_bits = 8;
    descriptor->channels = 1;
    descriptor->slot = slot;
    initial_x = x_in_eax(x);
    descriptor->pitch = 32768;
    return initial_x;
}
