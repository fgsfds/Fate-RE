#include "menucall.h"

#pragma pack(push, 1)
typedef struct {
    unsigned char prefix[7];
    long value, maximum;
} AudioMenuItem;
#pragma pack(pop)

extern MenuRecord *audio_entries[];
extern unsigned audio_menu_selection;
extern const char audio_menu_title[];

extern unsigned long get_audio_flag_a(void), get_audio_flag_b(void);
#pragma aux get_audio_flag_a modify exact [eax];
#pragma aux get_audio_flag_b modify exact [eax];
extern void set_audio_flag_a(unsigned long), set_audio_flag_b(unsigned long);
#pragma aux set_audio_flag_a modify exact [eax];
#pragma aux set_audio_flag_b modify exact [eax];
extern long get_audio_level_a(void), get_audio_level_b(void);
#pragma aux get_audio_level_a modify exact [eax];
#pragma aux get_audio_level_b modify exact [eax];
extern void set_audio_level_a(long), set_audio_level_b(long);
#pragma aux set_audio_level_a modify exact [eax];
#pragma aux set_audio_level_b modify exact [eax];

/* Preserve the original registers used for audio item and level setup. */
extern AudioMenuItem *keep_audio_menu_item(AudioMenuItem *);
#pragma aux keep_audio_menu_item = "" parm [ebx] value [ebx] modify exact [];
extern long keep_first_audio_level(long);
#pragma aux keep_first_audio_level = "" parm [ebx] value [ebx] modify exact [];

int run_audio_menu(void)
{
    int running;
    AudioMenuItem *second;
    long value;
    value = get_audio_flag_a();
    keep_audio_menu_item((AudioMenuItem *)audio_entries[2])->value = value;
    value = get_audio_flag_b();
    keep_audio_menu_item((AudioMenuItem *)audio_entries[3])->value = value;
    value = keep_first_audio_level(get_audio_level_a());
    ((AudioMenuItem *)audio_entries[0])->value = value;
    value = get_audio_level_b();
    keep_audio_menu_item((AudioMenuItem *)audio_entries[1])->value = value;
    ((AudioMenuItem *)audio_entries[0])->maximum = 16;
    second = (AudioMenuItem *)audio_entries[1];
    running = keep_menu_running(1);
    second->maximum = 16;

    while (running) {
        short tile = keep_menu_tile(0x821);
        if (!(running = keep_menu_running(run_menu_loop(
                &audio_menu_selection, 5,
                keep_menu_tile_after_arguments(tile, &audio_menu_selection, 5, audio_menu_title),
                audio_menu_title, audio_entries))))
            continue;

        set_audio_level_a(((AudioMenuItem *)audio_entries[0])->value);
        set_audio_level_b(((AudioMenuItem *)audio_entries[1])->value);
        switch (audio_menu_selection) {
        case 0:
        case 1:
            break;
        case 2:
            ((unsigned char *)&((AudioMenuItem *)audio_entries[2])->value)[0] ^= 1;
            set_audio_flag_a(((AudioMenuItem *)audio_entries[2])->value);
            break;
        case 3:
            ((unsigned char *)&((AudioMenuItem *)audio_entries[3])->value)[0] ^= 1;
            set_audio_flag_b(((AudioMenuItem *)audio_entries[3])->value);
            break;
        case 4:
            running = keep_menu_running(0);
            break;
        }
    }
    return running;
}
