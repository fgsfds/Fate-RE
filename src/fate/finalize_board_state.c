/* Build board visibility and preload textures from the selected sector. */
extern short numsectors, final_player_sprite;
extern short final_sector_seed[], final_sector_queue[], final_wall_first[], final_wall_count[];
extern short final_sector_lotag[], final_ceiling_tile[], final_floor_tile[];
extern short final_wall_tile[], final_wall_overlay[], final_wall_lotag[];
extern long final_tile_cache[];
extern unsigned char final_sectors_before[], final_walls_before[], final_sprites_before[];
extern unsigned char final_sectors_visible[], final_walls_visible[], final_sprites_visible[];
extern unsigned char final_visibility_dirty;
typedef struct {
    long x, y;
    short point, next_wall, next_sector, flags;
    short tile, overlay;
    unsigned char surface[6];
    short lotag, hitag, extra;
} FinalWall;
extern FinalWall final_walls[];
extern void loadtile(int);
#pragma aux loadtile parm [eax] modify exact [eax];

/* Keep the queue cursor, current sector, and wall range in the original frame. */
extern void begin_board_finalization(long);
#pragma aux begin_board_finalization = "push ebx" "push ecx" "push edx" "push esi" "push edi" "push ebp" \
    "sub esp,10h" "mov ebx,eax" parm [eax] modify exact [ebx];
extern void finish_board_finalization(void);
#pragma aux finish_board_finalization = "add esp,10h" "pop ebp" "pop edi" "pop esi" "pop edx" "pop ecx" "pop ebx" modify exact [];
extern void mark_initial_sector(void);
#pragma aux mark_initial_sector = \
    "xor ch,ch" "movsx edx,bx" "mov [final_visibility_dirty],ch" "mov cl,bl" "mov eax,edx" "and cl,7" \
    "mov esi,edx" "mov ch,1" "sar eax,3" "shl ch,cl" "shl edx,2" "mov cl,ch" "add edx,esi" \
    "mov ch,[eax+final_sectors_visible]" "mov [final_sector_seed],bx" "or ch,cl" \
    "movsx edx,word ptr [edx*8+final_sector_lotag]" "mov [eax+final_sectors_visible],ch" \
    modify exact [eax ecx edx esi];
extern void hide_initial_sector(void);
#pragma aux hide_initial_sector = "mov dl,cl" "not dl" "mov dh,ch" "and dh,dl" \
    "mov [eax+final_sectors_visible],dh" modify exact [edx];
extern void store_queue_position(long);
#pragma aux store_queue_position = "mov [esp+4],edi" parm [edi] modify exact [];
extern void read_queue_position(void);
#pragma aux read_queue_position = "mov ebp,[esp+4]" modify exact [];
extern void store_current_sector(long);
#pragma aux store_current_sector = "mov [esp+0ch],eax" parm [eax] modify exact [];
extern long read_current_sector_ebx(void);
#pragma aux read_current_sector_ebx = "mov ebx,[esp+0ch]" value [ebx] modify exact [ebx];
extern long read_current_sector_ecx(void);
#pragma aux read_current_sector_ecx = "mov ecx,[esp+0ch]" value [ecx] modify exact [ecx];
extern void store_wall_limit(long);
#pragma aux store_wall_limit = "mov [esp+8],edx" parm [edx] modify exact [];
extern long read_wall_limit(void);
#pragma aux read_wall_limit = "mov eax,[esp+8]" value [eax] modify exact [eax];
extern void calculate_wall_mask(void);
#pragma aux calculate_wall_mask = "mov cl,dl" "mov bl,1" "and cl,7" modify exact [ebx ecx];
extern unsigned char shift_wall_mask(long);
#pragma aux shift_wall_mask = "shl bl,cl" parm [eax] value [bl] modify exact [ebx];
/* Test the saved visibility bits and skip the existing neighbor entry. */
extern void skip_visible_neighbor(void);
#pragma aux skip_visible_neighbor = \
    "xor ecx,ecx" "mov cl,[eax+final_sectors_visible]" "mov [esp],ecx" \
    "mov ecx,ebx" "mov ebp,1" "and ecx,7" "shl ebp,cl" "mov ecx,ebp" \
    "test [esp],ecx" "db 75h, 58h" /* marker-rel8 +1,+2 */ modify exact [ecx];
extern void mark_neighbor_visible(void);
#pragma aux mark_neighbor_visible = \
    "mov cl,bl" "and cl,7" "mov ch,1" "shl ch,cl" "mov cl,ch" \
    "or [eax+final_sectors_visible],cl" modify exact [ecx];
extern void mark_player_visible(void);
#pragma aux mark_player_visible = "mov edx,[esp+4]" "mov ch,[eax+final_sprites_visible]" "inc edx" \
    "or ch,bl" "mov [esp+4],edx" "mov [eax+final_sprites_visible],ch" modify exact [ecx edx];
/* Zero-byte bindings preserve Watcom register assignments. */
extern long in_eax(long);
#pragma aux in_eax = parm [eax] value [eax] modify exact [];
extern long in_ebx(long);
#pragma aux in_ebx = parm [ebx] value [ebx] modify exact [];
extern long in_edx(long);
#pragma aux in_edx = parm [edx] value [edx] modify exact [];
extern long in_esi(long);
#pragma aux in_esi = parm [esi] value [esi] modify exact [];
extern long in_edi(long);
#pragma aux in_edi = parm [edi] value [edi] modify exact [];
extern short in_ax(short);
#pragma aux in_ax = parm [ax] value [ax] modify exact [];
extern long eax_value(void);
#pragma aux eax_value = value [eax] modify exact [];
extern long ebx_value(void);
#pragma aux ebx_value = value [ebx] modify exact [];
extern long edx_value(void);
#pragma aux edx_value = value [edx] modify exact [];
extern long esi_value(void);
#pragma aux esi_value = value [esi] modify exact [];
extern long edi_value(void);
#pragma aux edi_value = value [edi] modify exact [];
extern long ebp_value(void);
#pragma aux ebp_value = value [ebp] modify exact [];
extern short ax_value(void);
#pragma aux ax_value = value [ax] modify exact [];
extern short bx_value(void);
#pragma aux bx_value = value [bx] modify exact [];
extern unsigned char bl_value(void);
#pragma aux bl_value = value [bl] modify exact [];

extern void keep_wall_cursor(long);
#pragma aux keep_wall_cursor = parm [esi] modify exact [];

/* Keep the visibility masks in the original byte registers. */
extern unsigned char in_ah(unsigned char);
#pragma aux in_ah = parm [ah] value [ah] modify exact [];
extern unsigned char in_cl(unsigned char);
#pragma aux in_cl = parm [cl] value [cl] modify exact [];
extern unsigned char in_bl(unsigned char);
#pragma aux in_bl = parm [bl] value [bl] modify exact [];
extern unsigned char cl_value(void);
#pragma aux cl_value = value [cl] modify exact [];
extern unsigned char dl_value(void);
#pragma aux dl_value = value [dl] modify exact [];

void finalize_board_state(long);
#pragma aux finalize_board_state parm [eax] modify exact [eax ebx ecx edx esi edi];
void finalize_board_state(long sector)
{
    long row, end_wall;
    unsigned char bit;

    begin_board_finalization(sector);
    if (ax_value() < 0 || ax_value() >= numsectors)
        goto done;
    in_edx(0);
    goto check_clear_sectors;
clear_sectors:
    in_edx(edx_value() + 1);
    final_sectors_before[edx_value()] = in_ah(0);
check_clear_sectors:
    if (edx_value() < 128)
        goto clear_sectors;
    in_edx(0);
    goto check_clear_walls;
clear_walls:
    in_edx(edx_value() + 1);
    final_walls_before[edx_value()] = in_cl(0);
check_clear_walls:
    if (edx_value() < 1024)
        goto clear_walls;
    in_edx(0);
    goto check_clear_sprites;
clear_sprites:
    in_edx(edx_value() + 1);
    final_sprites_before[edx_value()] = in_cl(0);
check_clear_sprites:
    if (edx_value() < 512)
        goto clear_sprites;
    /* Tag 99 suppresses visibility without suppressing tile loading. */
    mark_initial_sector();
    if (edx_value() == 99)
        hide_initial_sector();
    row = in_edx(bx_value());
    in_ax(final_ceiling_tile[(in_eax(row) * 4 + row) * 4]);
    in_eax(ax_value());
    if (final_tile_cache[eax_value()] == 0)
        loadtile(eax_value());
    row = in_edx(bx_value());
    in_ax(final_floor_tile[(in_eax(row) * 4 + row) * 4]);
    in_eax(ax_value());
    if (final_tile_cache[eax_value()] == 0)
        loadtile(eax_value());

    /* Traverse the starting sector and append newly seen adjacent sectors. */
    in_edi(0);
    store_queue_position(edi_value());
    in_edi(1);
    goto check_queue;
visit_sector:
    row = in_eax(final_sector_seed[ebp_value()]);
    store_current_sector(row);
    row = in_edx(eax_value());
    in_eax(in_eax(eax_value() * 4) + row);
    in_ebx(final_wall_first[eax_value() * 4]);
    in_eax(final_wall_count[eax_value() * 4]);
    end_wall = in_edx(ebx_value() + eax_value());
    keep_wall_cursor(esi_value());
    in_esi((long)final_walls);
    store_wall_limit(end_wall);
    in_edx(ebx_value());
    in_ebx(ebx_value() * 32);
    in_esi(esi_value() + ebx_value());
    goto check_walls;
visit_wall:
    in_eax(edx_value());
    in_eax(eax_value() >> 3);
    final_walls_visible[eax_value()] |= bl_value();
    row = read_current_sector_ebx();
    in_eax(in_eax(row) * 4 + row);
    if (in_eax(final_sector_lotag[eax_value() * 4]) == 99)
        goto hide_wall;
    in_eax(in_eax(edx_value()) * 32);
    if (in_eax(*(const short *)((const char *)final_wall_lotag + eax_value())) != 99)
        goto wall_tiles;
hide_wall:
    in_cl(dl_value());
    in_bl(1);
    bit = in_cl(cl_value() & 7);
    in_eax(edx_value());
    in_bl((unsigned long)bl_value() << bit);
    in_eax(eax_value() >> 3);
    final_walls_visible[eax_value()] &= in_bl(~bl_value());
wall_tiles:
    /* The high overlay bits distinguish a tile from a non-tile value. */
    in_eax(in_eax(edx_value()) * 32);
    in_ax(*(const short *)((const char *)final_wall_tile + eax_value()));
    in_eax(ax_value());
    if (final_tile_cache[eax_value()] == 0)
        loadtile(eax_value());
    in_eax(in_eax(edx_value()) * 32);
    in_ax(*(const short *)((const char *)final_wall_overlay + eax_value()));
    if (in_ebx(ax_value()) & -4096L)
        goto wall_neighbor;
    in_eax(ax_value());
    if (final_tile_cache[eax_value()] == 0)
        loadtile(eax_value());
wall_neighbor:
    if (in_ebx(((const FinalWall *)esi_value())->next_sector) < 0)
        goto after_neighbor;
    in_eax(in_eax(ebx_value()) >> 3);
    skip_visible_neighbor();
    mark_neighbor_visible();
    row = in_eax(in_eax(ebx_value()) * 4 + ebx_value());
    in_ax(final_ceiling_tile[row * 4]);
    in_eax(ax_value());
    if (final_tile_cache[eax_value()] == 0)
        loadtile(eax_value());
    row = in_eax(in_eax(ebx_value()) * 4 + ebx_value());
    in_ax(final_floor_tile[row * 4]);
    in_eax(ax_value());
    if (final_tile_cache[eax_value()] == 0)
        loadtile(eax_value());
    in_edi(edi_value() + 1);
    final_sector_queue[edi_value()] = bx_value();

after_neighbor:
    row = read_current_sector_ecx();
    in_eax(in_eax(row) * 4 + row);
    if (in_eax(final_sector_lotag[eax_value() * 4]) == 99) {
        in_eax(ebx_value());
        in_cl(bl_value());
        in_bl(1);
        bit = in_cl(cl_value() & 7);
        in_bl((unsigned long)bl_value() << bit);
        in_eax(eax_value() >> 3);
        final_sectors_visible[eax_value()] &= in_bl(~bl_value());
    }
    in_edx(edx_value() + 1);
    in_esi(esi_value() + 32);
check_walls:
    calculate_wall_mask();
    end_wall = read_wall_limit();
    shift_wall_mask(end_wall);
    if (edx_value() < end_wall)
        goto visit_wall;
    in_eax(in_eax(final_player_sprite) >> 3);
    mark_player_visible();

check_queue:
    read_queue_position();
    if (edi_value() > ebp_value())
        goto visit_sector;
done:
    finish_board_finalization();
}
