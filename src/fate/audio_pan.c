extern short audio_listener_index, audio_listener_angles[];
extern long audio_listener_x[], audio_listener_y[];
/* Watcom register annotations preserve the original calculation order. */
extern int hold_initial_listener(int);
#pragma aux hold_initial_listener = "" parm [eax] value [eax] modify exact [];
extern int hold_listener_for_angle(int);
#pragma aux hold_listener_for_angle = "" parm [ecx] value [ecx] modify exact [];
extern int hold_unscaled_angle(int);
#pragma aux hold_unscaled_angle = "" parm [edx] value [edx] modify exact [];
extern short get_angle_low(long, long);
#pragma aux get_angle_low "getangle_" modify exact [eax edx];

extern long hold_y_delta(long);
#pragma aux hold_y_delta = "" parm [esi] value [esi] modify exact [];
extern long hold_input_x(long);
#pragma aux hold_input_x = "" parm [ebx] value [ebx] modify exact [];
long audio_pan(long x, long y)
{
    long prior_x = hold_input_x(x);
    int listener = hold_initial_listener(audio_listener_index);
    long y_delta = hold_y_delta(audio_listener_y[listener]);
    int listener_for_angle = hold_listener_for_angle(listener);
    int angle;
    short measured;
    long x_delta;
    long pan;
    long scaled;
    y_delta -= y;
    x_delta = audio_listener_x[listener] - prior_x;
    measured = get_angle_low(x_delta, y_delta);
    angle = (short)((measured - audio_listener_angles[listener_for_angle]) & 2047);
    scaled = hold_unscaled_angle(angle) * 64L;
    if (angle > 1024) {
        if (angle <= 1536)
            pan = scaled - 32768;
        else
            pan = (2048 - angle) * 64L + 32768;
        if ((unsigned long)pan > 65535)
            return 65535;
    } else {
        if (angle >= 512)
            pan = 32768 - (1024 - angle) * 64L;
        else
            pan = 32768 - scaled;
        if ((unsigned long)pan > 32768)
            pan = 0;
    }
    return pan;
}

extern unsigned long audio_pan_table[];
extern int getangle(long x, long y);
#pragma aux getangle modify exact [eax edx];

/* These Watcom register annotations preserve the original signed test and
 * register allocation without emitting any instructions. */
extern int keep_pan_angle(int);
#pragma aux keep_pan_angle = "" parm [eax] value [eax] modify exact [];
extern int keep_offset(int);
#pragma aux keep_offset = "" parm [esi] value [esi] modify exact [];
extern int keep_listener_index(int);
#pragma aux keep_listener_index = "" parm [edx] value [edx] modify exact [];

long audio_sprite_pan(long x, long y)
{
    int listener = keep_listener_index(audio_listener_index);
    int offset = keep_offset(2047);
    int pan_index;
    offset -= keep_pan_angle(audio_listener_angles[listener]);
    pan_index = (getangle(audio_listener_x[listener] - x,
                          audio_listener_y[listener] - y) + offset) & 2047;
    pan_index = keep_pan_angle(pan_index) >> 6;
    if (pan_index < 0 || pan_index > 35)
        pan_index = 13;
    return audio_pan_table[pan_index];
}
