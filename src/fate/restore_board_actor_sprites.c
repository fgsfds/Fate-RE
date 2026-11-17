/* Rebuild the current board's sprites from saved actors and sprite templates. */
typedef struct {
    long x, y, z;
    short cstat, tile;
    unsigned char shade, palette, clip_distance, unused, xrepeat, yrepeat, xoffset, yoffset;
    short sector, status, angle, owner, xvel, yvel, zvel, lotag, hitag, extra;
} RestoredSprite;
extern RestoredSprite restored_sprite[];
extern unsigned char actor_kind[], saved_actor_board[], saved_actor_mode[];
extern signed char saved_actor_active[], restored_current_board;
extern short restored_actor_sprite[], restored_sprite_actor[];
extern short saved_actor_lotag[], restored_tile_height[], inactive_actor_tiles[];
/* GAMEDATA serializes all 0x233a bytes of the 501 nine-word tile rows. */
extern short restored_actor_tiles[501 * 9];
extern long saved_actor_x[], saved_actor_y[], saved_actor_z[], restored_actor_z_offset[], restored_sector_floor[];
extern long restored_sprite_position[];
extern unsigned char restored_sprite_interpolated[];
extern char restore_actor_error_buffer[];
extern const char restore_actor_sector_error[];
extern short restore_template_cstat[], restore_template_angle[], restore_template_status[], restore_template_hitag[];
extern short restore_template_xvel[], restore_template_yvel[], restore_template_zvel[], restore_template_owner[];
extern unsigned char restore_template_shade[], restore_template_palette[], restore_template_clip_distance[];
extern unsigned char restore_template_xrepeat[], restore_template_yrepeat[], restore_template_xoffset[], restore_template_yoffset[];

extern void update_restored_actor_sector(long, long, short *);
#pragma aux update_restored_actor_sector "updatesector_" parm [eax] [edx] [ebx] modify exact [eax ebx edx];
extern int insert_restored_actor_sprite(int, int);
#pragma aux insert_restored_actor_sprite "insertsprite_" parm [eax] [edx] modify exact [eax edx];
extern void report_game_error(const char *);
#pragma aux report_game_error parm [eax] modify exact [eax];
extern int format_actor_restore_error(void);
#pragma aux format_actor_restore_error "sprintf_" modify exact [eax];

/* Retain the original sector, template, slot, and sprite scratch locations. */
extern void begin_sprite_restore(void);
#pragma aux begin_sprite_restore = \
    "push ebx" "push ecx" "push edx" "push esi" "push edi" "push ebp" "sub esp,18h" \
    "xor edx,edx" "mov [esp+0ch],edx" modify exact [edx];
extern void end_sprite_restore(void);
#pragma aux end_sprite_restore = \
    "add esp,18h" "pop ebp" "pop edi" "pop esi" "pop edx" "pop ecx" "pop ebx" modify exact [];
extern void advance_restore_slot(void);
#pragma aux advance_restore_slot = "inc dword ptr [esp+0ch]" modify exact [];
extern long restore_slot(void);
#pragma aux restore_slot = "movsx esi,word ptr [esp+0ch]" value [esi] modify exact [esi];
extern void save_actor_template(signed char);
#pragma aux save_actor_template = "mov [esp+14h],al" parm [al] modify exact [];
extern short *restored_sector_in_ebx(void);
#pragma aux restored_sector_in_ebx = "lea ebx,[esp+4]" value [ebx] modify exact [ebx];
extern short *saved_restore_sector_pointer(void);
#pragma aux saved_restore_sector_pointer = value [ebx] modify exact [];
extern void prepare_invalid_actor_message(void);
#pragma aux prepare_invalid_actor_message = \
    "mov edx,[ecx+saved_actor_y]" "push edx" "mov ebx,[ecx+saved_actor_x]" "push ebx" "push esi" \
    "push offset restore_actor_sector_error" "push offset restore_actor_error_buffer" \
    modify exact [ebx edx];
extern void finish_invalid_actor_message(long);
#pragma aux finish_invalid_actor_message = "add esp,14h" parm [eax] modify exact [];
extern int find_restored_actor_in_ecx(void);
#pragma aux find_restored_actor_in_ecx = "movsx ecx,word ptr [esp+0ch]" value [ecx] modify exact [ecx];
extern void choose_inactive_restore_tile(void);
#pragma aux choose_inactive_restore_tile = \
    "movsx eax,word ptr [ecx*2+saved_actor_lotag]" "sar eax,8" "movsx edx,ax" \
    "mov ebx,edx" "shl ebx,4" "xor ecx,ecx" "sub ebx,edx" "mov [esp+8],ecx" \
    "mov di,[ebx*8+inactive_actor_tiles]" modify exact [eax ebx ecx edx edi];
/* Original partial-register template loads and private-frame cstat store.
   EDX is the signed template number and EBX is seven times that number. */
extern void load_active_restore_template(long, long);
#pragma aux load_active_restore_template = \
    "mov ax,[edx+ebx*4+restore_template_cstat]" "mov [esp+8],eax" \
    "xor eax,eax" "mov al,[edx+ebx*4+restore_template_yrepeat]" \
    parm [edx] [ebx] modify exact [eax];
extern void measure_sprite_tile_height(void);
#pragma aux measure_sprite_tile_height = \
    "movsx edx,di" "movsx edx,word ptr [edx*2+restored_tile_height]" "imul eax,edx" \
    "movsx edx,word ptr [esp+4]" "mov ebx,edx" "shl ebx,2" "mov esi,[ecx*4+restored_actor_z_offset]" \
    "add edx,ebx" "add eax,eax" "shl edx,3" "mov ebx,ecx" "mov edx,[edx+restored_sector_floor]" \
    modify exact [eax ebx edx esi];
extern long restore_template_number(void);
#pragma aux restore_template_number = "movsx edx,byte ptr [esp+14h]" value [edx] modify exact [edx];
extern int current_sector_in_eax(void);
#pragma aux current_sector_in_eax = "movsx eax,word ptr [esp+4]" value [eax] modify exact [eax];
extern void store_restore_sprite_index(int);
#pragma aux store_restore_sprite_index = "mov [esp],eax" parm [eax] modify exact [];
extern void stage_restore_sprite_index(void);
#pragma aux stage_restore_sprite_index = "mov eax,[esp]" "movsx ebp,ax" modify exact [eax];
extern void store_restore_sprite_short(void);
#pragma aux store_restore_sprite_short = "mov [esp+10h],ax" modify exact [];
extern long current_restore_actor(void);
#pragma aux current_restore_actor = "movsx eax,word ptr [esp+0ch]" value [eax] modify exact [eax];
extern void load_restored_cstat(void);
#pragma aux load_restored_cstat = "mov edx,[esp+8]" modify exact [edx];
extern void copy_restore_sprite_position(void);
#pragma aux copy_restore_sprite_position = "rep movsd" modify exact [ecx esi edi];
extern unsigned char restore_interpolation_bit(void);
#pragma aux restore_interpolation_bit = "mov cl,[esp+10h]" "mov al,1" "and cl,7" value [al] modify exact [eax ecx];
extern void shift_restore_interpolation_bit(void);
#pragma aux shift_restore_interpolation_bit = "shl al,cl" modify exact [eax];
extern void load_restore_slot_and_sprite(void);
#pragma aux load_restore_slot_and_sprite = "mov eax,[esp+0ch]" modify exact [eax];
extern short load_restore_sprite_number(void);
#pragma aux load_restore_sprite_number = "mov eax,[esp]" value [ax] modify exact [eax];

/* Zero-byte bindings preserve the original Watcom register assignments. */
extern long in_eax(long);
#pragma aux in_eax = parm [eax] value [eax] modify exact [];
extern long in_ebx(long);
#pragma aux in_ebx = parm [ebx] value [ebx] modify exact [];
extern long in_ecx(long);
#pragma aux in_ecx = parm [ecx] value [ecx] modify exact [];
extern long in_edx(long);
#pragma aux in_edx = parm [edx] value [edx] modify exact [];
extern long in_edi(long);
#pragma aux in_edi = parm [edi] value [edi] modify exact [];
extern long in_esi(long);
#pragma aux in_esi = parm [esi] value [esi] modify exact [];
extern short in_ax(short);
#pragma aux in_ax = parm [ax] value [ax] modify exact [];
extern short in_dx(short);
#pragma aux in_dx = parm [dx] value [dx] modify exact [];
/* The loader accepts raw mode bytes. Retain this original machine load so
   a malformed save cannot turn its unchecked address into a new C array UB. */
extern void load_active_restore_tile(long, long);
#pragma aux load_active_restore_tile = "mov di,[ebx+edi*2+restored_actor_tiles]" \
    parm [ebx] [edi] modify exact [edi];
extern unsigned char in_dl(unsigned char);
#pragma aux in_dl = parm [dl] value [dl] modify exact [];
extern unsigned char in_al(unsigned char);
#pragma aux in_al = parm [al] value [al] modify exact [];
extern long eax_value(void);
#pragma aux eax_value = value [eax] modify exact [];
extern long ebx_value(void);
#pragma aux ebx_value = value [ebx] modify exact [];
extern long ecx_value(void);
#pragma aux ecx_value = value [ecx] modify exact [];
extern long edx_value(void);
#pragma aux edx_value = value [edx] modify exact [];
extern long edi_value(void);
#pragma aux edi_value = value [edi] modify exact [];
extern long esi_value(void);
#pragma aux esi_value = value [esi] modify exact [];
extern long ebp_value(void);
#pragma aux ebp_value = value [ebp] modify exact [];
extern short ax_value(void);
#pragma aux ax_value = value [ax] modify exact [];
extern short dx_value(void);
#pragma aux dx_value = value [dx] modify exact [];
extern short di_value(void);
#pragma aux di_value = value [di] modify exact [];
extern signed char al_value(void);
#pragma aux al_value = value [al] modify exact [];

/* Branch past the diagnostic when the sector saved at ESP+4 is valid. */
extern void skip_valid_actor_sector_diagnostic(void);
#pragma aux skip_valid_actor_sector_diagnostic = \
    "cmp word ptr [esp+4],0" "db 7dh, 3ch" /* marker-rel8 +2,+3 */ modify exact [];
extern void hold_restore_eax(long);
#pragma aux hold_restore_eax = parm [eax] modify exact [];
extern void hold_restore_esi(long);
#pragma aux hold_restore_esi = parm [esi] modify exact [];
extern void hold_restore_ecx(long);
#pragma aux hold_restore_ecx = parm [ecx] modify exact [];
extern void hold_restore_edi(long);
#pragma aux hold_restore_edi = parm [edi] modify exact [];

void restore_board_actor_sprites(void);
#pragma aux restore_board_actor_sprites modify exact [eax ebx ecx edx esi edi];

void restore_board_actor_sprites(void)
{
    long row, template_number, template_offset;
    unsigned char mask;

    begin_sprite_restore();
    goto check_limit;
next:
    /* Ignore empty actor slots and actors saved for a different board. */
    save_actor_template(in_al(saved_actor_active[esi_value()]));
    if (in_eax(al_value()) == -1)
        goto advance;
    in_edx(0);
    in_eax(restored_current_board);
    in_dl(saved_actor_board[esi_value()]);
    if (edx_value() != eax_value())
        goto advance;
    in_ecx((in_ecx(esi_value()) * 4 - esi_value()) * 4);
    restored_sector_in_ebx();
    in_edx(*(const long *)((const char *)saved_actor_y + ecx_value()));
    in_eax(*(const long *)((const char *)saved_actor_x + ecx_value()));
    update_restored_actor_sector(eax_value(), edx_value(), saved_restore_sector_pointer());
    skip_valid_actor_sector_diagnostic();
    prepare_invalid_actor_message();
    format_actor_restore_error();
    in_eax(0);
    in_al(actor_kind[esi_value()]);
    finish_invalid_actor_message(eax_value());
    if (eax_value() == 3)
        goto advance;
    report_game_error(restore_actor_error_buffer);
    /* Inactive actors use their saved lotag tile and a zero cstat. */
    find_restored_actor_in_ecx();
    hold_restore_eax(eax_value());
    in_eax(0);
    in_al(actor_kind[ecx_value()]);
    if (eax_value() == 3) {
        choose_inactive_restore_tile();
    } else {
        /* The loop bounds the row to 0..500; mode is an unsigned byte.
           Template arithmetic fits even for every raw signed template byte
           (-1 was skipped above). Keep both unchecked table loads in the
           original machine helpers, rather than assume validated save data.
           The template byte is in this routine's frame at ESP+14h. */
        in_ebx(in_ebx(ecx_value()) * 8 + ecx_value());
        in_edi(saved_actor_mode[ecx_value()]);
        in_ebx(ebx_value() * 2);
        restore_template_number();
        load_active_restore_tile(ebx_value(), edi_value());
        in_ebx(in_ebx(edx_value()) * 8 - edx_value());
        load_active_restore_template(edx_value(), ebx_value());
        measure_sprite_tile_height();
        in_ebx(ebx_value() * 4);
        in_edx(edx_value() + esi_value());
        in_ebx(ebx_value() - ecx_value());
        in_edx(edx_value() - eax_value());
        saved_actor_z[ebx_value()] = edx_value();
    }

    /* Install the saved pose and the template attributes in the engine's sprite record. */
    template_number = restore_template_number();
    template_offset = in_ebx((in_ebx(template_number) * 8 - template_number) * 4 + template_number);
    current_sector_in_eax();
    in_edx(*(const short *)((const char *)restore_template_status + template_offset));
    store_restore_sprite_index(insert_restored_actor_sprite(eax_value(), edx_value()));
    stage_restore_sprite_index();
    hold_restore_esi(esi_value());
    in_esi(ebp_value() * 44);
    store_restore_sprite_short();
    row = current_restore_actor();
    row = in_ecx(in_ecx(row) * 4 - row);
    in_esi(esi_value() + (long)restored_sprite);
    ((RestoredSprite *)esi_value())->x = in_edx(saved_actor_x[row]);
    ((RestoredSprite *)esi_value())->y = in_edx(saved_actor_y[ecx_value()]);
    ((RestoredSprite *)esi_value())->z = in_edx(saved_actor_z[ecx_value()]);
    load_restored_cstat();
    ((RestoredSprite *)esi_value())->cstat = dx_value();

    ((RestoredSprite *)esi_value())->shade = in_dl(restore_template_shade[ebx_value()]);
    ((RestoredSprite *)esi_value())->palette = in_dl(restore_template_palette[ebx_value()]);
    ((RestoredSprite *)esi_value())->clip_distance = in_dl(restore_template_clip_distance[ebx_value()]);
    ((RestoredSprite *)esi_value())->xrepeat = in_dl(restore_template_xrepeat[ebx_value()]);
    ((RestoredSprite *)esi_value())->yrepeat = in_dl(restore_template_yrepeat[ebx_value()]);
    ((RestoredSprite *)esi_value())->xoffset = in_dl(restore_template_xoffset[ebx_value()]);
    ((RestoredSprite *)esi_value())->yoffset = in_dl(restore_template_yoffset[ebx_value()]);
    ((RestoredSprite *)esi_value())->tile = di_value();
    ((RestoredSprite *)esi_value())->angle = in_dx(*(const short *)((const char *)restore_template_angle + ebx_value()));
    ((RestoredSprite *)esi_value())->xvel = in_dx(*(const short *)((const char *)restore_template_xvel + ebx_value()));
    ((RestoredSprite *)esi_value())->yvel = in_dx(*(const short *)((const char *)restore_template_yvel + ebx_value()));
    ((RestoredSprite *)esi_value())->zvel = in_dx(*(const short *)((const char *)restore_template_zvel + ebx_value()));
    ((RestoredSprite *)esi_value())->owner = in_dx(*(const short *)((const char *)restore_template_owner + ebx_value()));
    in_edx(eax_value() * 2);
    ((RestoredSprite *)esi_value())->lotag = in_ax(*(const short *)((const char *)saved_actor_lotag + edx_value()));
    in_ax(*(const short *)((const char *)restore_template_hitag + ebx_value()));
    in_ebx(ebp_value());
    in_ebx(ebx_value() * 4);
    hold_restore_ecx(ecx_value());
    in_ecx(3);
    in_ebx(ebx_value() - ebp_value());
    hold_restore_edi(edi_value());
    in_edi((long)restored_sprite_position);
    in_ebx(ebx_value() * 4);
    ((RestoredSprite *)esi_value())->extra = 0;
    in_edi(edi_value() + ebx_value());
    ((RestoredSprite *)esi_value())->hitag = ax_value();
    copy_restore_sprite_position();

    /* Clear interpolation state and publish both actor-to-sprite indices. */
    mask = restore_interpolation_bit();
    in_ebx(ebp_value());
    shift_restore_interpolation_bit();
    in_ebx(ebx_value() >> 3);
    mask = in_al(~al_value());
    restored_sprite_interpolated[ebx_value()] &= mask;
    load_restore_slot_and_sprite();
    restored_sprite_actor[ebp_value()] = ax_value();
    *(short *)((char *)restored_actor_sprite + edx_value()) = load_restore_sprite_number();

advance:
    advance_restore_slot();
check_limit:
    if (restore_slot() <= 500)
        goto next;
    end_sprite_restore();
}
