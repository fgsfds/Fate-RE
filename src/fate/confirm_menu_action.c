#include "menucall.h"
extern unsigned confirm_selection;
extern const char confirm_menu_title[];
extern MenuRecord *confirm_entries[];

int confirm_menu_action(void)
{
    int running = 1;
    int confirmed = 0;
    while (running) {
        short tile = keep_menu_tile(0x820);
        if (!(running = run_menu_loop(
                &confirm_selection, 2,
                keep_menu_tile_after_arguments(tile, &confirm_selection, 2, confirm_menu_title),
                confirm_menu_title, confirm_entries)))
            continue;
        switch (confirm_selection) {
        case 0:
            confirmed = 1;
            running = 0;
            break;
        case 1:
            confirmed = 0;
            running = 0;
            break;
        }
    }
    return confirmed;
}
