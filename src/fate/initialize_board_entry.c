/* Create a missing player sprite and install its board-entry palette ramp. */
typedef struct {
    long x, y, z;
    short cstat, tile;
    unsigned char shade, palette, clip_distance, filler, xrepeat, yrepeat, xoffset, yoffset;
    short sector, status, angle, owner, xvel, yvel, zvel, lotag, hitag, extra;
} PlayerEntrySprite;
extern PlayerEntrySprite board_player_sprites[];
extern short board_player_sprite[], board_player_sector[], board_player_angle[];
extern long board_player_x[], board_player_y[], board_player_z[], board_player_positions[];
extern unsigned char board_sprite_visibility[], board_player_palette[], board_player_ramp[];
extern char board_player_palette_dispatch[];

extern int insert_board_sprite(int, int);
#pragma aux insert_board_sprite "insertsprite_" parm [eax] [edx] modify exact [eax edx];
extern void make_board_player_palookup(void);
#pragma aux make_board_player_palookup "makepalookup_" modify exact [eax ebx ecx edx];

/* The palette paths share these saved registers and the original player index. */
extern void begin_board_entry(int);
#pragma aux begin_board_entry = \
    "push ebx" "push ecx" "push edx" "push esi" "push edi" "push eax" \
    parm [eax] modify exact [];
extern void end_board_entry_frame(void);
#pragma aux end_board_entry_frame = \
    "add esp,4" "pop edi" "pop esi" "pop edx" "pop ecx" "pop ebx" modify exact [];
extern void board_entry_finish(void);
extern void board_entry_default_palette(void);
extern void board_entry_has_sprite(void);
#pragma aux board_entry_has_sprite = \
    "cmp word ptr [ebx+board_player_sprite],0" "jge near board_entry_finish" modify exact [];
/* The seven-entry CS-relative ramp table stays at its original code offset. */
extern void dispatch_board_entry_palette(long);
#pragma aux dispatch_board_entry_palette = \
    "db 66h,3dh,6,0" "ja near board_entry_default_palette" "and eax,0ffffh" \
    "jmp dword ptr cs:[eax*4+board_player_palette_dispatch]" parm [eax] aborts modify exact [eax];
extern void read_board_player_palette(void);
#pragma aux read_board_player_palette = "mov al,[esp]" modify exact [eax];
extern long read_board_player(void);
#pragma aux read_board_player = "mov eax,[esp]" value [eax] modify exact [eax];
extern short make_board_player_owner(void);
#pragma aux make_board_player_owner = "add ah,10h" value [ax] modify exact [eax];
extern void backup_board_player_position(void);
#pragma aux backup_board_player_position = "rep movsd" modify exact [ecx esi edi];
extern void reveal_board_player(void);
#pragma aux reveal_board_player = \
    "movsx eax,word ptr [ebx+board_player_sprite]" "mov cl,byte ptr [ebx+board_player_sprite]" \
    "mov bl,1" "and cl,7" "sar eax,3" "shl bl,cl" \
    "mov dl,[eax+board_sprite_visibility]" "not bl" "and dl,bl" \
    "mov [eax+board_sprite_visibility],dl" modify exact [eax ebx ecx edx];
extern void board_player_palette_finish(void);
#pragma aux board_player_palette_finish aborts modify exact [];
extern void set_board_player_palette_args(void);
#pragma aux set_board_player_palette_args = \
    "push 1" "movsx eax,word ptr [esp+4]" "mov edx,offset board_player_palette" "push 0" \
    modify exact [eax edx];

/* Zero-byte bindings preserve the original Watcom register assignments. */
extern long in_eax(long);
#pragma aux in_eax = parm [eax] value [eax] modify exact [];
extern long in_ebx(long);
#pragma aux in_ebx = parm [ebx] value [ebx] modify exact [];
extern long in_ecx(long);
#pragma aux in_ecx = parm [ecx] value [ecx] modify exact [];
extern long in_edx(long);
#pragma aux in_edx = parm [edx] value [edx] modify exact [];
extern long in_esi(long);
#pragma aux in_esi = parm [esi] value [esi] modify exact [];
extern long in_edi(long);
#pragma aux in_edi = parm [edi] value [edi] modify exact [];
extern unsigned char in_bl(unsigned char);
#pragma aux in_bl = parm [bl] value [bl] modify exact [];
extern short in_ax(short);
#pragma aux in_ax = parm [ax] value [ax] modify exact [];
extern long eax_value(void);
#pragma aux eax_value = value [eax] modify exact [];
extern long ebx_value(void);
#pragma aux ebx_value = value [ebx] modify exact [];
extern long edi_value(void);
#pragma aux edi_value = value [edi] modify exact [];
extern long esi_value(void);
#pragma aux esi_value = value [esi] modify exact [];
extern short ax_value(void);
#pragma aux ax_value = value [ax] modify exact [];
extern unsigned char al_value(void);
#pragma aux al_value = value [al] modify exact [];
extern unsigned char bl_value(void);
#pragma aux bl_value = value [bl] modify exact [];

extern void hold_board_eax(long);
#pragma aux hold_board_eax = parm [eax] modify exact [];
extern void hold_board_ecx(long);
#pragma aux hold_board_ecx = parm [ecx] modify exact [];
extern void hold_board_edx(long);
#pragma aux hold_board_edx = parm [edx] modify exact [];
extern long from_board_ecx(void);
#pragma aux from_board_ecx = value [ecx] modify exact [];
extern long from_board_edx(void);
#pragma aux from_board_edx = value [edx] modify exact [];

extern long y_position_in_edi(void);
#pragma aux y_position_in_edi = "mov edi,[eax*4+board_player_y]" value [edi] modify exact [edi];

void initialize_board_entry(int);
#pragma aux initialize_board_entry parm [eax] aborts modify exact [eax ebx ecx edx esi edi];
void initialize_board_entry(int player_index)
{
    long offset, index, tile_z;

    begin_board_entry(player_index);
    index = in_edi(ax_value());
    in_ebx(index * 2);
    board_entry_has_sprite();
    hold_board_edx(from_board_edx());
    in_edx(8);
    in_eax(*(const short *)((const char *)board_player_sector + ebx_value()));
    *(short *)((char *)board_player_sprite + ebx_value()) = in_ax(insert_board_sprite(eax_value(), 8));
    offset = in_eax(in_eax(ax_value()) * 44);
    in_esi((long)board_player_sprites);
    in_esi(esi_value() + offset);
    in_eax(edi_value());
    ((PlayerEntrySprite *)esi_value())->x = in_edi(board_player_x[edi_value()]);
    ((PlayerEntrySprite *)esi_value())->y = y_position_in_edi();
    tile_z = in_eax(board_player_z[eax_value()]);
    /* The player sprite keeps its original position and default render state. */
    ((PlayerEntrySprite *)esi_value())->cstat = 0x101;
    ((PlayerEntrySprite *)esi_value())->shade = 0;
    ((PlayerEntrySprite *)esi_value())->clip_distance = 32;
    ((PlayerEntrySprite *)esi_value())->xrepeat = 64;
    ((PlayerEntrySprite *)esi_value())->yrepeat = 64;
    ((PlayerEntrySprite *)esi_value())->xoffset = 0;
    ((PlayerEntrySprite *)esi_value())->yoffset = 0;
    hold_board_eax(eax_value());
    tile_z = in_eax(eax_value() + 8192);
    ((PlayerEntrySprite *)esi_value())->tile = 120;
    ((PlayerEntrySprite *)esi_value())->z = tile_z;
    read_board_player_palette();
    ((PlayerEntrySprite *)esi_value())->palette = al_value();
    in_ax(*(const short *)((const char *)board_player_angle + ebx_value()));
    ((PlayerEntrySprite *)esi_value())->xvel = 0;
    ((PlayerEntrySprite *)esi_value())->yvel = 0;
    ((PlayerEntrySprite *)esi_value())->zvel = 0;
    ((PlayerEntrySprite *)esi_value())->lotag = 0;
    ((PlayerEntrySprite *)esi_value())->hitag = 0;
    ((PlayerEntrySprite *)esi_value())->angle = ax_value();
    read_board_player();
    ((PlayerEntrySprite *)esi_value())->extra = 0;
    ((PlayerEntrySprite *)esi_value())->owner = make_board_player_owner();
    index = in_edi(*(const short *)((const char *)board_player_sprite + ebx_value()));
    offset = in_eax(in_eax(index) * 4 - index);
    in_edi((long)board_player_positions);
    in_eax(offset * 4);
    hold_board_ecx(from_board_ecx());
    in_ecx(3);
    in_edi(edi_value() + eax_value());
    backup_board_player_position();
    reveal_board_player();
    dispatch_board_entry_palette(in_eax(read_board_player() - 1));
}

/* The seven cases replace the same 32-entry ramp with different base colors. */
#define DEFINE_BOARD_PALETTE(name, color, finish) \
void name(void) \
{ \
    unsigned char entry; \
    in_eax(0); \
    goto check; \
next: \
    entry = in_bl(al_value()); \
    in_eax(eax_value() + 1); \
    entry = in_bl(entry + color); \
    board_player_ramp[eax_value()] = entry; \
check: \
    if (eax_value() < 32) \
        goto next; \
    finish(); \
}

/* The final four entries have short jumps to the shared palette finish. */
extern void finish_board_palette_4(void);
#pragma aux finish_board_palette_4 = "db 0ebh,57h" aborts modify exact [];
extern void finish_board_palette_5(void);
#pragma aux finish_board_palette_5 = "db 0ebh,40h" aborts modify exact [];
extern void finish_board_palette_6(void);
#pragma aux finish_board_palette_6 = "db 0ebh,29h" aborts modify exact [];
extern void finish_board_palette_7(void);
#pragma aux finish_board_palette_7 = "db 0ebh,12h" aborts modify exact [];
#pragma aux board_entry_palette_1 modify exact [eax ebx];
#pragma aux board_entry_palette_2 modify exact [eax ebx];
#pragma aux board_entry_palette_3 modify exact [eax ebx];
#pragma aux board_entry_palette_4 aborts modify exact [eax ebx];
#pragma aux board_entry_palette_5 aborts modify exact [eax ebx];
#pragma aux board_entry_palette_6 aborts modify exact [eax ebx];
#pragma aux board_entry_palette_7 aborts modify exact [eax ebx];
DEFINE_BOARD_PALETTE(board_entry_palette_1, 0x80, board_player_palette_finish)
DEFINE_BOARD_PALETTE(board_entry_palette_2, 0x20, board_player_palette_finish)
DEFINE_BOARD_PALETTE(board_entry_palette_3, 0xe0, board_player_palette_finish)
DEFINE_BOARD_PALETTE(board_entry_palette_4, 0x40, finish_board_palette_4)
DEFINE_BOARD_PALETTE(board_entry_palette_5, 0x60, finish_board_palette_5)
DEFINE_BOARD_PALETTE(board_entry_palette_6, 0xa0, finish_board_palette_6)
DEFINE_BOARD_PALETTE(board_entry_palette_7, 0xc0, finish_board_palette_7)

#pragma aux board_entry_default_palette modify exact [eax ebx ecx edx esi edi];
void board_entry_default_palette(void)
{
    in_eax(0);
    goto check;
next:
    board_player_palette[eax_value()] = al_value();
    in_eax(eax_value() + 1);
check:
    if (eax_value() < 256)
        goto next;
    set_board_player_palette_args();
    in_ecx(0);
    in_ebx(0);
    make_board_player_palookup();
    end_board_entry_frame();
}
