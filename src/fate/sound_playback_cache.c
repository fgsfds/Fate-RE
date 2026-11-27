typedef struct {
    unsigned char *sample;
    int sound;
} SoundCacheEntry;

extern SoundCacheEntry frame_state_16fdac[16];
extern volatile int frame_state_17160f;
extern volatile int frame_state_17160b;

/* Direct transfers within the existing playback frame. */
extern void playback_archive_failure(void);
#pragma aux playback_archive_failure parm [] aborts modify exact [];
extern void playback_cached_sample(unsigned char *);
#pragma aux playback_cached_sample parm [eax] aborts modify exact [];

extern int cache_index_ebx(int);
#pragma aux cache_index_ebx = "" parm nomemory [ebx] value [ebx] modify exact nomemory [];
/* The full-slot comparison leaves its input live in EBX on fallthrough. */
extern int cache_active_ebx(void);
#pragma aux cache_active_ebx = "" parm [] value [ebx] modify exact [];
extern unsigned cache_index_eax(unsigned);
#pragma aux cache_index_eax = "" parm nomemory [eax] value [eax] modify exact nomemory [];

#define CACHE_AT_OFFSET(offset) \
    ((SoundCacheEntry *)((unsigned char *)&frame_state_16fdac + (offset)))

/* EDI carries the sound ID and ECX carries the original flags.
 * A miss reaches the archive phase at the private RET site. */
void playback_cache_lookup(int);
#pragma aux playback_cache_lookup parm [edi] modify exact [eax ebx gs];
void playback_cache_lookup(int sound)
{
    int slot;
    int initial_slot = cache_index_ebx(frame_state_17160f);
    if (initial_slot == 16)
        playback_archive_failure();
    if (frame_state_16fdac[cache_active_ebx()].sound == -1)
        return;

    frame_state_17160b = cache_index_ebx(0);
    do {
        unsigned offset = cache_index_eax(frame_state_17160b) << 3;
        if (sound == CACHE_AT_OFFSET(offset)->sound)
            playback_cached_sample(CACHE_AT_OFFSET(cache_index_eax(offset))->sample);

        slot = cache_index_ebx(frame_state_17160b);
        slot = cache_index_ebx(slot + 1);
        frame_state_17160b = slot;
    } while (slot < 16);
}
