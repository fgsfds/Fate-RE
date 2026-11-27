#include "menurec.h"

extern MenuRecord *difficulty_entries[];
extern unsigned difficulty_selection;
extern const char difficulty_menu_title[];
extern short difficulty_divisor;
extern int run_menu_loop(unsigned *, int, short, const char *, MenuRecord **);
#pragma aux run_menu_loop parm routine [eax] [edx] [ebx] [ecx] modify exact [eax edx ebx ecx];

int run_difficulty_menu(void)
{
    int running = 1;
    while (running) {
        if (!(running = run_menu_loop(&difficulty_selection, 4, 0x820,
                                      difficulty_menu_title, difficulty_entries)))
            continue;
        switch (difficulty_selection) {
        case 0:
            difficulty_divisor = 4;
            return 1;
        case 1:
            difficulty_divisor = 2;
            return 2;
        case 2:
            difficulty_divisor = 1;
            return 3;
        case 3:
            running = 0;
            break;
        }
    }
    return running;
}
