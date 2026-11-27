/* One-shot mode toggle and availability-driven local input selection. */
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

void collect_input_selection(void)
{
    unsigned char toggle_key;
    long enabled;

    if (input_mode)
        return;

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
