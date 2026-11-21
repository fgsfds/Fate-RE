#include "sndslot.h"

extern void report_game_error(const char *);
#pragma aux report_game_error modify exact [eax];

extern unsigned char audio_enabled;
extern long audio_driver;
extern const char sound_slot_overflow[], null_sample_handle[], stop_sample_error[];
extern int request_sample_stop(long, int);
#pragma aux request_sample_stop modify exact [eax edx];

int stop_sound(int slot)
{
    if (!audio_enabled)
        return -1;
    if (slot < 0 || slot >= 16)
        report_game_error(sound_slot_overflow);
    if (sound_slots[slot]->handle == -1)
        report_game_error(null_sample_handle);
    if (request_sample_stop(audio_driver, sound_slots[slot]->handle))
        report_game_error(stop_sample_error);
    sound_slots[slot]->handle = -1;
    sound_slots[slot]->sprite = 0;
    sound_slots[slot]->flags = 0;
    return slot;
}

extern const char sprite_sound_slot_overflow[], stop_sprite_sample_error[], stopped_sprite_message[];
extern char error_buffer[];
extern int format_game_error(char *, const char *, ...);
#pragma aux format_game_error "sprintf_" parm caller [] modify exact [eax];

int stop_sprite_sound(int sprite)
{
    int slot;
    if (!audio_enabled)
        return -1;
    if (sprite < 0 || sprite >= 4096)
        report_game_error(sprite_sound_slot_overflow);
    slot = 0;
    do {
        SoundSlot *sound = sound_slots[slot];
        if (sound->handle != -1 && sound->sprite == sprite)
            break;
    } while (++slot < 16);
    if (request_sample_stop(audio_driver, sound_slots[slot]->handle))
        report_game_error(stop_sprite_sample_error);
    format_game_error(error_buffer, stopped_sprite_message, sprite);
    /* The original indexes the cleared slot by the requested sprite. */
    sound_slots[sprite]->handle = -1;
    sound_slots[sprite]->sprite = 0;
    sound_slots[sprite]->flags = 0;
    return sprite;
}
