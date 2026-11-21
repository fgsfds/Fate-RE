#include "menucall.h"

#pragma pack(push, 1)
typedef struct {
    unsigned char prefix[7];
    long value, maximum;
} ControlMenuItem;
#pragma pack(pop)

extern MenuRecord *limits_entries[];
extern unsigned control_limits_selection;
extern const char control_limits_title[];
extern volatile long strafe_limit;
extern long strafe_step;

/* Preserve the Watcom register assignments in the fixed-point conversions. */
extern int keep_control_running(int);
#pragma aux keep_control_running = "" parm [ebx] value [ebx] modify exact [];

extern long keep_control_value(long);
#pragma aux keep_control_value = "" parm [edx] value [edx] modify exact [];
extern long keep_strafe_limit(long);
#pragma aux keep_strafe_limit = "" parm [esi] value [esi] modify exact [];

int run_control_limits_menu(void)
{
    int running = keep_control_running(1);

    ((ControlMenuItem *)limits_entries[0])->value = keep_control_value((strafe_limit + 1) / 16);
    ((ControlMenuItem *)limits_entries[0])->maximum = 16;
    ((ControlMenuItem *)limits_entries[1])->value = strafe_step;
    ((ControlMenuItem *)limits_entries[1])->maximum = 16;

    while (running) {
        short tile = keep_menu_tile(0x821);
        if (!(running = keep_control_running(run_menu_loop(
                &control_limits_selection, 3,
                keep_menu_tile_after_arguments(tile, &control_limits_selection, 3, control_limits_title),
                control_limits_title, limits_entries))))
            continue;
        if (((ControlMenuItem *)limits_entries[0])->value < 3)
            ((ControlMenuItem *)limits_entries[0])->value = 3;
        if (((ControlMenuItem *)limits_entries[1])->value < 3)
            ((ControlMenuItem *)limits_entries[1])->value = 3;
        /* The original publishes the scaled limit before subtracting one. */
        strafe_limit = ((ControlMenuItem *)limits_entries[0])->value << 4;
        {
            long limit = keep_strafe_limit(strafe_limit) - 1;
            ControlMenuItem *item = (ControlMenuItem *)limits_entries[1];
            strafe_limit = limit;
            strafe_step = item->value;
        }
        switch (control_limits_selection) {
        case 0:
        case 1:
            break;
        case 2:
            running = keep_control_running(0);
            break;
        }
    }
    return running;
}
