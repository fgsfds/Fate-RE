#include "menucall.h"

extern MenuRecord *mouse_entries[];
extern unsigned mouse_settings_selection;
extern const char mouse_settings_title[];

extern int run_mouse_button_menu(void);
#pragma aux run_mouse_button_menu modify exact [eax];
extern int run_mouse_sensitivity_menu(void);
#pragma aux run_mouse_sensitivity_menu modify exact [eax];

/* Set up the other register arguments before widening the tile from BX. */

int run_mouse_settings(void)
{
    int running = keep_menu_running(1);

    while (running) {
        short tile = keep_menu_tile(0x820);
        if (!(running = keep_menu_running(run_menu_loop(
                &mouse_settings_selection, 3,
                keep_menu_tile_after_arguments(tile, &mouse_settings_selection, 3, mouse_settings_title),
                mouse_settings_title, mouse_entries))))
            continue;
        switch (mouse_settings_selection) {
        case 0:
            run_mouse_sensitivity_menu();
            break;
        case 1:
            run_mouse_button_menu();
            break;
        case 2:
            running = keep_menu_running(0);
            break;
        }
    }
    return running;
}
