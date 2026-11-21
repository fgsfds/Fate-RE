// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// See ../engine/BUILDLIC.TXT.
/* Seven unchanged sections supply 431 bytes; menuprep.c supplies another 63.
 * The resume block, original table and alignment remain assembly. The full
 * private C context is not exact. Empty ABI auxiliaries preserve real values.
 * EDI/EBP hold clock snapshots and ESI the result through the shared frame.
 * The entry's independent tick load and EDX zero are selected in original
 * order; all six saves and the clock-read order remain unchanged.
 * return_main_menu is a nonreturning shared-frame tail continuation, not an
 * ordinary callable helper: it returns ESI in EAX and restores six saves.
 * Selection guards its E9 transfer. No private table is linked.
 */
#include "menurec.h"
extern long totalclock, menu_saved_tick, menu_animation_clock;
extern long game_in_progress, menu_dispatch_active, loaded_game_ready, menu_loop_state;
extern unsigned main_menu_selection;
extern short new_game_requested, difficulty_divisor;
extern long presentation_width, presentation_height, loading_caption_columns;
extern const unsigned char main_menu_title[], loading_caption[];
extern MenuRecord *main_entries[], *pause_entries[];
extern void reset_menu_animation_clock(void), cache_menu_tiles(void);
#pragma aux reset_menu_animation_clock modify exact [eax];
#pragma aux cache_menu_tiles modify exact [eax];
extern int run_menu_loop(unsigned *,int,short,const char *,MenuRecord **);
#pragma aux run_menu_loop parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern int run_options_menu(void), confirm_menu_action(void);
extern int run_save_game_menu(void), run_load_game_menu(void), run_help_menu(void);
extern int new_game_disabled(void), run_difficulty_menu(void);
extern void preload_game_tiles(void);
#pragma aux run_options_menu modify exact [eax];
#pragma aux confirm_menu_action modify exact [eax];
#pragma aux run_save_game_menu modify exact [eax];
#pragma aux run_load_game_menu modify exact [eax];
#pragma aux run_help_menu modify exact [eax];
#pragma aux new_game_disabled modify exact [eax];
#pragma aux run_difficulty_menu modify exact [eax];
#pragma aux preload_game_tiles modify exact [eax];
extern void menu_clearview(int colour);
#pragma aux menu_clearview "clearview_" parm [eax] modify exact [eax];
extern void rotatesprite(long,long,long,short,short,signed char,unsigned char,unsigned char,long,long,long,long);
#pragma aux rotatesprite modify exact [eax ebx ecx edx];
extern void draw_menu_text(long,long,long,const unsigned char *,int);
#pragma aux draw_menu_text parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void nextpage(void);
#pragma aux nextpage modify exact [eax];
extern int return_main_menu(int result);
#pragma aux return_main_menu "menu_selection_return_" parm [esi] aborts modify exact [eax];
extern int main_result_in_esi(int);
#pragma aux main_result_in_esi = "" parm [esi] value [esi] modify exact [];
extern long main_clock_in_edi(long);
#pragma aux main_clock_in_edi = "" parm [edi] value [edi] modify exact [];
extern int main_request_in_ebx(int);
#pragma aux main_request_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern long main_flag_in_eax(long);
#pragma aux main_flag_in_eax = "" parm [eax] value [eax] modify exact [];
int dispatch_main_menu(void);
#pragma aux dispatch_main_menu modify exact [eax];
int dispatch_main_menu(void)
{
    int result, accepted;
    long saved_clock, saved_tick;
    result = main_result_in_esi(1);
    saved_clock = main_clock_in_edi(totalclock);
    saved_tick = menu_saved_tick;
    reset_menu_animation_clock();
    menu_animation_clock = 0;
    cache_menu_tiles();
    if (game_in_progress)
        main_menu_selection = result;
    else
        main_menu_selection = 0;
    while (menu_dispatch_active) {
        if (!game_in_progress)
            accepted = run_menu_loop(&main_menu_selection,8,0x820,(const char *)main_menu_title,main_entries);
        else
            accepted = run_menu_loop(&main_menu_selection,8,0x820,(const char *)main_menu_title,pause_entries);
        if (!accepted)
            goto cancelled;
        switch (main_menu_selection) {
        case 0:
            new_game_requested = main_request_in_ebx(1);
            if (main_flag_in_eax(game_in_progress) && !confirm_menu_action())
                break;
            if (new_game_disabled() > 0) {
            successful:
                result = 1;
                goto done;
            }
            if (run_difficulty_menu()) {
                menu_clearview(0);
                result = 1;
                rotatesprite(160L<<16,100L<<16,65536L,0,0x9a1,0,0,2,
                             0,0,presentation_width-1,presentation_height-1);
                draw_menu_text(160-((long)((unsigned long)loading_caption_columns*7U)>>1),
                               78,-1,loading_caption,1);
                nextpage();
            preload:
                preload_game_tiles();
                goto done;
            }
            break;
        case 1: run_options_menu(); break;
        case 2:
            if (game_in_progress && !confirm_menu_action())
                break;
            if (run_load_game_menu() == -1)
                break;
            result = 1;
            loaded_game_ready = result;
            difficulty_divisor = 2;
            goto preload;
        case 3: run_save_game_menu(); break;
        case 4: run_help_menu(); break;
        case 5:
        case 6:
            if (game_in_progress)
                goto successful;
            goto clear_result;
        case 7:
            if (confirm_menu_action()) {
                result = 0;
                menu_dispatch_active = 0;
                game_in_progress = 0;
                menu_loop_state = 0;
                goto done;
            }
            break;
        }
    }
    goto done;
cancelled:
    if (game_in_progress)
        goto successful;
clear_result:
    result = 0;
done:
    totalclock = saved_clock;
    menu_saved_tick = saved_tick;
    return return_main_menu(result);
}
