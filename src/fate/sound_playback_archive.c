typedef struct {
    unsigned long entry_tag;
    long offset;
    unsigned long length;
} SoundArchiveEntry;

typedef struct {
    unsigned char *sample;
    int sound;
} SoundCacheEntry;

extern SoundArchiveEntry *frame_state_16fb18[165];
extern SoundCacheEntry frame_state_16fdac[16];
extern volatile int frame_state_17160f;
extern int sound_archive_handle;
extern long frame_state_12cec;

extern long lseek(int, long, int);
#pragma aux lseek parm [eax] [edx] [ebx] modify exact [eax edx ebx];
extern int read(int, void *, unsigned);
#pragma aux read parm [eax] [edx] [ebx] modify exact [eax edx ebx];

/* The selected compiler context uses direct conditional transfers to the
 * original failure return. These jumps keep the playback frame intact. */
extern void playback_archive_failure(void);
#pragma aux playback_archive_failure parm [] aborts modify exact [];

extern unsigned long archive_offset_eax(unsigned long);
#pragma aux archive_offset_eax = "" parm nomemory [eax] value [eax] modify exact nomemory [];
extern int index_eax(int);
#pragma aux index_eax = "" parm nomemory [eax] value [eax] modify exact nomemory [];
extern SoundArchiveEntry *entry_eax(SoundArchiveEntry *);
#pragma aux entry_eax = "" parm nomemory [eax] value [eax] modify exact nomemory [];
extern SoundArchiveEntry *entry_edx(SoundArchiveEntry *);
#pragma aux entry_edx = "" parm nomemory [edx] value [edx] modify exact nomemory [];
extern int origin_ebx(int);
#pragma aux origin_ebx = "" parm nomemory [ebx] value [ebx] modify exact nomemory [];
extern unsigned count_ebx(unsigned);
#pragma aux count_ebx = "" parm nomemory [ebx] value [ebx] modify exact nomemory [];
extern long offset_edx(long);
#pragma aux offset_edx = "" parm nomemory [edx] value [edx] modify exact nomemory [];
extern unsigned char *sample_edx(unsigned char *);
#pragma aux sample_edx = "" parm nomemory [edx] value [edx] modify exact nomemory [];

/* The table has a backed predecessor for the seeded sound -1. Normal IDs
 * are 0..163. Adding the predecessor's four bytes in unsigned arithmetic
 * wraps the seeded -1 offset to zero before forming an array pointer. */
#define ARCHIVE_ENTRY(offset) \
    (*(SoundArchiveEntry **)((unsigned char *)&frame_state_16fb18 + ((offset) + 4UL)))

/* The selected instructions borrow the original playback frame's [ESP]
 * word. The compiler's private allocation, release and RET are excluded.
 * EDI holds sound. ESI, EBP and ECX retain descriptor, Y and flags. */
unsigned char *playback_archive(int);
#pragma aux playback_archive parm [edi] value [eax] modify exact [eax ebx edx gs];
unsigned char *playback_archive(int sound)
{
    volatile unsigned long entry_offset;
    unsigned long first_entry_offset;
    SoundArchiveEntry *entry;
    unsigned char *sample;
    int origin;
    long offset;
    unsigned count;
    int result;
    int slot;

    if (frame_state_17160f == 16)
        playback_archive_failure();

    first_entry_offset = archive_offset_eax((unsigned long)sound) << 2;
    entry_offset = first_entry_offset;
    entry = entry_eax(ARCHIVE_ENTRY(first_entry_offset));
    origin = origin_ebx(0);
    offset = offset_edx(entry->offset);
    lseek(sound_archive_handle, offset, origin);

    entry = entry_eax(ARCHIVE_ENTRY(entry_offset));
    count = count_ebx(entry->length);
    slot = index_eax(frame_state_17160f);
    sample = sample_edx(frame_state_16fdac[slot].sample);
    result = read(sound_archive_handle, sample, count);

    entry = entry_edx(ARCHIVE_ENTRY(entry_offset));
    frame_state_12cec = result;
    if ((unsigned)result != entry->length)
        playback_archive_failure();

    slot = index_eax(frame_state_17160f);
    frame_state_16fdac[slot].sound = sound;
    return frame_state_16fdac[slot].sample;
}


