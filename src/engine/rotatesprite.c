/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

typedef struct {
    long x, y, zoom;
    short angle, tile;
    unsigned char shade, palette, flags, pages;
    long left, top, right, bottom;
} permanent_sprite;

extern long picanm[];
extern short tilesizx[], tilesizy[];
extern long display_page_count, permanent_sprite_head;
extern volatile long permanent_sprite_tail;
extern permanent_sprite permanent_sprite_queue[];
extern unsigned char permanent_sprite_phase, draw_single_page_sprite;

extern void end_rotated_sprite(void);
#pragma aux end_rotated_sprite aborts modify exact [];
extern long animateoffs(long tile, long clock_offset);
#pragma aux animateoffs parm [eax] [edx] value [eax] modify exact [eax edx];
extern void draw_rotated_sprite(void);
#pragma aux draw_rotated_sprite modify exact [eax ebx ecx edx];

extern void begin_rotated_sprite(long x, long y, long zoom, long angle);
#pragma aux begin_rotated_sprite = "push esi" "push edi" "push ebp" "sub esp,4" \
    "mov ebp,eax" "mov edi,edx" "mov esi,ebx" "mov [esp],ecx" \
    parm [eax] [edx] [ebx] [ecx] modify exact [esi edi];
/* Keep the original direct branches to the frame cleanup. */
extern void require_visible_rotated_sprite(void);
#pragma aux require_visible_rotated_sprite = "mov eax,[esp+24h]" "cmp eax,[esp+2ch]" "jg end_rotated_sprite" \
    "mov eax,[esp+28h]" "cmp eax,[esp+30h]" "jg end_rotated_sprite" "cmp esi,10h" "jle end_rotated_sprite" modify exact [eax];
extern long rotation_tile(void);
#pragma aux rotation_tile = "movsx eax,word ptr [esp+14h]" value [eax] modify exact [eax];
extern long active_rotation_tile(void);
#pragma aux active_rotation_tile = value [eax] modify exact [];
extern void apply_tile_animation(long offset);
#pragma aux apply_tile_animation = "add [esp+14h],eax" parm [eax] modify exact [];
extern void require_rotated_tile_dimensions(void);
#pragma aux require_rotated_tile_dimensions = "movsx edx,word ptr [esp+14h]" "lea eax,[edx+edx]" \
    "cmp word ptr [eax+tilesizx],0" "jle end_rotated_sprite" "cmp word ptr [eax+tilesizy],0" "jle end_rotated_sprite" \
    modify exact [eax edx];
extern void push_draw_clip_bounds(void);
#pragma aux push_draw_clip_bounds = "mov ecx,[esp+30h]" "push ecx" "mov eax,[esp+30h]" "push eax" \
    "mov ebx,[esp+30h]" "push ebx" "mov ecx,[esp+30h]" "xor eax,eax" "push ecx" \
    modify exact [eax ebx ecx];
extern void push_draw_sprite_fields(void);
#pragma aux push_draw_sprite_fields = "mov al,[esp+30h]" "push eax" "xor eax,eax" \
    "mov al,[esp+30h]" "push eax" "movsx eax,byte ptr [esp+30h]" "mov ebx,esi" "push eax" \
    "movsx ecx,word ptr [esp+1ch]" "push edx" "mov eax,ebp" "mov edx,edi" modify exact [eax ebx ecx edx];
extern void require_permanent_rotation(void);
#pragma aux require_permanent_rotation = "mov al,[esp+20h]" "and al,80h" "and eax,0ffh" \
    "jz end_rotated_sprite" modify exact [eax];

extern void prepare_rotation_slot(void);
#pragma aux prepare_rotation_slot = "mov edx,permanent_sprite_tail" "mov eax,edx" "shl eax,3" \
    "add eax,edx" "mov edx,offset permanent_sprite_queue" "shl eax,2" "add edx,eax" modify exact [eax edx];
/* Queue records occupy 36 bytes and retain the clipping bounds. */
extern void save_rotated_sprite_geometry(void);
#pragma aux save_rotated_sprite_geometry = "mov [edx],ebp" "mov [edx+4],edi" "mov eax,[esp]" "mov [edx+8],esi" \
    "mov [edx+0ch],ax" "mov eax,[esp+14h]" "mov [edx+0eh],ax" modify exact [eax];
extern void save_rotated_sprite_color(void);
#pragma aux save_rotated_sprite_color = "mov al,[esp+18h]" "mov [edx+10h],al" "mov al,[esp+1ch]" \
    "mov [edx+11h],al" "mov al,[esp+20h]" "mov [edx+12h],al" "mov ah,permanent_sprite_phase" \
    "and ah,1" "shl ah,7" "mov al,byte ptr display_page_count" "add al,ah" "mov [edx+13h],al" modify exact [eax];
extern void save_rotated_sprite_clip_bounds(void);
#pragma aux save_rotated_sprite_clip_bounds = "mov eax,[esp+24h]" "mov [edx+14h],eax" "mov eax,[esp+28h]" \
    "mov [edx+18h],eax" "mov eax,[esp+2ch]" "mov [edx+1ch],eax" "mov eax,[esp+30h]" "mov [edx+20h],eax" modify exact [eax];
extern void advance_permanent_tail(void);
#pragma aux advance_permanent_tail aborts modify exact [];
extern void require_cover_scan(void);
#pragma aux require_cover_scan = "mov al,[esp+20h]" "and al,40h" "and eax,0ffh" \
    "jz advance_permanent_tail" modify exact [eax];

extern void begin_previous_sprites(long head);
#pragma aux begin_previous_sprites = "" parm [esi] modify exact [];
extern long previous_sprite_index(void);
#pragma aux previous_sprite_index = value [esi] modify exact [];
extern void prepare_previous_sprite(void);
#pragma aux prepare_previous_sprite = "mov eax,esi" "shl eax,3" "add eax,esi" "shl eax,2" \
    "add eax,offset permanent_sprite_queue" modify exact [eax];
extern long previous_sprite_pages(void);
#pragma aux previous_sprite_pages = "mov bl,[eax+13h]" "and bl,7fh" value [ebx] modify exact [ebx];
extern void retain_previous_sprite_pages(long pages);
#pragma aux retain_previous_sprite_pages = "" parm [ebx] modify exact [];
extern permanent_sprite *current_sprite_slot(void);
#pragma aux current_sprite_slot = value [edx] modify exact [];
extern void prepare_sprite_tile_comparison(void);
#pragma aux prepare_sprite_tile_comparison = "movsx ecx,word ptr [eax+0eh]" "add ecx,ecx" \
    "movsx ebx,word ptr [edx+0eh]" "mov di,word ptr [ecx+tilesizx]" "add ebx,ebx" modify exact [ecx ebx edi];
extern short previous_sprite_width(void);
#pragma aux previous_sprite_width = value [di] modify exact [];
extern short previous_sprite_height(void);
#pragma aux previous_sprite_height = "mov cx,word ptr [ecx+tilesizy]" value [cx] modify exact [ecx];
extern long current_tile_byte_offset(void);
#pragma aux current_tile_byte_offset = value [ebx] modify exact [];
extern void advance_previous_sprite(void);
#pragma aux advance_previous_sprite = "inc esi" "and esi,1ffh" modify exact [esi];
extern long tail_in_eax(long tail);
#pragma aux tail_in_eax = "" parm [eax] value [eax] modify exact [];
extern void finish_rotated_sprite(void);
#pragma aux finish_rotated_sprite = "add esp,4" "pop ebp" "pop edi" "pop esi" modify exact [];
#pragma aux rotatesprite modify exact [eax ebx ecx edx esi edi];

extern long prior_sprite_x(void);
#pragma aux prior_sprite_x = "mov ebx,[eax]" value [ebx] modify exact [ebx];
extern void next_rotated_sprite(void);
#pragma aux next_rotated_sprite aborts modify exact [];
/* Force Watcom to retain the original near branch for this mismatch. */
extern void require_same_sprite_y(void);
#pragma aux require_same_sprite_y = "mov ebx,[eax+4]" "cmp ebx,[edx+4]" "jne next_rotated_sprite" \
    modify exact [ebx];
extern long prior_sprite_zoom(void);
#pragma aux prior_sprite_zoom = "mov ebx,[eax+8]" value [ebx] modify exact [ebx];
extern short prior_sprite_angle(void);
#pragma aux prior_sprite_angle = "mov bx,[eax+12]" value [bx] modify exact [ebx];
extern void discard_covered_clip_bounds(void);
#pragma aux discard_covered_clip_bounds = "mov ebx,[eax+14h]" "cmp ebx,[edx+14h]" "jl uncovered" \
    "mov ebx,[eax+18h]" "cmp ebx,[edx+18h]" "jl uncovered" "mov ebx,[eax+1ch]" "cmp ebx,[edx+1ch]" "jg uncovered" \
    "mov ebx,[eax+20h]" "cmp ebx,[edx+20h]" "jg uncovered" "mov byte ptr [eax+13h],0" "uncovered:" modify exact [ebx];


void rotatesprite(long x, long y, long zoom, long angle,
                  long tile, long shade, long palette, long flags,
                  long left, long top, long right, long bottom)
{
    long pages;

    begin_rotated_sprite(x, y, zoom, angle);
    require_visible_rotated_sprite();
    if ((unsigned char)picanm[rotation_tile()] & 0xc0)
        apply_tile_animation(animateoffs(active_rotation_tile(), -16384L));
    require_rotated_tile_dimensions();
    push_draw_clip_bounds();
    push_draw_sprite_fields();
    draw_rotated_sprite();

    require_permanent_rotation();
    if (display_page_count < 2)
        goto single_page;
    prepare_rotation_slot();
    save_rotated_sprite_geometry();
    save_rotated_sprite_color();
    save_rotated_sprite_clip_bounds();
    /* A covering sprite can retire older queued copies of the same geometry. */
    require_cover_scan();
    begin_previous_sprites(permanent_sprite_head);
    goto check_prior;
    do {
        prepare_previous_sprite();
        pages = previous_sprite_pages() & 255;
        if (!pages)
            goto next_sprite;
        retain_previous_sprite_pages(pages);
        if (prior_sprite_x() != current_sprite_slot()->x)
            goto next_sprite;
        require_same_sprite_y();
        if (prior_sprite_zoom() != current_sprite_slot()->zoom ||
            prior_sprite_angle() != current_sprite_slot()->angle)
            goto next_sprite;
        prepare_sprite_tile_comparison();
        if (previous_sprite_width() > *(short *)((char *)tilesizx + current_tile_byte_offset()) ||
            previous_sprite_height() > *(short *)((char *)tilesizy + current_tile_byte_offset()))
            goto next_sprite;
        discard_covered_clip_bounds();
next_sprite:
        advance_previous_sprite();
check_prior:;
    } while (previous_sprite_index() != permanent_sprite_tail);
    permanent_sprite_tail = tail_in_eax((permanent_sprite_tail + 1) & 511);
    goto done;
single_page:
    draw_single_page_sprite = 1;
done:
    finish_rotated_sprite();
}
