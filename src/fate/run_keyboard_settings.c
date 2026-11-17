#include "menucall.h"

extern MenuRecord *key_action_entries[];
extern unsigned key_settings_selection;
extern const char key_settings_title[];

extern void confirm_reset_key_bindings(void);
#pragma aux confirm_reset_key_bindings modify exact [eax];
extern int run_key_binding_menu(void);
#pragma aux run_key_binding_menu modify exact [eax];

/* Set up the other register arguments before widening the tile from BX. */

int run_keyboard_settings(void)
{
    int running = keep_menu_running(1);

    while (running) {
        short tile = keep_menu_tile(0x820);
        if (!(running = keep_menu_running(run_menu_loop(
                &key_settings_selection, 3,
                keep_menu_tile_after_arguments(tile, &key_settings_selection, 3, key_settings_title),
                key_settings_title, key_action_entries))))
            continue;
        switch (key_settings_selection) {
        case 0:
            run_key_binding_menu();
            break;
        case 1:
            confirm_reset_key_bindings();
            break;
        case 2:
            running = keep_menu_running(0);
            break;
        }
    }
    return running;
}
