#include "dosio.h"

typedef struct {
    unsigned metadata;
    unsigned offset;
    unsigned length;
} SoundIndexEntry;

typedef struct {
    unsigned page;
    unsigned short length;
    unsigned short unused_word_6;
    unsigned short metadata;
    unsigned short unused_word_10;
} SoundIndexRecord;
typedef char SoundIndexRecordSize[sizeof(SoundIndexRecord) == 12 ? 1 : -1];

extern SoundIndexRecord *sound_index_buffer;
extern SoundIndexEntry sound_index_storage[];
extern SoundIndexEntry *sound_index_entries[];
extern int sound_archive_handle;
extern const char sound_index_memory_error[], sound_archive_filename[], sound_archive_open_error[];

extern void *sound_allocate(unsigned);
#pragma aux sound_allocate "malloc_" modify exact [eax];
extern void sound_release(void *);
#pragma aux sound_release "free_" modify exact [eax];
extern void sound_clear(void *, int, unsigned);
#pragma aux sound_clear "memset_" modify exact [eax];
extern void report_game_error(const char *);
#pragma aux report_game_error modify exact [eax];

/* These register hints preserve the original Watcom instruction order. */
extern int keep_index(int);
#pragma aux keep_index = "" parm [edx] value [edx] modify exact [];
extern unsigned keep_archive_page(unsigned);
#pragma aux keep_archive_page = "" parm [ecx] value [ecx] modify exact [];
extern unsigned keep_entry_length(unsigned);
#pragma aux keep_entry_length = "" parm [esi] value [esi] modify exact [];

extern SoundIndexEntry *keep_entry_pointer(SoundIndexEntry *);
#pragma aux keep_entry_pointer = "" parm [ebx] value [ebx] modify exact [];
extern int refresh_sound_position(int);
#pragma aux refresh_sound_position = "" parm [edx] value [edx] modify exact [ebx];
extern SoundIndexRecord *keep_record_base(SoundIndexRecord *);
#pragma aux keep_record_base = "" parm [ebx] value [ebx] modify exact [];
extern unsigned keep_index_times_three(unsigned);
#pragma aux keep_index_times_three = "" parm [ecx] value [ecx] modify exact [];
extern SoundIndexRecord *keep_buffer_with_index(SoundIndexRecord *, unsigned);
#pragma aux keep_buffer_with_index = "" parm [ebx] [ecx] value [ebx] modify exact [];

void load_sound_archive(void)
{
    int index;

    sound_index_buffer = sound_allocate(4096);
    if (!sound_index_buffer)
        report_game_error(sound_index_memory_error);
    sound_clear(sound_index_buffer, 0, 4096);
    sound_archive_handle = dos_open(sound_archive_filename, 0x200);
    if (sound_archive_handle == -1)
        report_game_error(sound_archive_open_error);
    lseek(sound_archive_handle, -4096, 2);
    read(sound_archive_handle, sound_index_buffer, 4096);

    index = keep_index(0);
    do {
        unsigned field, page, position, length;
        SoundIndexEntry *entry;
        SoundIndexRecord *buffer;

        sound_index_entries[index] = &sound_index_storage[index];
        page = keep_archive_page(sound_index_buffer[index].page);
        entry = keep_entry_pointer(sound_index_entries[index]);
        entry->offset = page << 12;
        index = refresh_sound_position(index);
        /* Each archive entry occupies three dwords. */
        position = keep_index_times_three(index * 3);
        buffer = keep_buffer_with_index(sound_index_buffer, position);
        position *= 4;
        length = keep_entry_length(((SoundIndexRecord *)((char *)buffer + position))->length);
        entry = keep_entry_pointer(sound_index_entries[index]);
        entry->length = length;
        buffer = keep_record_base(sound_index_buffer);
        field = ((SoundIndexRecord *)((char *)buffer + position))->metadata;
        ++index;
        sound_index_entries[index - 1]->metadata = field;
    } while (index < 164);
    sound_release(sound_index_buffer);
}
