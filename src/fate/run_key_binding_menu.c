extern unsigned char key_blank_name[];
extern unsigned char key_menu_row_format[];
extern unsigned char key_menu_title[];
extern unsigned char key_menu_prompt[];
extern unsigned char key_menu_rejected[];
extern unsigned char key_scan_names[];
extern unsigned char key_action_labels[];
extern unsigned char key_bindings_one_based[];
extern unsigned char key_forward[];
extern unsigned char key_entries_one_based[];
extern unsigned char key_entries[];
extern unsigned char key_menu_selection[];
extern unsigned char key_menu_rows[];
extern void play_sound(void);
#pragma aux play_sound modify exact [eax];
extern void presentation_input(void);
#pragma aux presentation_input modify exact [eax];
extern void draw_menu_frame(void);
#pragma aux draw_menu_frame modify exact [eax];
extern void run_menu_loop(void);
#pragma aux run_menu_loop modify exact [eax];
extern void validate_key_binding(void);
#pragma aux validate_key_binding modify exact [eax];
extern void format_string(void);
#pragma aux format_string modify exact [eax];
extern void format_menu_row(long, long, long, long);
#pragma aux format_menu_row "format_string_" parm caller [] modify exact [eax];
extern long get_eax(void);
#pragma aux get_eax = "" value [eax] modify exact [];
extern long put_eax(long);
#pragma aux put_eax = "" parm [eax] value [eax] modify exact [];
extern long get_ebx(void);
#pragma aux get_ebx = "" value [ebx] modify exact [];
extern long put_ebx(long);
#pragma aux put_ebx = "" parm [ebx] value [ebx] modify exact [];
extern long get_ecx(void);
#pragma aux get_ecx = "" value [ecx] modify exact [];
extern long put_ecx(long);
#pragma aux put_ecx = "" parm [ecx] value [ecx] modify exact [];
extern long get_edx(void);
#pragma aux get_edx = "" value [edx] modify exact [];
extern long put_edx(long);
#pragma aux put_edx = "" parm [edx] value [edx] modify exact [];
extern long get_esi(void);
#pragma aux get_esi = "" value [esi] modify exact [];
extern long put_esi(long);
#pragma aux put_esi = "" parm [esi] value [esi] modify exact [];
extern long get_edi(void);
#pragma aux get_edi = "" value [edi] modify exact [];
extern long put_edi(long);
#pragma aux put_edi = "" parm [edi] value [edi] modify exact [];
extern long get_ebp(void);
#pragma aux get_ebp = "" value [ebp] modify exact [];
extern unsigned char get_al(void);
#pragma aux get_al = "" value [al] modify exact [];
extern unsigned char put_al(unsigned char);
#pragma aux put_al = "" parm [al] value [al] modify exact [];
extern unsigned char put_dl(unsigned char);
#pragma aux put_dl = "" parm [dl] value [dl] modify exact [];
extern short get_si(void);
#pragma aux get_si = "" value [si] modify exact [];

/* Watcom owns the five other register saves/restores and RET. Keep EBP
   manual and retain conservative clobbers so initialization stays after PUSH. */
extern void preserve_menu_registers(void);
#pragma aux preserve_menu_registers = "push ebp" modify exact [ebx ecx edx esi edi];
extern int release_menu_registers(int);
#pragma aux release_menu_registers = "pop ebp" parm [eax] value [eax] modify exact [];
extern void push_menu_arg(long);
#pragma aux push_menu_arg = "" parm routine [] modify exact [];
extern void push_menu_rows(long);
#pragma aux push_menu_rows = "" parm routine [] modify exact [eax ebx ecx edx];
extern void keep_row_offset(long);
#pragma aux keep_row_offset = "" parm [eax] modify exact [edx];
extern void keep_format_index_in_esi(long);
#pragma aux keep_format_index_in_esi = "" parm [esi] modify exact [ebx edx];
extern void keep_format_index_in_ebx(long);
#pragma aux keep_format_index_in_ebx = "" parm [ebx] modify exact [edx];
extern void discard_format_args(void);
#pragma aux discard_format_args = "add esp,10h" modify exact [];
extern void load_selected_action_label(void);
#pragma aux load_selected_action_label = "mov ebp, dword ptr [eax*8 + key_action_labels]" modify exact [];
extern void remember_previous_binding(void);
#pragma aux remember_previous_binding = "mov ebp, [eax + 7]" modify exact [];

int run_key_binding_menu(void);
#pragma aux run_key_binding_menu modify exact [eax];
int run_key_binding_menu(void)
{
    preserve_menu_registers();
    put_ebx(0);
format_rows:
    /* Fill the display row and attach its current scan code. */
    put_eax(0);
    put_al(*(unsigned char *)(get_ebx() + (long)key_forward));
    put_edx(*(long *)(get_eax()*4 + (long)key_scan_names));
    put_eax(get_ebx());
    push_menu_arg(get_edx());
    put_eax(get_eax() << 0x4);
    put_ecx(*(long *)(get_ebx()*8 + (long)key_action_labels));
    keep_row_offset(put_eax(get_eax() - get_ebx()));
    push_menu_arg(get_ecx());
    put_eax(get_eax() + get_eax());
    push_menu_arg((long)key_menu_row_format);
    keep_row_offset(put_eax(get_eax() + (long)key_menu_rows));
    put_edx(get_ebx());
    push_menu_arg(get_eax());
    put_edx(get_edx() ^ get_ebx());
    put_ebx(get_ebx() + 1);
    format_string();
    put_eax(*(long *)(get_ebx()*4 + (long)key_entries_one_based));
    put_dl(*(unsigned char *)(get_ebx() + (long)key_bindings_one_based));
    discard_format_args();
    *(long *)(get_eax() + 0x7) = get_edx();
    if (get_ebx() < 0x19)
        goto format_rows;
    put_edi(0x1);
select_action:
    /* Redraw the selected row while the menu waits for a key. */
    if (get_edi() == 0)
        goto save_bindings;
    put_esi(0x83d);
    push_menu_rows((long)key_entries);
    put_ecx((long)key_menu_title);
    put_edx(0x19);
    put_eax((long)key_menu_selection);
    put_ebx(get_si());
    run_menu_loop();
    put_edi(get_eax());
    if (get_eax() == 0)
        goto select_action;
    put_eax(*(long *)((long)key_menu_selection));
    put_ebx(get_eax());
    load_selected_action_label();
    put_eax(get_eax() << 0x4);
    push_menu_arg((long)key_blank_name);
    put_eax(get_eax() - get_ebx());
    push_menu_arg(get_ebp());
    put_eax(get_eax() + get_eax());
    push_menu_arg((long)key_menu_row_format);
    put_eax(get_eax() + (long)key_menu_rows);
    push_menu_arg(get_eax());
    format_string();
    put_eax(*(long *)((long)key_menu_selection));
    put_eax(*(long *)(get_eax()*4 + (long)key_entries));
    discard_format_args();
    remember_previous_binding();
wait_for_key:
    presentation_input();
    put_ebx(get_eax());
    if (get_eax() != 0)
        goto validate_entry;
    push_menu_rows((long)key_entries);
    put_ecx((long)key_menu_prompt);
    put_edx(0x19);
    put_eax(*(long *)((long)key_menu_selection));
    put_ebx(get_si());
    draw_menu_frame();
    goto wait_for_key;
validate_entry:
    put_edx(*(long *)((long)key_menu_selection));
    validate_key_binding();
    if (get_eax() != 0x1)
        goto reject_binding;
    put_eax(get_ebx());
    put_ecx(*(long *)(get_eax()*4 + (long)key_scan_names));
    put_eax(*(long *)((long)key_menu_selection));
    push_menu_arg(get_ecx());
    put_esi(*(long *)(get_eax()*8 + (long)key_action_labels));
    push_menu_arg(get_esi());
    keep_format_index_in_esi(put_esi(get_eax()));
    put_eax(get_eax() << 0x4);
    put_eax(get_eax() - get_esi());
    put_eax(get_eax() + get_eax());
    push_menu_arg((long)key_menu_row_format);
    put_eax(get_eax() + (long)key_menu_rows);
    push_menu_arg(get_eax());
    format_string();
    put_eax(*(long *)((long)key_menu_selection));
    put_eax(*(long *)(get_eax()*4 + (long)key_entries));
    discard_format_args();
    *(long *)(get_eax() + 0x7) = get_ebx();
    goto select_action;
reject_binding:
    /* Restore the previous row after showing the rejection message. */
    put_eax(0x9d);
    put_ecx(0);
    put_ebx(0);
    put_edx(0);
    play_sound();
    push_menu_rows((long)key_entries);
    put_ecx((long)key_menu_rejected);
    put_edx(0x19);
    put_eax(*(long *)((long)key_menu_selection));
    put_ebx(get_si());
    draw_menu_frame();
    put_edx(*(long *)(get_ebp()*4 + (long)key_scan_names));
    put_eax(*(long *)((long)key_menu_selection));
    /* Caller cleanup is compiler-generated here; the other sites deliberately
     * defer it until after their selected-entry loads. */
    format_menu_row(
        (put_eax(get_eax() + (long)key_menu_rows), get_eax()),
        (keep_format_index_in_ebx(put_ebx(get_eax())),
         put_eax(get_eax() << 0x4), put_eax(get_eax() - get_ebx()),
         put_eax(get_eax() + get_eax()), (long)key_menu_row_format),
        (put_ebx(*(long *)(get_eax()*8 + (long)key_action_labels)), get_ebx()),
        get_edx());
    goto select_action;
save_bindings:
    /* Write the row scan codes back to the live bindings. */
    put_ebx(0);
copy_binding:
    put_eax(*(long *)(get_ebx()*4 + (long)key_entries));
    put_ebx(get_ebx() + 1);
    put_al(*(unsigned char *)(get_eax() + 0x7));
    *(unsigned char *)(get_ebx() + (long)key_bindings_one_based) = get_al();
    if (get_ebx() < 0x19)
        goto copy_binding;
    return release_menu_registers(get_edi());
}
