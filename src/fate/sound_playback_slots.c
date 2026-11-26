#include "sndslot.h"

extern volatile int frame_state_17160f;
extern unsigned char frame_state_1705dc[16][240];

extern void playback_archive_failure(void);
#pragma aux playback_archive_failure parm [] aborts modify exact [];

/* The DOS CRT preserves EAX and ECX across the fill. */
extern void clear_playback_descriptor(void *, int, unsigned);
#pragma aux clear_playback_descriptor "memset_" parm [eax] [edx] [ebx] modify exact [edx];

extern int slot_index_eax(int);
#pragma aux slot_index_eax = "" parm nomemory [eax] value [eax] modify exact nomemory [];
extern SoundSlot *slot_pointer_eax(SoundSlot *);
#pragma aux slot_pointer_eax = "" parm nomemory [eax] value [eax] modify exact nomemory [];
extern unsigned descriptor_index_edx(unsigned);
#pragma aux descriptor_index_edx = "" parm nomemory [edx] value [edx] modify exact nomemory [];
extern unsigned descriptor_offset_eax(unsigned);
#pragma aux descriptor_offset_eax = "" parm nomemory [eax] value [eax] modify exact nomemory [];
extern unsigned char *descriptor_pointer_esi(unsigned char *);
#pragma aux descriptor_pointer_esi = "" parm nomemory [esi] value [esi] modify exact nomemory [];
extern unsigned char *descriptor_base_esi(unsigned, unsigned char *);
#pragma aux descriptor_base_esi = "" parm nomemory [eax] [esi] value [esi] modify exact nomemory [];
extern unsigned descriptor_offset_with_base_eax(unsigned, unsigned char *);
#pragma aux descriptor_offset_with_base_eax = "" parm nomemory [eax] [esi] value [eax] modify exact nomemory [];
extern unsigned descriptor_size_ebx(unsigned, unsigned);
#pragma aux descriptor_size_ebx = "" parm nomemory [eax] [ebx] value [ebx] modify exact nomemory [];
extern unsigned descriptor_offset_with_size_eax(unsigned, unsigned);
#pragma aux descriptor_offset_with_size_eax = "" parm nomemory [eax] [ebx] value [eax] modify exact nomemory [];
extern int descriptor_fill_edx(int);
#pragma aux descriptor_fill_edx = "" parm nomemory [edx] value [edx] modify exact nomemory [];

/* descriptor_base_esi established ESI; the offset/size identities preserve it. */
extern unsigned char *descriptor_live_base_esi(void);
#pragma aux descriptor_live_base_esi = "" parm [] value [esi] modify exact [];

extern int cache_slot_ebx(int);
#pragma aux cache_slot_ebx = "" parm nomemory [ebx] value [ebx] modify exact nomemory [];

/* EDI carries the sound ID and ECX carries the original playback flags.
 * On a free slot, ESI carries the cleared descriptor to the cache phase. */
void playback_slot_scan(int, unsigned long);
#pragma aux playback_slot_scan parm [edi] [ecx] modify exact [eax ebx edx esi gs];
void playback_slot_scan(int sound, unsigned long flags)
{
    int index;

    frame_state_17160f = slot_index_eax(0);
    do {
        SoundSlot *slot = slot_pointer_eax(sound_slots[slot_index_eax(frame_state_17160f)]);
        if (slot->handle == -1) {
            unsigned slot_index = descriptor_index_edx((unsigned)frame_state_17160f);
            unsigned offset = descriptor_offset_eax(slot_index) << 4;
            unsigned char *base;
            unsigned count;
            unsigned char *descriptor;
            int fill;

            offset = descriptor_offset_eax(offset - slot_index);
            base = descriptor_base_esi(offset, (unsigned char *)&frame_state_1705dc);
            offset = descriptor_offset_with_base_eax(offset, base);
            offset = descriptor_offset_eax(offset << 4);
            count = descriptor_size_ebx(offset, sizeof(frame_state_1705dc[0]));
            offset = descriptor_offset_with_size_eax(offset, count);
            descriptor = descriptor_pointer_esi(descriptor_live_base_esi() + offset);
            fill = descriptor_fill_edx(0);
            clear_playback_descriptor(descriptor, fill, count);
            break;
        }
        if ((flags & 4) && sound == slot->sound_id)
            playback_archive_failure();

        index = slot_index_eax(frame_state_17160f);
        index = slot_index_eax(index + 1);
        frame_state_17160f = index;
    } while (index < 16);
    /* The cache phase supplies this shared successor in the image. */
    if (cache_slot_ebx(frame_state_17160f) == 16)
        playback_archive_failure();
}
