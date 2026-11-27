/* Apply the configured mouse action and release the previous synthetic key. */
extern int pending_mouse_action;
extern unsigned char mouse_button_bindings[], mouse_action_keys[], mouse_key_state[];
extern unsigned short previous_mouse_action, mouse_input_actions;

extern void keep_unassigned_action(int);
#pragma aux keep_unassigned_action = "" parm [ecx] modify exact [];
extern void keep_released_key(unsigned char);
#pragma aux keep_released_key = "" parm [dl] modify exact [];
extern int unassigned_action(void);
#pragma aux unassigned_action = value [ecx] modify exact [];
extern unsigned char released_key(void);
#pragma aux released_key = value [dl] modify exact [];
extern unsigned short mouse_buttons(void);
#pragma aux mouse_buttons = value [bx] modify exact [];
/* Empty auxiliaries expose register slices; all mask/extension instructions
 * below are emitted from C rather than inline instruction strings. */
extern unsigned binding_eax(void);
#pragma aux binding_eax = "" value [eax] modify exact [];
extern unsigned binding_ebx(void);
#pragma aux binding_ebx = "" value [ebx] modify exact [];
extern void keep_binding_eax(unsigned);
#pragma aux keep_binding_eax = "" parm [eax] modify exact [];
extern unsigned char binding_al(void);
#pragma aux binding_al = "" value [al] modify exact [];
extern unsigned char binding_ah(void);
#pragma aux binding_ah = "" value [ah] modify exact [];
extern unsigned char binding_bh(void);
#pragma aux binding_bh = "" value [bh] modify exact [];
extern void keep_binding_al(unsigned char);
#pragma aux keep_binding_al = "" parm [al] modify exact [];
extern void keep_binding_ah(unsigned char);
#pragma aux keep_binding_ah = "" parm [ah] modify exact [];
extern void keep_binding_bh(unsigned char);
#pragma aux keep_binding_bh = "" parm [bh] modify exact [];
extern short binding_ax(void);
#pragma aux binding_ax = "" value [ax] modify exact [];
extern void keep_binding_ax(unsigned short);
#pragma aux keep_binding_ax = "" parm [ax] modify exact [];
extern void set_button_index(int);
#pragma aux set_button_index = "" parm [ebx] modify exact [ebx];

extern void set_action_index(int);
#pragma aux set_action_index = "" parm [eax] modify exact [eax];
extern int current_action(void);
#pragma aux current_action = value [eax] modify exact [];
extern void start_key_index(unsigned);
#pragma aux start_key_index = "" parm [edx] modify exact [edx];
extern void set_key_index_low(unsigned char);
#pragma aux set_key_index_low = "" parm [dl] modify exact [];
extern unsigned key_index_in_edx(void);
#pragma aux key_index_in_edx = value [edx] modify exact [];
extern void set_pressed_value(unsigned char);
#pragma aux set_pressed_value = "" parm [bl] modify exact [ebx];
extern unsigned char pressed_value(void);
#pragma aux pressed_value = value [bl] modify exact [];

extern unsigned char edge_in_al(unsigned char);
#pragma aux edge_in_al = parm [al] value [al] modify exact [];
extern void keep_resulting_action_bits(unsigned short);
#pragma aux keep_resulting_action_bits = "" parm [dx] modify exact [];
extern unsigned short resulting_action_bits(void);
#pragma aux resulting_action_bits = value [dx] modify exact [];
void apply_mouse_button_binding(unsigned);
#pragma aux apply_mouse_button_binding modify exact [eax];
void apply_mouse_button_binding(unsigned buttons)
{
    int pending, key, edge, old_edge, handled;
    unsigned code;

    set_button_index(buttons);
    start_key_index(pending_mouse_action);
    pending = key_index_in_edx();
    if (pending != -1) {
        keep_binding_al(mouse_action_keys[key_index_in_edx()]);
        keep_unassigned_action(-1);
        keep_binding_eax(binding_eax() & 255UL);
        keep_released_key(0);
        code = binding_eax();
        pending_mouse_action = unassigned_action();
        mouse_key_state[code] = released_key();
    }
    if (!mouse_buttons())
        goto done;

    keep_binding_eax(binding_ebx());
    keep_binding_ah(binding_ah() ^ binding_bh());
    keep_binding_al(binding_al() & 1);
    keep_binding_eax(binding_ax());
    if (binding_eax())
        set_button_index(0);
    else {
        keep_binding_bh(0);
        set_pressed_value(pressed_value() & 2);
        keep_binding_eax((short)mouse_buttons());
        if (binding_eax())
            set_button_index(2);
        else
            set_button_index(1);
    }

    set_action_index(0);
    do {
        start_key_index((short)mouse_buttons());
        set_key_index_low(mouse_button_bindings[key_index_in_edx()]);
        start_key_index(key_index_in_edx() & 255UL);
        if (key_index_in_edx() != current_action())
            goto advance;

        /* Equal indices cancel, leaving the mapped key in a zero-extended register. */
        start_key_index(key_index_in_edx() ^ current_action());
        set_key_index_low(mouse_action_keys[current_action()]);
        key = key_index_in_edx();
        if (key == 6 || key == 18)
            goto keypress;

        keep_binding_eax(binding_ebx());
        keep_binding_ah(binding_ah() ^ binding_bh());
        keep_binding_al(binding_al() & 1);
        start_key_index(binding_ax());
        edge = key_index_in_edx();
        keep_binding_ax(previous_mouse_action);
        keep_binding_ah(0);
        keep_binding_al(binding_al() & 1);
        keep_binding_eax(binding_ax());
        old_edge = binding_eax();
        edge_in_al(edge > old_edge);
        keep_binding_ah(0);
        keep_resulting_action_bits(mouse_input_actions);
        keep_binding_eax(binding_eax() << 11);
        start_key_index(key_index_in_edx() | binding_eax());
        keep_binding_eax(key_index_in_edx());
        keep_binding_al(binding_al() ^ released_key());
        keep_binding_ah(binding_ah() & 8);
        previous_mouse_action = mouse_buttons();
        keep_binding_eax(binding_ax());
        handled = binding_eax();
        mouse_input_actions = resulting_action_bits();
        if (handled <= 0)
            goto done;
        set_pressed_value(pressed_value() & 0xfe);
        previous_mouse_action = mouse_buttons();
        return;

keypress:
        start_key_index(0);
        set_key_index_low(mouse_action_keys[current_action()]);
        code = key_index_in_edx();
        set_pressed_value(1);
        pending_mouse_action = current_action();
        mouse_key_state[code] = pressed_value();
        return;

advance:
        set_action_index(current_action() + 1);
    } while (current_action() < 25);

done:
    return;
}
