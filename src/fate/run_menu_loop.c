#include "menucall.h"

extern unsigned *menu_selection_storage;
extern unsigned menu_selection;
extern long menu_entry_count;
extern unsigned long enabled_menu_entries;
extern MenuRecord *active_menu_entries[];
extern MenuRecord *demo_entries[], *save_slot_menu_rows[];
extern long menu_loop_state;
extern unsigned char save_slot_preview_enabled;

extern void presentation_reset(void);
#pragma aux presentation_reset modify exact [eax];
extern void draw_menu_frame(unsigned, long, short, const char *, MenuRecord **);
#pragma aux draw_menu_frame parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void update_menu_selection(void);
#pragma aux update_menu_selection modify exact [eax];
extern void read_save_slot_preview(int);
#pragma aux read_save_slot_preview modify exact [eax];
/* The original epilogue is shared with the preceding menu routines. */
extern void release_menu_loop_frame(void);
#pragma aux release_menu_loop_frame = "add esp,8" modify exact [];
extern int menu_loop_return(int);
#pragma aux menu_loop_return "small_text_return_" parm [eax] aborts modify exact [];

extern unsigned long mask_in_edx(unsigned long);
#pragma aux mask_in_edx = parm [edx] value [edx] modify exact [];
extern unsigned long mask_in_ebx(unsigned long);
#pragma aux mask_in_ebx = parm [ebx] value [ebx] modify exact [];
extern long loop_state_in_ecx(long);
#pragma aux loop_state_in_ecx = parm [ecx] value [ecx] modify exact [];
extern unsigned char index_in_cl(unsigned char);
#pragma aux index_in_cl = parm [cl] value [cl] modify exact [];
extern unsigned index_in_ebx(unsigned);
#pragma aux index_in_ebx = parm [ebx] value [ebx] modify exact [];
extern unsigned long menu_mask_bit(unsigned char,unsigned long);
#pragma aux menu_mask_bit = "shl edx,cl" parm [cl] [edx] value [edx] modify exact [edx];
extern long prev_selection_in_edx(long);
#pragma aux prev_selection_in_edx = parm [edx] value [edx] modify exact [];
/* Watcom uses the original byte load and full-width comparison here. */
extern void start_preview_flag(unsigned);
#pragma aux start_preview_flag = "" parm [eax] modify exact [eax];
extern void set_preview_flag(unsigned char);
#pragma aux set_preview_flag = "" parm [al] modify exact [];
extern unsigned preview_flag(void);
#pragma aux preview_flag = value [eax] modify exact [];
/* Preserve the register choreography at the cancellation and setup boundaries. */
extern long cancel_state_in_edi(long);
#pragma aux cancel_state_in_edi = "" parm [edi] value [edi] modify exact [];
extern int zero_result_in_eax(int);
#pragma aux zero_result_in_eax = "" parm [eax] value [eax] modify exact [];

/* Keep the source-visible initialization in the original register order. */
extern long initial_state_in_ebx(long);
#pragma aux initial_state_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern void finish_selection_writes(unsigned *, long);
#pragma aux finish_selection_writes = "" parm [eax] [ebx] modify exact [ecx];
extern void zero_enabled_mask(unsigned long);
#pragma aux zero_enabled_mask = "" parm [ecx] modify exact [ecx];
extern unsigned long initial_mask_in_ecx(void);
#pragma aux initial_mask_in_ecx = "" value [ecx] modify exact [];
extern long count_in_eax(long);
#pragma aux count_in_eax = "" parm [eax] value [eax] modify exact [];
extern void keep_selection_and_state(unsigned *, long);
#pragma aux keep_selection_and_state = "" parm [eax] [ebx] modify exact [];

/* The original assembly entry initializes the frame in historical instruction order.
 * The build uses the Watcom output from byte 17 onward. */
int run_menu_loop(unsigned *selection, int count, short background, const char *title, MenuRecord **rows)
{
    struct {
        volatile long count;
        volatile long previous_selection;
    } saved;
    long previous, state, result;
    unsigned i, first;

    /* Keep both original frame slots visible to the compiler. */
    saved.count = count;
    previous = prev_selection_in_edx(-1);
    state = initial_state_in_ebx(1);
    keep_selection_and_state(selection, state);
    menu_selection_storage = selection;
    menu_loop_state = state;
    /* Keep the zeroed mask after both stores. */
    finish_selection_writes(selection, state);
    zero_enabled_mask(0);
    first = *selection;
    saved.previous_selection = previous;
    menu_selection = first;
    result = count_in_eax(saved.count);
    enabled_menu_entries = initial_mask_in_ecx();
    menu_entry_count = result;

    for (i = 0; (int)i < saved.count; ++i) {
        MenuRecord *entry = rows[index_in_ebx(i)];
        active_menu_entries[i] = entry;
        if ((*entry)[0]) {
            unsigned long one = mask_in_edx(1);
            unsigned char shift = index_in_cl((unsigned char)i);
            unsigned long old_mask = mask_in_ebx(enabled_menu_entries);
            enabled_menu_entries = old_mask | menu_mask_bit(shift, one);
        }
    }

    presentation_reset();
    while ((state = loop_state_in_ecx(menu_loop_state)) == 1) {
        if (rows == demo_entries) {
            unsigned current = menu_selection;
            if (current <= 0)
                goto first_demo;
            if (current == (unsigned)state)
                goto second_demo;
            goto draw;
        first_demo:
            background = 0x874;
            goto draw;
        second_demo:
            background = 0x875;
        }
    draw:
        draw_menu_frame(menu_selection, menu_entry_count, background, title, rows);
        update_menu_selection();
        if (rows == save_slot_menu_rows &&
            (unsigned)prev_selection_in_edx(saved.previous_selection) != menu_selection) {
            start_preview_flag(0);
            set_preview_flag(save_slot_preview_enabled);
            if (preview_flag() == 1)
                read_save_slot_preview(menu_selection);
        }
        saved.previous_selection = menu_selection;
    }

    if (state == -1) {
        long stopped = cancel_state_in_edi(0);
        result = zero_result_in_eax(0);
        menu_loop_state = stopped;
    } else {
        result = 1;
    }
    release_menu_loop_frame();
    return menu_loop_return(result);
}
