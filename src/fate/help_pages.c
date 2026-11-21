#include "menurec.h"

/* The first byte of each record enables its navigation entry. */
extern MenuRecord *help_extra_entries[];
extern unsigned help_page_selection;
extern int run_help_page_menu(int);
#pragma aux run_help_page_menu modify exact [eax];

extern char help_page_title[];
extern int run_menu_loop(unsigned *, int, short, const char *, MenuRecord **);
#pragma aux run_menu_loop parm routine [eax] [edx] [ebx] [ecx] modify exact [eax edx ebx ecx];

int run_help_page_menu(int tile)
{
    int running = 1;
    while (running == 1) {
        if (!(running = run_menu_loop(&help_page_selection, 3, (short)tile, help_page_title, help_extra_entries)))
            continue;
        switch (help_page_selection) {
        case 0: running = -1; break;
        case 1: running = -2; break;
        case 2: running = 0; break;
        }
    }
    return running;
}

int run_first_help_pages(void)
{
    int page = 0;
    for (;;) {
        (*help_extra_entries[0])[0] = 1;
        (*help_extra_entries[1])[0] = 1;
        if (!page) {
            (*help_extra_entries[1])[0] = 0;
            help_page_selection = 0;
        }
        switch (run_help_page_menu(0x834 + page)) {
        case -1:
            if (page < 0)
                ++page;
            break;
        case -2:
            if (page > 0)
                --page;
            break;
        default:
            return 0;
        }
    }
}

int run_second_help_pages(void)
{
    int page = 0;
    for (;;) {
        (*help_extra_entries[0])[0] = 1;
        (*help_extra_entries[1])[0] = 1;
        switch ((unsigned)page) {
        case 0:
            (*help_extra_entries[1])[0] = 0;
            help_page_selection = 0;
            break;
        case 2:
            (*help_extra_entries[0])[0] = 0;
            help_page_selection = 1;
            break;
        }
        switch (run_help_page_menu(0x835 + page)) {
        case -1:
            if (page < 2)
                ++page;
            break;
        case -2:
            if (page > 0)
                --page;
            break;
        default:
            return 0;
        }
    }
}

extern unsigned back_selection;
extern MenuRecord *help_back_entries[];
extern const char help_back_title[];

int run_help_submenu(void)
{
    int running = 1;

    while (running == 1) {
        if (!(running = run_menu_loop(&back_selection, running, 0x83e, help_back_title,
                                       help_back_entries)))
            continue;
        switch (back_selection) {
        case 0: running = 0; break;
        }
    }
    return running;
}
