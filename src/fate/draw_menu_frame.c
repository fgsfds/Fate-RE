/* Draw the menu background, entries, marker and optional save preview. */
typedef struct MenuEntry MenuEntry;
typedef MenuEntry **MenuRows;

extern long redraw_menu_frame;
extern MenuEntry *save_slot_menu_rows[];
extern long presentation_height, presentation_width;

extern int advance_menu_animation(void);
#pragma aux advance_menu_animation modify exact [eax];
extern void draw_menu_entries(long, long, long, const void *, MenuRows);
#pragma aux draw_menu_entries parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void draw_menu_selection_marker(long, long, MenuRows);
#pragma aux draw_menu_selection_marker parm routine [eax] [edx] [ebx] modify exact [eax ebx edx];
extern void draw_save_slot_preview(void);
#pragma aux draw_save_slot_preview modify exact [eax];
extern void nextpage(void);
#pragma aux nextpage modify exact [eax];
extern void rotatesprite(long, long, long, long, long, long, long, long,
                         long, long, long, long);
#pragma aux rotatesprite parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];

/* Establish the Watcom frame used jointly by the entries and marker calls.
 * EDI keeps the selection, ESI the heading tile, EBP the layout context,
 * and the local stack word keeps the highlight. The common return restores it. */
extern int begin_menu_frame(long, long, long, const void *);
#pragma aux begin_menu_frame = \
    "push ebp" "sub esp,4" "mov edi,eax" "mov [esp],edx" \
    "mov esi,ebx" "mov ebp,ecx" "call advance_menu_animation" \
    parm [eax] [edx] [ebx] [ecx] value [eax] modify exact [eax esi edi];

extern short menu_frame_tile(void);
#pragma aux menu_frame_tile = value [si] modify exact [];
extern long tile_for_comparison(long);
#pragma aux tile_for_comparison = parm [eax] value [eax] modify exact [];

/* Marshal the original menu entries stack argument and preserve its
 * sign-extended highlight in ESI for the marker. */
extern void render_frame_entries(void);
#pragma aux render_frame_entries = \
    "mov ebx,[esp+14h]" "mov ecx,ebp" "push ebx" "movsx ebx,si" \
    "movsx esi,word ptr [esp+4]" "mov eax,edi" "mov edx,esi" "call draw_menu_entries" \
    modify exact [eax ebx ecx edx esi];

extern MenuRows render_frame_marker(void);
#pragma aux render_frame_marker = \
    "mov ebx,[esp+14h]" "movsx eax,di" "mov edx,esi" "mov ecx,[esp+14h]" \
    "call draw_menu_selection_marker" value [ecx] modify exact [eax ebx edx ecx];

extern void release_frame(void);
#pragma aux release_frame = "add esp,4" modify exact [];
extern void menu_frame_return(void);
#pragma aux menu_frame_return aborts modify exact [];

#define draw_background(tile) rotatesprite(0, 0, 65536L, 0, tile, 0, 0, 0x92, 0, 0, \
                                           presentation_width - 1, presentation_height - 1)

void draw_menu_frame(long, long, long, const void *, MenuRows);
#pragma aux draw_menu_frame parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];

void draw_menu_frame(long selected, long highlight, long background,
                     const void *context, MenuRows rows)
{
    long tile;
    if (begin_menu_frame(selected, highlight, background, context) || redraw_menu_frame) {
        tile = tile_for_comparison(menu_frame_tile());
        if (tile == 0x820 || tile == 0x874 || tile == 0x875) {
            draw_background(0x81f);
        } else {
            if (tile < 0x834)
                goto range;
            if (tile > 0x834)
                goto range;
        common_background:
            draw_background(0x821);
            goto entries;
        range:
            tile = tile_for_comparison(menu_frame_tile());
            if (tile >= 0x835 && tile <= 0x837)
                goto common_background;
            tile = tile_for_comparison(menu_frame_tile());
            if (tile == 0x83e)
                draw_background(0x821);
        }
    entries:
        render_frame_entries();
        if (render_frame_marker() == save_slot_menu_rows)
            draw_save_slot_preview();
        nextpage();
    }
    release_frame();
    menu_frame_return();
}
