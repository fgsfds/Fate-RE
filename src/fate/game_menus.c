#include "menurec.h"

extern MenuRecord main_menu_records[], pause_records[], options_records[];
extern MenuRecord confirm_records[], controller_records[];
extern MenuRecord *main_entries[], *pause_entries[], *options_entries[];
extern MenuRecord *confirm_entries[], *controller_entries[];

extern void initialize_key_menu(void);
extern void initialize_demo_menu(void);
extern void initialize_difficulty_menu(void);
extern void initialize_help_menus(void);
extern void initialize_mouse_menus(void);
extern void initialize_control_limits_menu(void);
extern void initialize_audio_menu(void);
/* Descriptor zero opens the default file, so no seek status is passed in EDX. */
extern void load_default_game_configuration(int descriptor);
#pragma aux load_default_game_configuration "load_game_configuration_" parm [eax];

void initialize_game_menus(void)
{
    int index = 0;
    do {
        /* Watcom uses the shared byte offset for both record arrays. */
        unsigned long offset = index * sizeof(MenuRecord);
        MenuRecord *main_entry = (MenuRecord *)((unsigned long)main_menu_records + offset);
        ++index;
        main_entries[index - 1] = main_entry;
        pause_entries[index - 1] = (MenuRecord *)(offset + (unsigned long)pause_records);
    } while (index < 8);

    index = 0;
    do {
        MenuRecord *entry = &options_records[index];
        ++index;
        options_entries[index - 1] = entry;
    } while (index < 6);
    index = 0;
    do {
        MenuRecord *entry = &confirm_records[index];
        ++index;
        confirm_entries[index - 1] = entry;
    } while (index < 2);
    index = 0;
    do {
        MenuRecord *entry = &controller_records[index];
        ++index;
        controller_entries[index - 1] = entry;
    } while (index < 5);

    initialize_key_menu();
    initialize_demo_menu();
    initialize_difficulty_menu();
    initialize_help_menus();
    initialize_mouse_menus();
    initialize_control_limits_menu();
    initialize_audio_menu();
    load_default_game_configuration(0);
}
