#include "sndslot.h"

typedef struct {
    unsigned char *data;
    int sound_id;
} SoundPlaybackCache;

extern SoundSlot sound_slot_storage[];
extern unsigned char sound_cache[][60000];
extern SoundPlaybackCache sound_playback[];
extern const char sound_cache_error[];
extern void report_game_error(const char *);
#pragma aux report_game_error modify exact [eax];

/* Keep the final slot pointer in EAX across the index increment. */
extern SoundSlot *last_sound_slot(SoundSlot *);
#pragma aux last_sound_slot = "" parm [eax] value [eax] modify exact [];

void initialize_sound_slots(void)
{
    int index = 0;
    do {
        SoundSlot *slot = &sound_slot_storage[index];
        sound_slots[index] = slot;
        slot->handle = -1;
        sound_slots[index]->sound_id = 0;
        sound_slots[index]->cache_lock = 255;
        sound_slots[index]->cache = sound_cache[index];
        if (sound_slots[index]->cache == 0) {
            sound_slots[index]->cache_lock = 0;
            report_game_error(sound_cache_error);
        }
        slot = sound_slots[index];
        sound_playback[index].data = slot->cache;
        sound_playback[index].sound_id = -1;
        slot->sprite = 0;
        sound_slots[index]->x = 0;
        sound_slots[index]->y = 0;
        sound_slots[index]->flags = 0;
        slot = last_sound_slot(sound_slots[index]);
        ++index;
        slot->sound_id = -1;
    } while (index < 16);
}
