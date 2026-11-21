/* Mouse-button assignment, conflict removal, and persistence of the three bindings.
 * Empty auxiliaries constrain the original register ABI without emitting code.
 */
extern unsigned char mouse_row_format[], mouse_blank[], mouse_empty_format[];
extern unsigned char mouse_menu_title[], mouse_menu_prompt[];
extern unsigned char mouse_action_labels[], mouse_bindings[], mouse_button_names[];
extern unsigned char mouse_menu_entries[], mouse_menu_rows[], mouse_menu_selection[];
extern short mouse_buttons;
extern void presentation_input(void);
#pragma aux presentation_input modify exact [eax];
extern void draw_menu_frame(void);
#pragma aux draw_menu_frame modify exact [eax];
extern void run_menu_loop(void);
#pragma aux run_menu_loop modify exact [eax];
extern void format_string(void);
#pragma aux format_string modify exact [eax];
extern void format_call(long, long, long, long);
#pragma aux format_call "format_string_" parm caller [] modify exact [eax];

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
extern unsigned char get_bl(void);
#pragma aux get_bl = "" value [bl] modify exact [];
extern unsigned char put_al(unsigned char);
#pragma aux put_al = "" parm [al] value [al] modify exact [];
extern unsigned char get_al(void);
#pragma aux get_al = "" value [al] modify exact [];
extern unsigned char get_ah(void);
#pragma aux get_ah = "" value [ah] modify exact [];
extern unsigned char get_dh(void);
#pragma aux get_dh = "" value [dh] modify exact [];
extern unsigned char put_ah(unsigned char);
#pragma aux put_ah = "" parm [ah] value [ah] modify exact [];
extern short get_ax(void);
#pragma aux get_ax = "" value [ax] modify exact [];
extern short get_si(void);
#pragma aux get_si = "" value [si] modify exact [];
extern short get_dx(void);
#pragma aux get_dx = "" value [dx] modify exact [];
extern short put_dx(short);
#pragma aux put_dx = "" parm [dx] value [dx] modify exact [];

/* Watcom owns the other five saves/restores and RET. Keep EBP manual for
   the existing button-name loads. Conservative clobbers keep initialization
   after this push rather than hoisting it ahead of the shared register state. */
extern void save_menu_registers(void);
#pragma aux save_menu_registers = "push ebp" modify exact [ebx ecx edx esi edi];
extern int release_menu_registers(int);
#pragma aux release_menu_registers = "pop ebp" parm [eax] value [eax] modify exact [];
extern void push_menu_arg(long);
#pragma aux push_menu_arg = "" parm routine [] modify exact [];
extern void push_menu_rows(long);
#pragma aux push_menu_rows = "" parm routine [] modify exact [eax ebx ecx edx];
extern void keep_row_offset(long);
#pragma aux keep_row_offset = "" parm [eax] modify exact [ecx];
/* Two format sites defer caller cleanup until after a row-pointer load. */
extern void discard_format_args(void);
#pragma aux discard_format_args = "add esp,10h" modify exact [];
extern void load_action_ebp(void);
#pragma aux load_action_ebp = "mov ebp,dword ptr [ebx*8+mouse_action_labels]" modify exact [];
extern void load_button_ebp(void);
#pragma aux load_button_ebp = "mov ebp,dword ptr [ebx*4+mouse_button_names]" modify exact [];

int run_mouse_button_menu(void);
#pragma aux run_mouse_button_menu modify exact [eax];
int run_mouse_button_menu(void)
{
    save_menu_registers();
    put_ebx(0);
format_action:
    /* Attach the first currently bound button to each of the 25 action rows. */
    put_eax(*(long *)(get_ebx()*4 + (long)mouse_menu_entries));
    put_edx(0);
    *(long *)(get_eax()+7) = -1;
find_binding:
    put_eax(0);
    put_al(*(unsigned char *)(get_edx() + (long)mouse_bindings));
    if (get_eax() != get_ebx())
        goto next_binding;
    put_ecx(*(long *)(get_edx()*4 + (long)mouse_button_names));
    put_eax(get_eax()<<4);
    push_menu_arg(get_ecx());
    put_esi(*(long *)(get_ebx()*8 + (long)mouse_action_labels));
    keep_row_offset(put_eax(get_eax()-get_ebx()));
    push_menu_arg(get_esi());
    put_eax(get_eax()+get_eax());
    push_menu_arg((long)mouse_row_format);
    put_eax(get_eax()+(long)mouse_menu_rows);
    push_menu_arg(get_eax());
    format_string();
    put_eax(*(long *)(get_ebx()*4 + (long)mouse_menu_entries));
    discard_format_args();
    *(long *)(get_eax()+7) = get_edx();
    goto binding_found;
next_binding:
    put_edx(get_edx()+1);
    if (get_edx()<3)
        goto find_binding;
binding_found:
    put_eax(*(long *)(get_ebx()*4 + (long)mouse_menu_entries));
    if (*(long *)(get_eax()+7) != -1)
        goto next_action;
    put_eax(get_ebx());
    format_call(
        (put_eax(get_eax()+(long)mouse_menu_rows), get_eax()),
        (put_eax(get_eax()+get_eax()), (long)mouse_empty_format),
        (put_eax(get_eax()<<4), load_action_ebp(),
         put_eax(get_eax()-get_ebx()), get_ebp()),
        (long)mouse_blank);
next_action:
    put_ebx(get_ebx()+1);
    if (get_ebx()<25)
        goto format_action;
    put_edi(1);
select_action:
    /* A nonzero menu result enters capture; zero leaves the outer loop. */
    if (!get_edi())
        goto save_bindings;
    put_esi(0x83d);
    push_menu_rows((long)mouse_menu_entries);
    put_ecx((long)mouse_menu_title);
    put_edx(25);
    put_eax((long)mouse_menu_selection);
    put_ebx(get_si());
    run_menu_loop();
    put_edi(get_eax());
    if (!get_eax())
        goto select_action;
    put_eax(*(long *)mouse_menu_selection);
    format_call(
        (put_eax(get_eax()+(long)mouse_menu_rows), get_eax()),
        (put_edx(get_eax()), put_eax(get_eax()<<4), put_eax(get_eax()-get_edx()),
         put_eax(get_eax()+get_eax()), (long)mouse_empty_format),
        (put_edx(*(long *)(get_eax()*8 + (long)mouse_action_labels)), get_edx()),
        (long)mouse_blank);
wait_for_button:
    presentation_input();
    if (get_eax())
        goto received_button;
    push_menu_rows((long)mouse_menu_entries);
    put_ecx((long)mouse_menu_prompt);
    put_edx(25);
    put_eax(*(long *)mouse_menu_selection);
    put_ebx(get_si());
    draw_menu_frame();
    goto wait_for_button;
received_button:
    /* Keep the byte-register mask sequence compiler-generated. */
    put_dx(mouse_buttons);
    if (!get_dx())
        goto select_action;
    put_eax(get_edx());
    put_ah(get_ah() ^ get_dh());
    put_al(get_al() & 1);
    put_eax(get_ax());
    if (get_eax()) {
        put_ebx(0);
        goto scan_actions;
    }
    put_eax(get_edx());
    put_ah(get_ah() ^ get_dh());
    put_al(get_al() & 2);
    put_eax(get_ax());
    if (get_eax()) {
        put_ebx(2);
        goto scan_actions;
    }
    put_ebx(1);
scan_actions:
    put_edx(0);
scan_binding:
    /* A mouse button can belong to only one action. */
    put_eax(*(long *)(get_edx()*4 + (long)mouse_menu_entries));
    if (get_ebx()!=*(long *)(get_eax()+7))
        goto next_owner;
    *(long *)(get_eax()+7) = -1;
    put_eax(get_edx());
    format_call(
        (put_eax(get_eax()+(long)mouse_menu_rows), get_eax()),
        (put_eax(get_eax()+get_eax()), (long)mouse_empty_format),
        (put_eax(get_eax()<<4), put_esi(*(long *)(get_edx()*8 + (long)mouse_action_labels)),
         put_eax(get_eax()-get_edx()), get_esi()),
        (long)mouse_blank);
    goto assign_binding;
next_owner:
    put_edx(get_edx()+1);
    if (get_edx()<25)
        goto scan_binding;
assign_binding:
    load_button_ebp();
    put_eax(*(long *)mouse_menu_selection);
    push_menu_arg(get_ebp());
    put_edx(*(long *)(get_eax()*8 + (long)mouse_action_labels));
    push_menu_arg(get_edx());
    put_edx(get_eax());
    put_eax(get_eax()<<4);
    put_eax(get_eax()-get_edx());
    put_eax(get_eax()+get_eax());
    push_menu_arg((long)mouse_row_format);
    put_eax(get_eax()+(long)mouse_menu_rows);
    push_menu_arg(get_eax());
    format_string();
    put_eax(*(long *)mouse_menu_selection);
    put_eax(*(long *)(get_eax()*4 + (long)mouse_menu_entries));
    discard_format_args();
    *(long *)(get_eax()+7) = get_ebx();
    goto select_action;
save_bindings:
    /* Unassigned buttons retain their previous mapping; clear temporary values. */
    put_ebx(0);
write_binding:
    put_edx(*(long *)(get_ebx()*4 + (long)mouse_menu_entries));
    put_edx(*(long *)(get_edx()+7));
    if (get_edx()==-1)
        goto next_write;
    *(unsigned char *)(get_edx()+(long)mouse_bindings) = get_bl();
next_write:
    put_ebx(get_ebx()+1);
    if (get_ebx()<25)
        goto write_binding;
    put_ebx(0);
clear_value:
    put_eax(*(long *)(get_ebx()*4 + (long)mouse_menu_entries));
    put_ebx(get_ebx()+1);
    *(long *)(get_eax()+7) = 0;
    if (get_ebx()<25)
        goto clear_value;
    return release_menu_registers(get_edi());
}
