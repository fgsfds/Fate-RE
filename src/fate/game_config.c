#include "dosio.h"

extern long get_audio_level_a(void), get_audio_level_b(void);
extern int get_audio_flag_a(void), get_audio_flag_b(void);
extern void set_audio_level_a(long), set_audio_level_b(long);
extern void set_audio_flag_a(unsigned long), set_audio_flag_b(unsigned long);
#pragma aux get_audio_level_a modify exact [eax];
#pragma aux get_audio_level_b modify exact [eax];
#pragma aux get_audio_flag_a modify exact [eax];
#pragma aux get_audio_flag_b modify exact [eax];
#pragma aux set_audio_level_a modify exact [eax];
#pragma aux set_audio_level_b modify exact [eax];
#pragma aux set_audio_flag_a modify exact [eax];
#pragma aux set_audio_flag_b modify exact [eax];

typedef struct {
    long level_a, level_b, flag_a, flag_b;
} AudioSettings;

extern const char game_configuration_filename[];
extern unsigned char active_key_bindings[25], mouse_button_bindings[3];
extern AudioSettings stored_audio_settings;
extern long mouse_scales[2], movement_limits[2];

int load_game_configuration(int descriptor, long seek_status);
int save_game_configuration(int descriptor, long seek_status);
#pragma aux load_game_configuration parm [eax] [edx] modify exact [eax];
#pragma aux save_game_configuration parm [eax] [edx] modify exact [eax];

int load_game_configuration(int descriptor, long seek_status)
{
    int opened_here = 0;
    if (descriptor == 0) {
        opened_here = 1;
        descriptor = dos_open(game_configuration_filename, 0x202);
        if (descriptor == -1)
            return descriptor;
        seek_status = lseek(descriptor, 0, 0);
    }
    if (seek_status == -1) {
        close(descriptor);
        return seek_status;
    }
    if (read(descriptor, active_key_bindings, sizeof(active_key_bindings)) != sizeof(active_key_bindings)) {
io_failed:
        close(descriptor);
        return -1;
    }
    if (read(descriptor, mouse_button_bindings, sizeof(mouse_button_bindings)) != sizeof(mouse_button_bindings)
        || read(descriptor, &stored_audio_settings, sizeof(stored_audio_settings)) != sizeof(stored_audio_settings)
        || read(descriptor, mouse_scales, sizeof(mouse_scales)) != sizeof(mouse_scales)
        || read(descriptor, movement_limits, sizeof(movement_limits)) != sizeof(movement_limits))
        goto io_failed;
    if (opened_here)
        close(descriptor);
    set_audio_flag_a(stored_audio_settings.flag_a);
    set_audio_flag_b(stored_audio_settings.flag_b);
    set_audio_level_a(stored_audio_settings.level_a);
    set_audio_level_b(stored_audio_settings.level_b);
    return 1;
}

int save_game_configuration(int descriptor, long seek_status)
{
    int opened_here = 0;
    stored_audio_settings.level_a = get_audio_level_a();
    stored_audio_settings.level_b = get_audio_level_b();
    stored_audio_settings.flag_a = get_audio_flag_a();
    stored_audio_settings.flag_b = get_audio_flag_b();
    if (descriptor == 0) {
        opened_here = 1;
        descriptor = dos_open(game_configuration_filename, 0x222, 0x180);
        if (descriptor == -1)
            return descriptor;
        seek_status = lseek(descriptor, 0, 0);
    }
    if (seek_status == -1) {
        close(descriptor);
        return seek_status;
    }
    if (write(descriptor, active_key_bindings, sizeof(active_key_bindings)) != sizeof(active_key_bindings)) {
io_failed:
        close(descriptor);
        return -1;
    }
    if (write(descriptor, mouse_button_bindings, sizeof(mouse_button_bindings)) != sizeof(mouse_button_bindings)
        || write(descriptor, &stored_audio_settings, sizeof(stored_audio_settings)) != sizeof(stored_audio_settings)
        || write(descriptor, mouse_scales, sizeof(mouse_scales)) != sizeof(mouse_scales)
        || write(descriptor, movement_limits, sizeof(movement_limits)) != sizeof(movement_limits))
        goto io_failed;
    if (opened_here) {
        close(descriptor);
        flushall();
    }
    return 1;
}
