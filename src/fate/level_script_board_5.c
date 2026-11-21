extern short board5_actor_steps[], board5_actors[], board5_script_sprites[], player_sector, advance_clock;
extern short sequence_actor_sector[], sequence_actor_sprite[];
extern short sequence_sprite_tile[];
extern unsigned char hit_sprite_lotag[];
extern long board5_target_x[], board5_target_y[], player_x, player_y;
extern unsigned char actor_kind[], sequence_actor_flag[];
extern short saved_actor_lotag[];
extern void play_sound(int sound, long x, long y, int repeat);
#pragma aux play_sound parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void start_sequence(int sprite);
#pragma aux start_sequence parm [eax] modify exact [eax];
extern void updatesector(long x, long y, short *sector);
#pragma aux updatesector parm [eax] [edx] [ebx] modify exact [eax ebx edx];

extern int moving_board5_actor_index(void);
#pragma aux moving_board5_actor_index = value [edi] modify exact [];

extern int board5_in_eax(int);
#pragma aux board5_in_eax = "" parm [eax] value [eax] modify exact [];
extern int board5_in_ecx(int);
#pragma aux board5_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern int board5_in_ebx(int);
#pragma aux board5_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern unsigned char board5_in_bl(unsigned char);
#pragma aux board5_in_bl = "" parm [bl] value [bl] modify exact [];
extern int saved_board5_eax(void);
#pragma aux saved_board5_eax = "" value [eax] modify exact [];
extern int saved_board5_ecx(void);
#pragma aux saved_board5_ecx = "" value [ecx] modify exact [];
extern int saved_board5_edx(void);
#pragma aux saved_board5_edx = "" value [edx] modify exact [];
extern void stage_board5_sound(int,int,int);
#pragma aux stage_board5_sound = "" parm [eax] [edx] [ecx] modify exact [];
extern void finish_board5_step_stores(short);
#pragma aux finish_board5_step_stores = "" parm [bx] modify exact [ebx];

extern void board5_set_edx(int);
#pragma aux board5_set_edx = "" parm [edx] modify exact [];
extern void board5_set_al(unsigned char);
#pragma aux board5_set_al = "" parm [al] modify exact [];
extern short board5_in_bx(short);
#pragma aux board5_in_bx = "" parm [bx] value [bx] modify exact [];
extern short board5_in_ax(short);
#pragma aux board5_in_ax = "" parm [ax] value [ax] modify exact [];
extern void prepare_activation(int,int);
#pragma aux prepare_activation = "" parm [esi] [ecx] modify exact [];
extern short board5_cx(void);
#pragma aux board5_cx = "" value [cx] modify exact [];
extern short board5_si(void);
#pragma aux board5_si = "" value [si] modify exact [];

extern int board5_in_edi(int);
#pragma aux board5_in_edi = "" parm [edi] value [edi] modify exact [];
extern int board5_in_edx(int);
#pragma aux board5_in_edx = "" parm [edx] value [edx] modify exact [];
extern short saved_board5_bx(void);
#pragma aux saved_board5_bx = "" value [bx] modify exact [];
extern unsigned char board5_in_ah(unsigned char);
#pragma aux board5_in_ah = "" parm [ah] value [ah] modify exact [];
extern unsigned char board5_in_dl(unsigned char);
#pragma aux board5_in_dl = "" parm [dl] value [dl] modify exact [];
extern short *board5_pointer_in_ebx(short *);
#pragma aux board5_pointer_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern short *saved_board5_pointer(void);
#pragma aux saved_board5_pointer = "" value [ebx] modify exact [];
extern int saved_board5_esi(void);
#pragma aux saved_board5_esi = "" value [esi] modify exact [];

extern void stage_tile_lotag(unsigned char);
#pragma aux stage_tile_lotag = "" parm [ah] modify exact [];
extern unsigned char staged_tile_lotag(void);
#pragma aux staged_tile_lotag = "" value [ah] modify exact [];

extern void finish_tile_store(void);
#pragma aux finish_tile_store = "" modify exact [eax];

/* Watcom schedules Y before X in the declaration to match their register loads. */
extern void move_board5_native(int actor, long y, long x, int sector, long turn_x, long turn_y);
#pragma aux move_board5_native "move_actor_" parm routine [eax] [ebx] [edx] [ecx] modify exact [eax ebx ecx edx];
extern int turn_x_after_sector(int turn_x, int sector);
#pragma aux turn_x_after_sector = "" parm [ebx] [ecx] value [ebx] modify exact [];

extern int board5_in_esi(int);
#pragma aux board5_in_esi = "" parm [esi] value [esi] modify exact [];

extern void stage_board5_target_x(int);
#pragma aux stage_board5_target_x = "" parm [eax] modify exact [];

extern void update_board_5_script(void);
#pragma aux update_board_5_script modify exact [eax];

void update_board_5_script(void)
{
    int sector, step;
    short first_step, final_step;
    unsigned char mode;
    short actor_slot, sprite_slot;
    int sprite, offset, actor_kind_value, moved, actor_offset;
    short movement_tile;
    unsigned char lowtag;
    short *target_sector;
    long turn_x, turn_y;
    int move_actor_id, movement_offset, movement_slot;
    union {
        volatile int whole;
        volatile short word;
    } actor;

    if (board5_actor_steps[0] != 0)
        goto actors;
    sector = board5_in_eax(player_sector);
    if (sector == 0xec)
        goto start;
    if (sector == 0xed)
        goto start;
    if (sector != 0xee)
        goto actors;
start:
    /* Start all four actors together, then play the board's cue. */
    first_step = board5_in_ebx(1);
    stage_board5_sound(0x8e, 0, 0);
    board5_actor_steps[0] = first_step;
    board5_actor_steps[1] = first_step;
    board5_actor_steps[2] = first_step;
    board5_actor_steps[3] = first_step;
    finish_board5_step_stores(first_step);
    play_sound(saved_board5_eax(), saved_board5_edx(), 0, saved_board5_ecx());
actors:
    /* The original frame increments the full counter and reads its low word. */
    actor.whole = board5_in_eax(0);
    goto count;
update_actor:
    /* Use the actor slot as a byte offset into the parallel short arrays. */
    board5_set_edx(saved_board5_edx() * 2);
    actor_slot = board5_in_bx(*(short *)((char *)board5_actors + saved_board5_edx()));
    actor_kind_value = board5_in_eax(actor_slot);
    board5_set_al(actor_kind[actor_kind_value]);
    if (board5_in_eax((unsigned char)saved_board5_eax()) == 3)
        goto advance;
    step = board5_in_eax(*(short *)((char *)board5_actor_steps + saved_board5_edx()));
    if (step != 1)
        goto delay;
    sprite_slot = board5_in_ax(*(short *)((char *)board5_script_sprites + saved_board5_edx()));
    sprite = board5_in_eax(sprite_slot);
    offset = board5_in_ebx(sprite * 44);
    prepare_activation(2, 0x4400);
    *(short *)(hit_sprite_lotag + offset) = board5_cx();
    start_sequence(saved_board5_eax());
    *(short *)((char *)board5_actor_steps + saved_board5_edx()) = board5_si();
    goto advance;
delay:
    /* Stagger the movement until the actor's scripted delay finishes. */
    if (step < 2 || step > 7)
        goto movement;
    if (!advance_clock)
        goto advance;
    ++*(short *)((char *)board5_actor_steps + saved_board5_edx());
    goto advance;
movement:
    movement_slot = board5_in_esi(actor.word);
    movement_offset = movement_slot * 2;
    if (board5_in_eax(*(short *)((char *)board5_actor_steps + movement_offset)) != 8)
        goto advance;
    /* Change the sprite tile and propagate its low lotag flags. */
    moved = board5_in_edi(saved_board5_bx());
    actor_offset = board5_in_ecx(moved * 2);
    offset = board5_in_edx(*(short *)((char *)sequence_actor_sprite + actor_offset));
    offset = board5_in_edx(offset * 44);
    movement_tile = (short)board5_in_ebx(0x91b);
    stage_tile_lotag(hit_sprite_lotag[offset]);
    *(short *)((char *)sequence_sprite_tile + offset) = movement_tile;
    /* Finish the tile store before updating the tag byte. */
    finish_tile_store();
    lowtag = board5_in_ah(staged_tile_lotag() | 0x65);
    target_sector = board5_pointer_in_ebx(sequence_actor_sector);
    hit_sprite_lotag[offset] = lowtag;
    /* Resolve the destination sector for this actor's scripted coordinates. */
    lowtag = board5_in_dl(*((unsigned char *)saved_actor_lotag + saved_board5_ecx()));
    target_sector = board5_pointer_in_ebx((short *)((char *)saved_board5_pointer() + saved_board5_ecx()));
    lowtag = board5_in_dl(lowtag | 0x65);
    stage_board5_target_x(board5_target_x[saved_board5_esi() * 2]);
    *((unsigned char *)saved_actor_lotag + saved_board5_ecx()) = lowtag;
    updatesector(saved_board5_eax(), board5_target_y[saved_board5_esi() * 2], target_sector);
    turn_y = board5_in_edx(player_y);
    turn_x = board5_in_ebx(player_x);
    move_actor_id = board5_in_eax(moving_board5_actor_index());
    move_board5_native(move_actor_id,
                       board5_target_y[saved_board5_esi() * 2],
                       board5_target_x[saved_board5_esi() * 2],
                       saved_board5_ecx(),
                       turn_x_after_sector(turn_x, *(short *)((char *)sequence_actor_sector + saved_board5_ecx())),
                       turn_y);
    if (actor_kind[moving_board5_actor_index()] != 0)
        goto advance;
    mode = board5_in_bl(2);
    final_step = board5_in_ecx(9);
    sequence_actor_flag[moving_board5_actor_index()] = mode;
    *(short *)((char *)board5_actor_steps + movement_offset) = final_step;
advance:
    ++actor.whole;
count:
    if (board5_in_edx(actor.word) <= 3)
        goto update_actor;
    return;
}
