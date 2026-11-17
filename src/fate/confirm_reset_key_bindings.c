#include "menucall.h"
extern unsigned key_confirm_selection;
extern const char key_confirm_title[];
extern MenuRecord *key_confirm_entries[];

extern void reset_key_bindings(void);
#pragma aux reset_key_bindings modify exact [eax];

extern int keep_reset_running(int);
#pragma aux keep_reset_running = "" parm [eax] value [eax] modify exact [];

void confirm_reset_key_bindings(void)
{
    int running = 1;

    while (keep_reset_running(running)) {
        short tile = keep_menu_tile(0x834);
        if (!(running = run_menu_loop(
                &key_confirm_selection, 2,
                keep_menu_tile_after_arguments(tile, &key_confirm_selection, 2, key_confirm_title),
                key_confirm_title, key_confirm_entries)))
            continue;
        switch (key_confirm_selection) {
        case 0:
            reset_key_bindings();
            /* Fall through. */
        case 1:
            running = 0;
            break;
        }
    }
}
