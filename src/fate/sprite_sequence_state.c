extern short sequence_actor_sprite[], sequence_actor_sector[], sequence_tile_height[];
extern long sequence_actor_x[], sequence_actor_y[], sequence_actor_z_offset[];
extern unsigned char actor_kind[], sequence_actor_state[], sequence_actor_flag[];
extern unsigned char sequence_actor_first[], sequence_actor_frame[];
extern short sequence_sprite_tile[], advance_clock;
extern unsigned char sequence_sprite_yrepeat[];
extern long sector_floor_z[];
extern void updatesector(long x, long y, short *sector);
#pragma aux updatesector parm [eax] [edx] [ebx] modify exact [eax ebx ecx];
extern int setsprite(int sprite, long x, long y, long z);
#pragma aux setsprite parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];

extern int actor_index_in_esi(void);
#pragma aux actor_index_in_esi = value [esi] modify exact [];

extern short seq_saved_ax(void);
#pragma aux seq_saved_ax = "" value [ax] modify exact [];
extern void advance_moved_actor(int, long, long, int, long, long);
#pragma aux advance_moved_actor "move_actor_" parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];

extern int sequence_eax(int);
#pragma aux sequence_eax = "" parm [eax] value [eax] modify exact [];
extern int sequence_edx(int);
#pragma aux sequence_edx = "" parm [edx] value [edx] modify exact [];
extern void sequence_set_edi(int);
#pragma aux sequence_set_edi = "" parm [edi] modify exact [];
extern int sequence_edi(void);
#pragma aux sequence_edi = "" value [edi] modify exact [];
extern int sequence_saved_eax(void);
#pragma aux sequence_saved_eax = "" value [eax] modify exact [];
extern int sequence_saved_edx(void);
#pragma aux sequence_saved_edx = "" value [edx] modify exact [];
extern short sequence_saved_bx(void);
#pragma aux sequence_saved_bx = "" value [bx] modify exact [];
extern short sequence_ax(short);
#pragma aux sequence_ax = "" parm [ax] value [ax] modify exact [];
extern short sequence_dx(short);
#pragma aux sequence_dx = "" parm [dx] value [dx] modify exact [];
extern unsigned char sequence_bh(unsigned char);
#pragma aux sequence_bh = "" parm [bh] value [bh] modify exact [];
extern unsigned char sequence_cl(unsigned char);
#pragma aux sequence_cl = "" parm [cl] value [cl] modify exact [];
extern unsigned char sequence_ah(unsigned char);
#pragma aux sequence_ah = "" parm [ah] value [ah] modify exact [];
extern unsigned char sequence_dl(unsigned char);
#pragma aux sequence_dl = "" parm [dl] value [dl] modify exact [];
extern void sequence_al_set(unsigned char);
#pragma aux sequence_al_set = "" parm [al] modify exact [];
extern void sequence_zero_eax(int);
#pragma aux sequence_zero_eax = "" parm [eax] modify exact [eax];

extern void keep_frame_before_zero(unsigned char);
#pragma aux keep_frame_before_zero = "" parm [dl] modify exact [eax];

extern int seq_from_ecx(void);
#pragma aux seq_from_ecx = "" value [ecx] modify exact [];
extern int seq_ecx(int);
#pragma aux seq_ecx = "" parm [ecx] value [ecx] modify exact [];
extern int seq_ebx(int);
#pragma aux seq_ebx = "" parm [ebx] value [ebx] modify exact [];
extern int seq_from_ebx(void);
#pragma aux seq_from_ebx = "" value [ebx] modify exact [];
extern short *seq_sector_ptr(short *);

extern unsigned char seq_ch(unsigned char);
#pragma aux seq_ch = "" parm [ch] value [ch] modify exact [];
extern unsigned char seq_al(void);
#pragma aux seq_al = "" value [al] modify exact [];
#pragma aux seq_sector_ptr = "" parm [ebx] value [ebx] modify exact [];
extern void finish_anchor_x_store(void);
#pragma aux finish_anchor_x_store = "" modify exact [ebx];
extern short *saved_seq_sector(void);
#pragma aux saved_seq_sector = "" value [ebx] modify exact [];

extern void seq_stage_actor(int);
#pragma aux seq_stage_actor = "" parm [esi] modify exact [];
extern short seq_actor_word(void);
#pragma aux seq_actor_word = "" value [si] modify exact [];
extern void seq_set_sprite(short);
#pragma aux seq_set_sprite = "" parm [bx] modify exact [];
extern int seq_kind_in_edi(int);
#pragma aux seq_kind_in_edi = "" parm [edi] value [edi] modify exact [];
extern const short *table_in_eax(const short *);
#pragma aux table_in_eax = "" parm [eax] value [eax] modify exact [];
extern const short *table_in_edx(const short *);
#pragma aux table_in_edx = "" parm [edx] value [edx] modify exact [];

extern void update_sprite_sequence_state(int, long, long, long, long, const short *);
#pragma aux update_sprite_sequence_state parm routine [eax] [edx] [ebx] [ecx] \
    modify exact [eax ebx ecx edx];

void update_sprite_sequence_state(int actor, long x, long y, long turn_x, long turn_y, const short *tiles)
{
    int kind, state, saved_index, sprite_offset;
    struct {
        volatile int sprite, sector_offset;
    } saved;
    short display_tile;
    unsigned char frame, new_state;
    const short *tile_table;
    int sector_offset, height;
    short *sector_pointer;
    unsigned char cleared;

    /* Fallen actors stay fixed. Hit reactions always select the third table entry. */
    seq_stage_actor(sequence_saved_eax());
    sequence_eax(sequence_saved_edx());
    sequence_edx(seq_from_ebx());
    seq_stage_actor(seq_actor_word());
    saved_index = seq_ebx(actor_index_in_esi() * 2);
    kind = seq_kind_in_edi(actor_kind[actor_index_in_esi()]);
    saved.sector_offset = saved_index;
    seq_set_sprite(*(short *)((char *)sequence_actor_sprite + seq_from_ebx()));
    if (kind == 3)
        goto done;
    if (kind == 4)
        goto reaction;
    if (kind != 5)
        goto initialize;
reaction:
    sequence_eax(sequence_eax(sequence_saved_bx()) * 44);
    tile_table = table_in_edx(tiles);
    display_tile = sequence_dx(tile_table[2]);
    *(short *)((char *)sequence_sprite_tile + sequence_saved_eax()) = display_tile;
    goto done;

initialize:
    sequence_set_edi(actor_index_in_esi());
    sequence_set_edi(sequence_edi() * 4);
    if (sequence_actor_state[actor_index_in_esi()] != 0)
        goto active;
    cleared = seq_ch(0);
    sector_pointer = seq_sector_ptr(sequence_actor_sector);
    sequence_actor_flag[actor_index_in_esi()] = cleared;
    seq_ecx(saved.sector_offset);
    /* Keep each assignment result in its original value register; otherwise
     * Watcom introduces a temporary before the store. No inline code needed. */
    sequence_eax(*(long *)((char *)sequence_actor_x + sequence_edi()) = sequence_saved_eax());
    /* Resolve the sector pointer after storing the X anchor. */
    finish_anchor_x_store();
    sector_pointer = seq_sector_ptr((short *)((char *)saved_seq_sector() + seq_from_ecx()));
    sequence_edx(*(long *)((char *)sequence_actor_y + sequence_edi()) = sequence_saved_edx());
    updatesector(sequence_saved_eax(), sequence_saved_edx(), sector_pointer);
    tile_table = table_in_eax(tiles);
    sequence_al_set(*(unsigned char *)tile_table);
    sequence_actor_first[actor_index_in_esi()] = seq_al();
    sequence_actor_state[actor_index_in_esi()] = 1;
    goto done;

active:
    sequence_zero_eax(0);
    sequence_al_set(sequence_actor_state[actor_index_in_esi()]);
    state = sequence_saved_eax();
    if (state != 1)
        goto animate;
    /* Save the sprite index for placement after the actor moves. */
    sequence_eax(sequence_saved_bx());
    saved.sprite = sequence_saved_eax();
    sprite_offset = sequence_saved_eax() * 44;
    (void)table_in_eax(tiles);
    sequence_ax(*(short *)(sequence_saved_eax() + 2));
    *(short *)((char *)sequence_sprite_tile + sprite_offset) = seq_saved_ax();
    /* Let the compiler own both stack arguments and the intervening frame
     * reload, while empty ABI constraints retain the original argument order. */
    advance_moved_actor(
        sequence_saved_eax(), sequence_saved_edx(), seq_from_ebx(),
        (seq_ecx(saved.sector_offset),
         seq_ebx(*(long *)((char *)sequence_actor_y + sequence_edi())),
         sequence_eax(actor_index_in_esi()),
         seq_ecx(*(short *)((char *)sequence_actor_sector + seq_from_ecx()))),
        (sequence_edx(*(long *)((char *)sequence_actor_x + sequence_edi())), seq_from_ecx()),
        sequence_eax(turn_y));
    if (actor_kind[actor_index_in_esi()] != 0)
        goto done;
    /* Keep the base of the scaled tile at the actor's anchor height. */
    height = sequence_eax(*(short *)((char *)sequence_sprite_tile + sprite_offset));
    sequence_edx(sequence_tile_height[height]);
    sequence_zero_eax(0);
    sequence_al_set(sequence_sprite_yrepeat[sprite_offset]);
    seq_ecx(sequence_saved_eax());
    seq_ecx(seq_from_ecx() * sequence_saved_edx());
    sector_offset = sequence_edx(saved.sector_offset);
    sequence_edx(*(short *)((char *)sequence_actor_sector + sector_offset));
    sequence_eax(sequence_saved_edx());
    sequence_eax(sequence_saved_eax() * 5);
    sequence_eax(sector_floor_z[sequence_saved_eax() * 2]);
    sequence_edx(*(long *)((char *)sequence_actor_z_offset + sequence_edi()));
    seq_ecx(seq_from_ecx() * 2);
    sequence_eax(sequence_saved_eax() + sequence_saved_edx());
    seq_ebx(*(long *)((char *)sequence_actor_y + sequence_edi()));
    sequence_eax(sequence_saved_eax() - seq_from_ecx());
    sequence_edx(*(long *)((char *)sequence_actor_x + sequence_edi()));
    seq_ecx(sequence_saved_eax());
    setsprite(sequence_eax(saved.sprite), sequence_saved_edx(), seq_from_ebx(), seq_from_ecx());
    if (!advance_clock)
        goto done;
    frame = sequence_bh(3);
    tile_table = table_in_eax(tiles);
    sequence_actor_frame[actor_index_in_esi()] = frame;
    display_tile = sequence_ax(tile_table[3]);
    new_state = sequence_cl(2);
    *(short *)((char *)sequence_sprite_tile + sprite_offset) = display_tile;
    sequence_actor_state[actor_index_in_esi()] = new_state;
    goto done;

animate:
    /* A sequence ends on a -1 tile and resets its state on the following update. */
    if (state != 2)
        goto reset;
    if (!advance_clock)
        goto done;
    frame = sequence_dl(sequence_actor_frame[actor_index_in_esi()]);
    /* Zero-extend the next frame after reading the current byte. */
    keep_frame_before_zero(frame);
    sequence_zero_eax(0);
    frame = sequence_dl(frame + 1);
    sequence_al_set(frame);
    sequence_actor_frame[actor_index_in_esi()] = frame;
    tile_table = table_in_edx(tiles);
    sequence_eax(sequence_saved_eax() * 2);
    sequence_eax(sequence_saved_eax() + (int)tile_table);
    if (sequence_edx(*(short *)sequence_saved_eax()) != -1)
        goto show;
    sequence_actor_state[actor_index_in_esi()] = 3;
    goto done;
show:
    sequence_edx(sequence_edx(sequence_saved_bx()) * 44);
    display_tile = sequence_ax(*(short *)sequence_saved_eax());
    *(short *)((char *)sequence_sprite_tile + sequence_saved_edx()) = display_tile;
    goto done;
reset:
    if (state != 3)
        goto done;
    sequence_actor_state[actor_index_in_esi()] = sequence_ah(0);
done:
    return;
}
