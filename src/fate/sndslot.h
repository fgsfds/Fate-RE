#ifndef FATE_SOUND_SLOT_H
#define FATE_SOUND_SLOT_H

#pragma pack(push, 1)
typedef struct {
    int handle;
    int sound_id;
    unsigned char *cache;
    unsigned char cache_lock;
    unsigned char reserved;
    short sprite;
    long x, y;
    long flags;
} SoundSlot;
#pragma pack(pop)

extern SoundSlot *sound_slots[];

#endif
