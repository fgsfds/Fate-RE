// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// See ../engine/BUILDLIC.TXT.
/* Select 40 caption-argument bytes and 23 menu-selection bytes. Both normal
 * C contexts are larger than their linked prefixes; their private successors
 * are checked and excluded. Caption PUSH ESI is a real outgoing fifth argument
 * consumed by the immediately following production draw_menu_text CALL/RET4.
 * Selection receives the actual ESI result and EDX zero from the entry and
 * preserves all registers before the existing active-state comparison.
 * Watcom's 32-bit unsigned multiply, bit-preserving signed conversion and
 * arithmetic right shift reproduce the caption math without signed overflow.
 */
extern long loading_caption_columns;
extern const unsigned char loading_caption[];
extern void draw_menu_text(long,long,long,const unsigned char *,int);
#pragma aux draw_menu_text parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
void main_caption_setup(long);
#pragma aux main_caption_setup parm [esi] modify exact [eax ebx ecx edx];
void main_caption_setup(long style)
{
    draw_menu_text(160-((long)((unsigned long)loading_caption_columns*7U)>>1),
                   78,-1,loading_caption,style);
}

extern long game_in_progress, menu_dispatch_active;
extern unsigned main_menu_selection;
long main_menu_select(unsigned long, unsigned long);
#pragma aux main_menu_select parm [esi] [edx] value [eax] modify exact [eax];
long main_menu_select(unsigned long result, unsigned long zero)
{
    if (game_in_progress)
        main_menu_selection = result;
    else
        main_menu_selection = zero;
    return menu_dispatch_active;
}
