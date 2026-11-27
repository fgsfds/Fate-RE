/* Local input mode, selection, and mouse and keyboard motion. */
extern unsigned char input_mode, key_toggle_mode, toggled_mode;
extern unsigned char key_state[256];
extern short selection_1_enabled, selection_2_enabled, selection_3_enabled;
extern short selection_4_enabled, selection_5_enabled, selection_6_enabled;
extern short selection_7_enabled;
extern short selection_2_stock, selection_2_alternate_stock, selection_3_stock;
extern short selection_4_stock, selection_5_stock, selection_6_stock;
extern short selection_7_stock;
extern long selection;

/* These identities preserve their arguments and the other register bits. */
extern unsigned char input_selection_in_dh(unsigned char);
extern unsigned char input_selection_in_cl(unsigned char);
extern unsigned char input_selection_in_al(unsigned char);
extern unsigned char input_selection_in_dl(unsigned char);
extern unsigned char input_selection_in_bl(unsigned char);
extern long input_selection_in_edx(long);
extern long input_selection_in_eax(long);
#pragma aux input_selection_in_dh = "" parm [dh] value [dh] modify exact [];
#pragma aux input_selection_in_cl = "" parm [cl] value [cl] modify exact [];
#pragma aux input_selection_in_al = "" parm [al] value [al] modify exact [];
#pragma aux input_selection_in_dl = "" parm [dl] value [dl] modify exact [];
#pragma aux input_selection_in_bl = "" parm [bl] value [bl] modify exact [];
#pragma aux input_selection_in_edx = "" parm [edx] value [edx] modify exact [];
#pragma aux input_selection_in_eax = "" parm [eax] value [eax] modify exact [];


extern unsigned char key_strafe, key_left, key_right, key_toggle_word, key_reset_view;
extern long keyboard_turn, keyboard_strafe, strafe_step, strafe_limit;
extern unsigned short toggled_word;
extern long view_adjustment;

/* These identities constrain only the register of their unchanged value. */
extern unsigned long input_motion_in_ebx(unsigned long);
extern long input_motion_in_ecx(long);
extern unsigned char input_motion_in_bh(unsigned char);
#pragma aux input_motion_in_ebx = "" parm [ebx] value [ebx] modify exact [];
#pragma aux input_motion_in_ecx = "" parm [ecx] value [ecx] modify exact [];
#pragma aux input_motion_in_bh = "" parm [bh] value [bh] modify exact [];

extern unsigned char key_forward, key_backward, key_strafe_left, key_strafe_right;
extern short mouse_dx, mouse_dy, mouse_buttons;
extern unsigned short active_mouse_buttons;
extern long keyboard_forward;
extern signed char input_forward, input_strafe, input_turn;

extern int getmousevalues(short *, short *, short *);
extern void scale_mouse(short *, short *);

/* These identities leave the supplied values and all other register bits intact. */
extern unsigned short input_mouse_in_ax(unsigned short);
extern short input_mouse_in_cx(short);
extern long input_motion_in_esi(long);
extern long input_motion_in_edi(long);
#pragma aux input_mouse_in_ax = "" parm [ax] value [ax] modify exact [];
#pragma aux input_mouse_in_cx = "" parm [cx] value [cx] modify exact [];
#pragma aux input_motion_in_esi = "" parm [esi] value [esi] modify exact [];
#pragma aux input_motion_in_edi = "" parm [edi] value [edi] modify exact [];

void collect_input_mouse(void)
{
    unsigned char toggle_key;
    long enabled;
    long key, motion, limit;
    unsigned long step;

    if (!input_mode) {
        toggle_key = key_toggle_mode;
        if (key_state[toggle_key] != 0) {
            key_state[toggle_key] = input_selection_in_dh(0);
            toggled_mode ^= 1;
        }

        if (key_state[2] > 0) {
            key_state[2] = input_selection_in_cl(0);
            selection = input_selection_in_edx(0);
        }
        if (key_state[3] > 0) {
            key_state[3] = input_selection_in_al(0);
            enabled = input_selection_in_eax(selection_1_enabled);
            if (enabled == 1)
                selection = enabled;
        }
        if (key_state[4] > 0) {
            key_state[4] = input_selection_in_dl(0);
            if (input_selection_in_eax(selection_2_enabled) == 1 &&
                (selection_2_stock > 0 || selection_2_alternate_stock > 0))
                selection = 2;
        }
        if (key_state[5] > 0) {
            key_state[5] = input_selection_in_bl(0);
            if (input_selection_in_eax(selection_3_enabled) == 1 && selection_3_stock > 0)
                selection = 3;
        }
        if (key_state[6] > 0) {
            key_state[6] = input_selection_in_cl(0);
            if (input_selection_in_eax(selection_4_enabled) == 1 && selection_4_stock > 0)
                selection = 4;
        }
        if (key_state[7] > 0) {
            key_state[7] = input_selection_in_al(0);
            if (input_selection_in_eax(selection_5_enabled) == 1 && selection_5_stock > 0)
                selection = 5;
        }
        if (key_state[8] > 0) {
            key_state[8] = input_selection_in_dl(0);
            if (input_selection_in_eax(selection_6_enabled) == 1 && selection_6_stock > 0)
                selection = 6;
        }
        if (key_state[9] > 0) {
            key_state[9] = input_selection_in_bl(0);
            if (input_selection_in_eax(selection_7_enabled) == 1 && selection_7_stock > 0)
                selection = 7;
        }
    }

    /* Watcom interprets the wrapped 32-bit values as signed for the clamps. */
    if (key_state[input_selection_in_eax(key_strafe)] == 0) {
        if (key_state[input_selection_in_eax(key_left)] > 0) {
            motion = input_selection_in_eax((long)((unsigned long)keyboard_turn - 48UL));
            if (motion <= -128)
                motion = -128;
            keyboard_turn = input_selection_in_eax(motion);
        }
        if (key_state[input_selection_in_eax(key_right)] > 0) {
            motion = input_selection_in_eax((long)((unsigned long)keyboard_turn + 48UL));
            if (motion >= 127)
                motion = 127;
            keyboard_turn = input_selection_in_eax(motion);
        }
    } else {
        if (key_state[input_selection_in_eax(key_left)] > 0) {
            step = input_motion_in_ebx((unsigned long)strafe_step);
            motion = input_selection_in_eax((long)((step << 2) - step));
            limit = input_motion_in_ecx(strafe_limit);
            motion = (long)((unsigned long)motion + input_motion_in_ebx((unsigned long)keyboard_strafe));
            if (motion >= limit)
                motion = limit;
            keyboard_strafe = input_selection_in_eax(motion);
        }
        if (key_state[input_selection_in_eax(key_right)] > 0) {
            step = input_motion_in_ebx((unsigned long)strafe_step);
            motion = input_selection_in_eax((long)((step << 2) - step));
            motion = input_selection_in_eax((long)(input_motion_in_ebx((unsigned long)keyboard_strafe) -
                                                   (unsigned long)motion));
            limit = (long)input_motion_in_ebx(0UL - (unsigned long)strafe_limit);
            if (motion <= limit)
                motion = limit;
            keyboard_strafe = input_selection_in_eax(motion);
        }
    }

    key = input_selection_in_eax(key_toggle_word);
    if (input_motion_in_ebx(key_state[key]) == 1) {
        key_state[key] = input_selection_in_bl(0);
        toggled_word = (unsigned short)~toggled_word;
    }

    key = input_selection_in_eax(key_reset_view);
    if (input_motion_in_ebx(key_state[key]) == 1) {
        key_state[key] = input_motion_in_bh(0);
        view_adjustment = 100;
    }

    mouse_buttons = input_mouse_in_cx(0);
    getmousevalues(&mouse_dx, &mouse_dy, &mouse_buttons);
    scale_mouse(&mouse_dx, &mouse_dy);

    if (key_state[input_selection_in_eax(key_forward)] > 0 ||
        input_selection_in_eax((short)((unsigned char)input_mouse_in_ax(active_mouse_buttons) & 2U))) {
        long motion;

        motion = input_selection_in_eax((long)((unsigned long)keyboard_forward + 12UL));
        if (motion >= 127)
            motion = 127;
        keyboard_forward = input_selection_in_eax(motion);
    }
    if (key_state[input_selection_in_eax(key_backward)] > 0) {
        long motion;

        motion = input_selection_in_eax((long)((unsigned long)keyboard_forward - 12UL));
        if (motion <= -128)
            motion = -128;
        keyboard_forward = input_selection_in_eax(motion);
    }
    if (key_state[input_selection_in_eax(key_strafe_left)] > 0) {
        long motion;
        unsigned long step;
        long limit;
        long next;

        step = input_motion_in_ebx((unsigned long)strafe_step);
        motion = input_selection_in_eax((long)((step << 2) - step));
        next = input_motion_in_edi(keyboard_strafe);
        limit = strafe_limit;
        motion = (long)((unsigned long)motion + (unsigned long)next);
        if (motion >= limit)
            motion = limit;
        keyboard_strafe = input_selection_in_eax(motion);
    }
    if (key_state[input_selection_in_eax(key_strafe_right)] > 0) {
        long motion;
        unsigned long step;
        long limit;

        step = input_motion_in_ebx((unsigned long)strafe_step);
        motion = input_selection_in_eax((long)((step << 2) - step));
        motion = input_selection_in_eax((long)(input_motion_in_ebx((unsigned long)keyboard_strafe) -
                                               (unsigned long)motion));
        limit = (long)input_motion_in_ebx(0UL - (unsigned long)strafe_limit);
        if (motion <= limit)
            motion = limit;
        keyboard_strafe = input_selection_in_eax(motion);
    }

    {
        long motion = input_selection_in_eax(keyboard_turn);
        if (motion < 0) {
            motion = input_selection_in_eax((long)((unsigned long)motion + 36UL));
            if (motion >= 0)
                motion = 0;
            keyboard_turn = input_selection_in_eax(motion);
        }
    }

    {
        long next = input_selection_in_edx(keyboard_turn);
        if (next > 0) {
            long motion = input_selection_in_eax((long)((unsigned long)next - 36UL));
            if (motion <= 0)
                motion = 0;
            keyboard_turn = input_selection_in_eax(motion);
        }
    }

    {
        long next = (long)input_motion_in_ebx((unsigned long)keyboard_strafe);
        if (next < 0) {
            long motion = input_selection_in_eax((long)((unsigned long)next + 6UL));
            if (motion >= 0)
                motion = 0;
            keyboard_strafe = input_selection_in_eax(motion);
        }
    }

    {
        long next = input_motion_in_ecx(keyboard_strafe);
        if (next > 0) {
            long motion = input_selection_in_eax((long)((unsigned long)next - 6UL));
            if (motion <= 0)
                motion = 0;
            keyboard_strafe = input_selection_in_eax(motion);
        }
    }

    {
        long next = input_motion_in_esi(keyboard_forward);
        if (next < 0) {
            long motion = input_selection_in_eax((long)((unsigned long)next + 6UL));
            if (motion >= 0)
                motion = 0;
            keyboard_forward = input_selection_in_eax(motion);
        }
    }

    {
        long next = input_motion_in_edi(keyboard_forward);
        if (next > 0) {
            long motion = input_selection_in_eax((long)((unsigned long)next - 6UL));
            if (motion <= 0)
                motion = 0;
            keyboard_forward = input_selection_in_eax(motion);
        }
    }

    {
        long strafe_sample, turn_sample;

        {
            /* The upper-bound test uses a lower-clamped value. The low arm samples
               the accumulator again, matching the original nested clamps. */
            long next = keyboard_forward;
            long motion = input_selection_in_eax(next > -120 ? next : -120);
            if (motion < 119) {
                next = input_selection_in_eax(keyboard_forward);
                motion = input_selection_in_eax(next > -120 ? next : -120);
            } else {
                motion = 119;
            }
            strafe_sample = input_selection_in_edx(keyboard_strafe);
            input_forward = (signed char)input_selection_in_al((unsigned char)motion);
        }

        {
            long next = strafe_sample;
            long motion = input_selection_in_eax(next > -120 ? next : -120);
            if (motion < 119) {
                next = (long)input_motion_in_ebx((unsigned long)keyboard_strafe);
                motion = input_selection_in_eax(next > -120 ? next : -120);
            } else {
                motion = 119;
            }
            turn_sample = input_motion_in_ecx(keyboard_turn);
            input_strafe = (signed char)input_selection_in_al((unsigned char)motion);
        }

        {
            long next = turn_sample;
            long motion = input_selection_in_eax(next > -112 ? next : -112);
            if (motion < 111) {
                next = input_motion_in_esi(keyboard_turn);
                motion = input_selection_in_eax(next > -112 ? next : -112);
            } else {
                motion = 111;
            }
            input_turn = (signed char)input_selection_in_al((unsigned char)motion);
        }
    }
}
