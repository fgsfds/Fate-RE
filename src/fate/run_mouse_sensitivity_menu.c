#include "menucall.h"

#pragma pack(push, 1)
typedef struct {
    unsigned char prefix[7];
    long value, maximum;
} MouseSensitivityItem;
#pragma pack(pop)

extern MenuRecord *mouse_button_entries[];
extern unsigned mouse_sensitivity_selection;
extern const char mouse_sensitivity_title[];
extern float mouse_x_scale, mouse_y_scale;
extern const float mouse_sensitivity_multiplier;
extern const double mouse_sensitivity_divisor;

extern MouseSensitivityItem *keep_sensitivity_item(MouseSensitivityItem *);
#pragma aux keep_sensitivity_item = "" parm [ebx] value [ebx] modify exact [];

int run_mouse_sensitivity_menu(void)
{
    int running;
    float scale;
    MouseSensitivityItem *second;

    keep_sensitivity_item((MouseSensitivityItem *)mouse_button_entries[0])->value =
        (long)(mouse_x_scale * mouse_sensitivity_multiplier);
    ((MouseSensitivityItem *)mouse_button_entries[0])->maximum = 16;
    keep_sensitivity_item((MouseSensitivityItem *)mouse_button_entries[1])->value =
        (long)(mouse_y_scale * mouse_sensitivity_multiplier);
    second = (MouseSensitivityItem *)mouse_button_entries[1];
    running = keep_menu_running(1);
    second->maximum = 16;

    while (running) {
        short tile = keep_menu_tile(0x820);
        if (!(running = keep_menu_running(run_menu_loop(
                &mouse_sensitivity_selection, 3,
                keep_menu_tile_after_arguments(tile, &mouse_sensitivity_selection, 3, mouse_sensitivity_title),
                mouse_sensitivity_title, mouse_button_entries))))
            continue;

        if (((MouseSensitivityItem *)mouse_button_entries[0])->value < 1)
            ((MouseSensitivityItem *)mouse_button_entries[0])->value = 1;
        if (((MouseSensitivityItem *)mouse_button_entries[1])->value < 1)
            ((MouseSensitivityItem *)mouse_button_entries[1])->value = 1;
        scale = ((MouseSensitivityItem *)mouse_button_entries[0])->value / mouse_sensitivity_divisor;
        mouse_x_scale = scale;
        scale = ((MouseSensitivityItem *)mouse_button_entries[1])->value / mouse_sensitivity_divisor;
        mouse_y_scale = scale;
        switch (mouse_sensitivity_selection) {
        case 0:
        case 1:
            break;
        case 2:
            running = keep_menu_running(0);
            break;
        }
    }
    return running;
}
