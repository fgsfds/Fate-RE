#include "menurec.h"

/* Menu navigation and bounded slider changes. Longs are 32-bit under Watcom;
 * unsigned arithmetic preserves the original wrapped mouse accumulators.
 * The full, unmasked input code is returned. No handwritten instructions. */
#pragma pack(push,1)
typedef struct SelectionMenuEntry {
    unsigned char flags;
    unsigned short type;
    unsigned char bytes3_6[4];
    long value, limit;
    unsigned char bytes15_20[6];
} SelectionMenuEntry;
#pragma pack(pop)
extern short mouse_dx, mouse_dy;
extern long menu_mouse_x, menu_mouse_y;
extern unsigned menu_selection;
extern long menu_entry_count, menu_loop_state;
extern unsigned *menu_selection_storage;
extern unsigned long enabled_menu_entries;
extern MenuRecord *active_menu_entries[];
extern long presentation_input(void);
#pragma aux presentation_input modify exact [eax];
extern void play_sound(int, long, long, int);
#pragma aux play_sound parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
unsigned update_menu_selection(void);
#pragma aux update_menu_selection modify exact [eax];
unsigned update_menu_selection(void)
{
    unsigned key;
    SelectionMenuEntry *entry;
    long limit;
    key = presentation_input();
    menu_mouse_y = (long)((unsigned long)menu_mouse_y + (unsigned long)(long)mouse_dy);
    if (menu_mouse_y < -120) {
        key = 0x48;
        menu_mouse_y = 0;
    } else if (menu_mouse_y > 120) {
        key = 0x50;
        menu_mouse_y = 0;
    }
    menu_mouse_x = (long)((unsigned long)menu_mouse_x + (unsigned long)(long)mouse_dx);
    if (menu_mouse_x < -100) {
        key = 0x4b;
        menu_mouse_x = 0;
    } else if (menu_mouse_x > 100) {
        key = 0x4d;
        menu_mouse_x = 0;
    }
    /* Navigation requires 1..32 rows, an in-range selection, and at least
     * one enabled bit within those rows, as in the original menu loop. */
    switch (key & 0x7fU) {
    case 0x48:
        do {
            --menu_selection;
            if ((long)menu_selection < 0)
                menu_selection = menu_entry_count - 1;
        } while (((1UL << menu_selection) & enabled_menu_entries) == 0);
        play_sound(2,0,0,0);
        break;
    case 0x50:
        do {
            ++menu_selection;
            if ((long)menu_selection >= menu_entry_count)
                menu_selection = 0;
        } while (((1UL << menu_selection) & enabled_menu_entries) == 0);
        play_sound(2,0,0,0);
        break;
    case 0x4d:
        entry = (SelectionMenuEntry *)active_menu_entries[menu_selection];
        switch (entry->type) {
        case 1:
            *menu_selection_storage = menu_selection;
            menu_loop_state = 0;
            break;
        case 2:
            limit = (long)((unsigned long)entry->limit - 1U);
            if (limit > entry->value) {
                ++entry->value;
                play_sound(0x9c,0,0,0);
            }
            break;
        }
        break;
    case 0x4b:
        entry = (SelectionMenuEntry *)active_menu_entries[menu_selection];
        switch (entry->type) {
        case 1:
            *menu_selection_storage = menu_selection;
            menu_loop_state = 0;
            break;
        case 2:
            if (entry->value > 0) {
                --entry->value;
                play_sound(0x9c,0,0,0);
            }
            break;
        }
        break;
    case 0x1c:
    case 0x39:
        *menu_selection_storage = menu_selection;
        menu_loop_state = 0;
        play_sound(4,0,0,0);
        break;
    case 1:
        menu_loop_state = -1;
        play_sound(3,0,0,0);
        break;
    }
    return key;
}
