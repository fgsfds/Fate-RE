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


/* Cursor coordinates and mouse-derived view controls. */
extern unsigned char cursor_mode, key_adjust_view, adjust_view_held;
extern short cursor_x, cursor_y, map_mode, map_x, map_scale_or_y, map_offset_y;
extern short mouse_motion_disabled, mouse_history_index;
/* The linker binds this view to the start of the LE DATA object. */
extern volatile short input_cursor_data_words[0x28a300UL / sizeof(short)];
extern short smoothed_mouse_dx;

/* The sign extension is expressed at the use site. These calls only select
   the register for the unchanged word, byte or long value. */
extern short input_cursor_in_ax(short);
extern short input_cursor_in_bx(short);
extern short input_cursor_in_dx(short);
extern short input_cursor_in_si(short);
extern short input_cursor_in_di(short);
extern unsigned char input_cursor_in_ch(unsigned char);
extern long input_cursor_in_ebx(long);
#pragma aux input_cursor_in_ax = "" parm [ax] value [ax] modify exact [];
#pragma aux input_cursor_in_bx = "" parm [bx] value [bx] modify exact [];
#pragma aux input_cursor_in_dx = "" parm [dx] value [dx] modify exact [];
#pragma aux input_cursor_in_si = "" parm [si] value [si] modify exact [];
#pragma aux input_cursor_in_di = "" parm [di] value [di] modify exact [];
#pragma aux input_cursor_in_ch = "" parm [ch] value [ch] modify exact [];
#pragma aux input_cursor_in_ebx = "" parm [ebx] value [ebx] modify exact [];


void collect_input_cursor_context(void)
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


    {
        short horizontal, vertical;

        if (cursor_mode != 0 || map_mode != 0) {
            short mode = input_cursor_in_si(map_mode);
            horizontal = (short)input_selection_in_edx(0);
            vertical = (short)input_selection_in_eax(0);
            active_mouse_buttons = (unsigned short)input_cursor_in_dx(horizontal);
            if (mode == 0) {
                short delta = input_cursor_in_bx(mouse_dx);
                short x = input_cursor_in_di(cursor_x);
                short y = input_mouse_in_cx(cursor_y);
                long position;

                x = input_cursor_in_di((short)((unsigned short)x + (unsigned short)delta));
                delta = input_cursor_in_bx(mouse_dy);
                cursor_x = x;
                y = input_mouse_in_cx((short)((unsigned short)y + (unsigned short)delta));
                position = input_cursor_in_ebx(x);
                cursor_y = y;
                position = position > 316 ? position : 316;
                if (position < 988) {
                    position = input_cursor_in_ebx(cursor_x);
                    if (position <= 316)
                        position = input_cursor_in_ebx(316L);
                } else {
                    position = input_cursor_in_ebx(988L);
                }
                cursor_x = (short)input_cursor_in_ebx(position);

                position = input_cursor_in_ebx(cursor_y);
                position = position > 364 ? position : 364;
                if (position < 440) {
                    position = input_cursor_in_ebx(cursor_y);
                    if (position <= 364)
                        position = input_cursor_in_ebx(364L);
                } else {
                    position = input_cursor_in_ebx(440L);
                }
                cursor_y = (short)input_cursor_in_ebx(position);

                /* This Watcom target uses arithmetic right shifts for signed longs. */
                position = input_cursor_in_ebx(cursor_x);
                position = input_cursor_in_ebx(position >> 2);
                map_x = input_cursor_in_bx((short)position);
                position = input_cursor_in_ebx(cursor_y);
                position = input_cursor_in_ebx(position >> 2);
                map_scale_or_y = input_cursor_in_bx((short)position);

                if ((unsigned short)input_cursor_in_bx(mouse_buttons) & 2U)
                    cursor_mode = input_motion_in_bh(0);
            } else if (!((unsigned short)input_cursor_in_bx(mouse_buttons) & 2U)) {
                short delta = input_cursor_in_bx(mouse_dx);
                short x = input_mouse_in_cx(map_x);
                short scale = input_cursor_in_si(map_scale_or_y);
                long position, bound, minimum;

                x = input_mouse_in_cx((short)((unsigned short)x - (unsigned short)delta));
                scale = input_cursor_in_si((short)((unsigned short)scale - (unsigned short)mouse_dy));
                map_x = x;
                position = input_cursor_in_ebx(scale);
                map_scale_or_y = scale;
                position = position > 256 ? position : 256;
                if (position < 2048) {
                    position = input_cursor_in_ebx(map_scale_or_y);
                    if (position <= 256)
                        position = input_cursor_in_ebx(256L);
                } else {
                    position = input_cursor_in_ebx(2048L);
                }
                scale = (short)input_cursor_in_ebx(position);
                map_scale_or_y = scale;

                position = input_cursor_in_ebx(scale);
                bound = input_motion_in_ecx(position);
                bound = input_motion_in_ecx(bound >> 3);
                position = input_cursor_in_ebx(position - bound);
                minimum = input_motion_in_esi((short)position);
                bound = input_motion_in_ecx(map_x);
                minimum = input_motion_in_esi(-minimum);
                if (bound <= minimum)
                    bound = minimum;
                position = input_cursor_in_ebx((short)position);
                if (bound < position) {
                    bound = input_motion_in_ecx(map_x);
                    position = input_cursor_in_ebx(-position);
                    if (bound > position)
                        position = bound;
                }
                map_x = input_cursor_in_bx((short)position);
            } else {
                short delta = input_cursor_in_bx(mouse_dy);
                short offset = input_cursor_in_di(map_offset_y);
                long position;

                offset = input_cursor_in_di((short)((unsigned short)offset + (unsigned short)delta));
                position = input_cursor_in_ebx(offset);
                map_offset_y = offset;
                position = position > -256 ? position : -256;
                if (position < 256) {
                    position = input_cursor_in_ebx(map_offset_y);
                    if (position <= -256)
                        position = input_cursor_in_ebx(-256L);
                } else {
                    position = input_cursor_in_ebx(256L);
                }
                map_offset_y = (short)input_cursor_in_ebx(position);
            }
        } else {
            short buttons;

            if (mouse_motion_disabled == 0) {
                horizontal = input_cursor_in_dx(mouse_dx);
                buttons = input_cursor_in_bx(mouse_buttons);
                vertical = input_cursor_in_ax(mouse_dy);
            } else {
                horizontal = (short)input_selection_in_edx(0);
                buttons = (short)input_motion_in_bh(0);
                vertical = (short)input_selection_in_eax(0);
            }
            active_mouse_buttons = (unsigned short)input_cursor_in_bx(buttons);
        }

        if (input_cursor_in_ebx(key_state[input_cursor_in_ebx(key_adjust_view)]) == 1) {
            adjust_view_held = 1;
        } else if (input_cursor_in_ebx(adjust_view_held) == 1) {
            unsigned char released = input_selection_in_cl(0);
            long centered = input_motion_in_edi(100);

            adjust_view_held = released;
            view_adjustment = centered;
        }

        if (key_state[input_cursor_in_ebx(key_strafe)] == 0) {
            unsigned char held;

            {
                short next = input_cursor_in_di(mouse_history_index);
                long index;
                long sample, sum;

                next = input_cursor_in_di((short)((unsigned short)next + 1U));
                index = input_cursor_in_ebx(next);
                mouse_history_index = next;
                if (index > 3) {
                    index = input_cursor_in_ebx(0);
                    mouse_history_index = input_cursor_in_bx((short)index);
                }
                /* Negative indices address DATA before the four history samples. */
                index = input_cursor_in_ebx(mouse_history_index);
                input_cursor_data_words[index + 0x42949L] = input_cursor_in_dx(horizontal);
                sample = input_cursor_in_ebx(input_cursor_data_words[0x42949L + 1]);
                sum = input_motion_in_ecx(input_cursor_data_words[0x42949L + 0]);
                sample = input_cursor_in_ebx(sample + sum);
                sum = input_motion_in_ecx(input_cursor_data_words[0x42949L + 2]);
                sum = input_motion_in_ecx(sum + sample);
                sample = input_cursor_in_ebx(input_cursor_data_words[0x42949L + 3]);
                sample = input_cursor_in_ebx((sample + sum) >> 2);
                held = input_cursor_in_ch(adjust_view_held);
                smoothed_mouse_dx = input_cursor_in_bx((short)sample);
            }

            if (held != 0) {
                if (vertical > 0) {
                    long adjustment = input_cursor_in_ebx(view_adjustment);
                    adjustment = input_cursor_in_ebx((long)((unsigned long)adjustment + 4UL));
                    view_adjustment = adjustment;
                    if (adjustment > 200)
                        view_adjustment = 200;
                } else if (vertical < 0) {
                    long adjustment = view_adjustment;
                    adjustment = (long)((unsigned long)adjustment - 4UL);
                    view_adjustment = adjustment;
                    if (adjustment < 0)
                        view_adjustment = input_selection_in_edx(0);
                }
            } else {
                long delta = input_motion_in_ecx(input_cursor_in_ax(vertical));
                long motion = input_cursor_in_ebx(input_forward);

                delta = input_motion_in_ecx(delta * 8L);
                motion = input_cursor_in_ebx(motion - delta);
                motion = motion > -128 ? motion : -128;
                if (motion < 127) {
                    delta = input_cursor_in_ebx(input_selection_in_eax(input_cursor_in_ax(vertical)));
                    motion = input_selection_in_eax(input_forward);
                    delta = input_cursor_in_ebx(delta * 8L);
                    motion = input_selection_in_eax(motion - delta);
                    if (motion <= -128)
                        motion = -128;
                } else {
                    motion = 127;
                }
                input_forward = (signed char)input_selection_in_al((unsigned char)motion);
            }
        } else {
            long delta = input_cursor_in_ebx(input_cursor_in_dx(horizontal));
            long motion = input_selection_in_eax(input_turn);
            short reset;

            delta = input_cursor_in_ebx(delta * 8L);
            reset = (short)input_motion_in_esi(0);
            motion = input_selection_in_eax(motion - delta);
            smoothed_mouse_dx = input_cursor_in_si(reset);
            motion = motion > -128 ? motion : -128;
            if (motion < 127) {
                delta = input_selection_in_eax(input_cursor_in_dx(horizontal));
                motion = input_cursor_in_ebx(input_turn);
                delta = input_selection_in_eax(delta * 8L);
                motion = input_cursor_in_ebx(motion - delta);
                if (motion <= -128)
                    motion = -128;
            } else {
                motion = 127;
            }
            delta = input_selection_in_eax(input_strafe);
            input_strafe = (signed char)input_selection_in_al((unsigned char)(delta + motion));
        }
    }

}
