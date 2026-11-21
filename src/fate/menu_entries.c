#include "menurec.h"

extern MenuRecord demo_records[], difficulty_records[], audio_records[], limits_records[];
extern MenuRecord help_records[], help_extra_records[], help_back_records[];
extern MenuRecord mouse_records[], mouse_button_records[];
extern MenuRecord key_records[], key_action_records[], key_confirm_records[];

extern MenuRecord *demo_entries[], *difficulty_entries[], *audio_entries[], *limits_entries[];
extern MenuRecord *help_entries[], *help_extra_entries[], *help_back_entries[];
extern MenuRecord *mouse_entries[], *mouse_button_entries[];
extern MenuRecord *key_entries[], *key_action_entries[], *key_confirm_entries[];

#define INIT_ENTRIES(entries, records, count) \
    index = 0; \
    do { \
        MenuRecord *record = &records[index]; \
        ++index; \
        entries[index - 1] = record; \
    } while (index < count)

void initialize_demo_menu(void)
{
    int index;
    INIT_ENTRIES(demo_entries, demo_records, 3);
}

void initialize_difficulty_menu(void)
{
    int index;
    INIT_ENTRIES(difficulty_entries, difficulty_records, 4);
}

void initialize_audio_menu(void)
{
    int index;
    INIT_ENTRIES(audio_entries, audio_records, 5);
}

void initialize_control_limits_menu(void)
{
    int index;
    INIT_ENTRIES(limits_entries, limits_records, 3);
}

void initialize_help_menus(void)
{
    int index;
    INIT_ENTRIES(help_entries, help_records, 4);
    INIT_ENTRIES(help_extra_entries, help_extra_records, 3);
    INIT_ENTRIES(help_back_entries, help_back_records, 1);
}

void initialize_mouse_menus(void)
{
    int index;
    INIT_ENTRIES(mouse_entries, mouse_records, 3);
    INIT_ENTRIES(mouse_button_entries, mouse_button_records, 3);
}

void initialize_key_menu(void)
{
    int index;
    INIT_ENTRIES(key_entries, key_records, 25);
    INIT_ENTRIES(key_action_entries, key_action_records, 3);
    INIT_ENTRIES(key_confirm_entries, key_confirm_records, 2);
}

extern unsigned char default_key_bindings[25], active_key_bindings[25];

void reset_key_bindings(void)
{
    int index = 0;

    do {
        ++index;
        active_key_bindings[index - 1] = default_key_bindings[index - 1];
    } while (index < 25);
}
