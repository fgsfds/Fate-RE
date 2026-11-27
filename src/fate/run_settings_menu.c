#include "menucall.h"

extern MenuRecord *settings_entries[];
extern unsigned settings_selection;
extern const char settings_menu_title[];
extern int run_keyboard_settings(void);
#pragma aux run_keyboard_settings modify exact [eax];
extern int run_mouse_settings(void);
#pragma aux run_mouse_settings modify exact [eax];
/* With descriptor zero, the save routine opens and seeks its own file. */
extern int save_local_configuration(int);
#pragma aux save_local_configuration "save_game_configuration_" parm [eax] modify exact [eax];
extern unsigned keep_initial_menu_selection(unsigned);
#pragma aux keep_initial_menu_selection = parm [ebx] value [ebx] modify exact [];

int run_settings_menu(void)
{
    unsigned initial = keep_initial_menu_selection(4);
    int running = keep_menu_running(1);
    settings_selection = initial;
    goto check_menu;

    /* The keyboard and mouse paths share the configuration save. */

keyboard_settings:
    run_keyboard_settings();
save_settings:
    save_local_configuration(0);

check_menu:
    while (running) {
        short tile = keep_menu_tile(0x820);
        if (!(running = keep_menu_running(run_menu_loop(
                &settings_selection, 5,
                keep_menu_tile_after_arguments(tile, &settings_selection, 5, settings_menu_title),
                settings_menu_title, settings_entries))))
            continue;

        switch (settings_selection) {
        case 0:
            goto keyboard_settings;
        case 2:
            goto save_settings;
        case 3:
            break;
        case 1:
            run_mouse_settings();
            goto save_settings;
        case 4:
            running = keep_menu_running(0);
            break;
        }
    }
    return running;
}

/* The compiler shares the settings return code with the options menu. */
#pragma pack(push, 1)
typedef struct {
    unsigned char prefix[3];
    const char *caption;
} OptionMenuEntry;
#pragma pack(pop)

extern MenuRecord *options_entries[];
extern unsigned options_selection;
extern unsigned long gore_mode;
extern const char options_menu_title[], gore_on_caption[], gore_off_caption[];

extern int run_audio_menu(void);
#pragma aux run_audio_menu modify exact [eax];
extern int run_control_limits_menu(void);
#pragma aux run_control_limits_menu modify exact [eax];
#pragma aux run_settings_menu modify exact [eax];

int run_options_menu(void)
{
    unsigned initial = keep_initial_menu_selection(5);
    int running = keep_menu_running(1);
    options_selection = initial;
    goto check_menu;

toggle_gore:
    *(unsigned char *)&gore_mode ^= 1;
    if (gore_mode)
        ((OptionMenuEntry *)options_entries[0])->caption = gore_on_caption;
    else
        ((OptionMenuEntry *)options_entries[0])->caption = gore_off_caption;
    goto check_menu;

audio_menu:
    run_audio_menu();
save_options:
    save_local_configuration(0);

check_menu:
    while (running) {
        short tile = keep_menu_tile(0x820);
        if (!(running = keep_menu_running(run_menu_loop(
                &options_selection, 6,
                keep_menu_tile_after_arguments(tile, &options_selection, 6, options_menu_title),
                options_menu_title, options_entries))))
            continue;
        switch (options_selection) {
        case 0:
            goto toggle_gore;
        case 2:
            goto audio_menu;
        case 1:
            break;
        case 3:
            run_settings_menu();
            break;
        case 4:
            run_control_limits_menu();
            goto save_options;
        case 5:
            running = keep_menu_running(0);
            break;
        }
    }
    return running;
}
