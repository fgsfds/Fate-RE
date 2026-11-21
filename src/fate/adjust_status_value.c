extern short difficulty_divisor, status_left_tenths;
extern long status_right_tenths;
extern const char invalid_difficulty_message[];
extern void report_game_error(const char *);
#pragma aux report_game_error modify exact [eax];
extern void start_negative_delta_effect(int);
#pragma aux start_negative_delta_effect modify exact [eax];

/* These identities preserve the original Watcom register assignments. */
extern short keep_delta(short);
#pragma aux keep_delta = "" parm [dx] value [dx] modify exact [];
extern long keep_status_right(long);
#pragma aux keep_status_right = "" parm [ebx] value [ebx] modify exact [];
extern short keep_status_left(short);
#pragma aux keep_status_left = "" parm [cx] value [cx] modify exact [];
extern long keep_updated_right(long);
#pragma aux keep_updated_right = "" parm [esi] value [esi] modify exact [];
extern int keep_updated_left(int);
#pragma aux keep_updated_left = "" parm [edx] value [edx] modify exact [];
extern long keep_current_right(long);
#pragma aux keep_current_right = "" parm [ecx] value [ecx] modify exact [];
extern long keep_next_right(long);
#pragma aux keep_next_right = "" parm [ecx] value [ecx] modify exact [];
extern long incoming_status_accumulator(void);
#pragma aux incoming_status_accumulator = "" value [eax] modify exact [];
extern void keep_status_accumulator(long);
#pragma aux keep_status_accumulator = "" parm [eax] modify exact [];
extern short keep_zero_left(short);
#pragma aux keep_zero_left = "" parm [di] value [di] modify exact [];

void adjust_status_value(short);
#pragma aux adjust_status_value modify exact [eax];
void adjust_status_value(short delta)
{
    int scaled;
    short reserve;

    delta = keep_delta(delta);

    if ((int)difficulty_divisor < 1)
        report_game_error(invalid_difficulty_message);
    if (delta < 0) {
        long prior = incoming_status_accumulator();
        long current = keep_status_right(status_right_tenths);
        keep_status_accumulator(prior);
        if (current < 0) {
            if (current < -1)
                status_right_tenths = -1;
            return;
        }
    }

    scaled = delta / (int)difficulty_divisor;
    start_negative_delta_effect((short)scaled);
    reserve = keep_status_left(status_left_tenths);
    if (reserve > 0 && (short)scaled < 0) {
        int half = ((short)scaled) >> 1;
        long current = keep_updated_right(status_right_tenths);
        current = keep_updated_right(current + half);
        reserve = keep_updated_left((int)reserve + half);
        status_right_tenths = current;
        status_left_tenths = reserve;
        if (reserve < 0)
            status_left_tenths = keep_zero_left(0);
    } else {
        long current = keep_current_right(status_right_tenths);
        current = keep_next_right(current + (short)scaled);
        status_right_tenths = current;
    }

    if (status_right_tenths > 1000)
        status_right_tenths = 1000;
}
