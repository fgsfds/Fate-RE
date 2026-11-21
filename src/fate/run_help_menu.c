#include "menucall.h"

extern MenuRecord *help_entries[];
extern unsigned help_selection;
extern const char help_menu_title[];

extern int run_first_help_pages(void);
#pragma aux run_first_help_pages modify exact [eax];
extern int run_second_help_pages(void);
#pragma aux run_second_help_pages modify exact [eax];
extern int run_help_submenu(void);
#pragma aux run_help_submenu modify exact [eax];

int run_help_menu(void)
{
    int running = keep_menu_running(1);

    while (running) {
        short tile = keep_menu_tile(0x820);
        if (!(running = keep_menu_running(run_menu_loop(
                &help_selection, 4,
                keep_menu_tile_after_arguments(tile, &help_selection, 4, help_menu_title),
                help_menu_title, help_entries))))
            continue;
        switch (help_selection) {
        case 1:
            run_first_help_pages();
            break;
        case 0:
            run_second_help_pages();
            break;
        case 2:
            run_help_submenu();
            break;
        case 3:
            running = keep_menu_running(0);
            break;
        }
    }
    return running;
}
