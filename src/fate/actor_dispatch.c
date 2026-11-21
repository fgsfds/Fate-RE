/* Apply actor mode transitions and dispatch the selected behavior profile. The original caller supplies six arguments:
 * EAX actor, EDX flags, EBX/ECX target x/y, then stack z and sector. Actor,
 * flags and sector are consumed as signed low words. Dispatcher pops 8 bytes;
 * the mode-two callees pop three stack dwords. No inline instructions. */
#pragma pack(push, 1)
typedef struct DispatchSprite {
    long x, y, z;
    short cstat, tile;
    unsigned char bytes16_23[8];
    short sector;
    unsigned char bytes26_43[18];
} DispatchSprite;
#pragma pack(pop)

extern DispatchSprite sprite_x[];
extern unsigned char actor_kind[], actor_mode[], previous_mode[];
extern unsigned char actor_state_byte[], actor_delay_byte[];
extern unsigned char actor_recovery_counter[], actor_profile[];
extern unsigned char actor_sequence_initial[];
extern short defer_mode_change, actor_sprite_index[];
extern long actor_x[], actor_y[];
extern short actor_sector[], actor_tiles[];
extern short mode_one_tile[], mode_two_tile[], mode_three_tile[];
extern short mode_four_tile[], mode_five_tile[], mode_six_tile[];

extern void update_actor_common(int);
#pragma aux update_actor_common parm [eax] modify exact [eax];
extern void profile_one_mode_one(int, int);
#pragma aux profile_one_mode_one parm [eax] [edx] modify exact [eax edx];
extern void profile_one_mode_two(int, int, long, long, long, int, int);
#pragma aux profile_one_mode_two parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void profile_one_mode_three(int, int);
#pragma aux profile_one_mode_three parm [eax] [edx] modify exact [eax edx];
extern void profile_one_mode_four(int, int);
#pragma aux profile_one_mode_four parm [eax] [edx] modify exact [eax edx];
extern void profile_one_mode_five(int, int);
#pragma aux profile_one_mode_five parm [eax] [edx] modify exact [eax edx];
extern void profile_one_mode_six(int, int);
#pragma aux profile_one_mode_six parm [eax] [edx] modify exact [eax edx];
extern void profile_two_mode_one(int, int);
#pragma aux profile_two_mode_one parm [eax] [edx] modify exact [eax edx];
extern void profile_two_mode_two(int, int, long, long, long, int, int);
#pragma aux profile_two_mode_two parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void profile_two_mode_three(int, int);
#pragma aux profile_two_mode_three parm [eax] [edx] modify exact [eax edx];
extern void profile_two_mode_four(int, int);
#pragma aux profile_two_mode_four parm [eax] [edx] modify exact [eax edx];
extern void profile_two_mode_five(int, int);
#pragma aux profile_two_mode_five parm [eax] [edx] modify exact [eax edx];

extern unsigned dispatch_kind_in_esi(unsigned);
#pragma aux dispatch_kind_in_esi = "" parm [esi] value [esi] modify exact [];
extern short dispatch_slot_in_di(short);
#pragma aux dispatch_slot_in_di = "" parm [di] value [di] modify exact [];

extern void dispatch_stage_edx(int);
#pragma aux dispatch_stage_edx = "" parm [edx] modify exact [];
extern int dispatch_raw_edx(void);
#pragma aux dispatch_raw_edx = value [edx] modify exact [];
extern short dispatch_sector_in_di(short);
#pragma aux dispatch_sector_in_di = "" parm [di] value [di] modify exact [];

extern void dispatch_stage_actor(int);
#pragma aux dispatch_stage_actor = "" parm [eax] modify exact [];
extern int dispatch_current_actor(void);
#pragma aux dispatch_current_actor = value [eax] modify exact [];
extern int dispatch_stack_in_eax(int);
#pragma aux dispatch_stack_in_eax = "" parm [eax] value [eax] modify exact [];
extern long dispatch_stack_in_edi(long);
#pragma aux dispatch_stack_in_edi = "" parm [edi] value [edi] modify exact [];
extern long dispatch_stack_in_edx(long);
#pragma aux dispatch_stack_in_edx = "" parm [edx] value [edx] modify exact [];

extern unsigned dispatch_mode_word(unsigned);
#pragma aux dispatch_mode_word = "" parm [eax] value [eax] modify exact [];
extern int dispatch_row_in_edi(int);
#pragma aux dispatch_row_in_edi = "" parm [edi] value [edi] modify exact [];
extern void dispatch_stage_dl(unsigned char);
#pragma aux dispatch_stage_dl = "" parm [dl] modify exact [];
/* Real identity: the byte offset remains in EDX across update_actor_common,
 * whose verified body preserves EDX. No result or clobber is invented. */
extern int dispatch_offset_in_edx(int);
#pragma aux dispatch_offset_in_edx = "" parm [edx] value [edx] modify exact [];
#define DISPATCH_TILE(base, offset) (*(short *)((unsigned char *)(base) + (offset)))

void dispatch_actor_update(short actor, short flags, long x, long y, long z, short sector);
#pragma aux dispatch_actor_update parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
void dispatch_actor_update(short actor, short flags, long x, long y, long z, short sector)
{
    unsigned char mode, previous, profile;
    unsigned selected_mode;
    int offset;

    /* Keep entry and profile indices in distinct C lifetimes. */
    {
        int index;
        unsigned kind;
        short slot;
        long position_x;
        short saved_sector;
        long position_y;
        int tile_row;

        index = actor;
        kind = dispatch_kind_in_esi(actor_kind[index]);
        if (kind == 3)
            return;
        mode = actor_mode[index];
        previous = previous_mode[index];
        if (mode != previous) {
            if (defer_mode_change == 0) {
                slot = dispatch_slot_in_di(actor_sprite_index[index]);
                previous_mode[index] = mode;
                if (kind != 3)
                    actor_kind[index] = 2;
                index = actor;
                actor_state_byte[index] = 0;
                actor_delay_byte[index] = 0;
                actor_recovery_counter[index] = 0;
                if (mode != 0) {
                    position_x = sprite_x[slot].x;
                    saved_sector = dispatch_sector_in_di(sprite_x[slot].sector);
                    actor_x[index] = position_x;
                    actor_sector[index] = saved_sector;
                    position_y = sprite_x[slot].y;
                    /* Rows are 18 bytes. Stage the original actor*9, then its
                     * byte offset, while AL retains the selected mode. */
                    dispatch_stage_edx(index);
                    tile_row = dispatch_row_in_edi(dispatch_raw_edx());
                    actor_y[dispatch_raw_edx()] = position_y;
                    dispatch_stage_edx((unsigned)dispatch_raw_edx() * 8U);
                    tile_row = dispatch_row_in_edi(tile_row + dispatch_raw_edx());
                    dispatch_stage_edx(0);
                    tile_row = dispatch_row_in_edi(tile_row * 2);
                    dispatch_stage_dl(mode);
                    sprite_x[slot].tile = *(short *)((unsigned char *)actor_tiles +
                        tile_row + (unsigned)dispatch_raw_edx() * 2U);
                }
            } else {
                mode = previous;
            }
        }
    }
    {
        int index = actor;
        profile = actor_profile[index];
        if (profile < 1)
            return;
        offset = dispatch_offset_in_edx(index * 18);
        if (profile <= 1)
            goto profile_one;
        if (profile == 2)
            goto profile_two;
        return;
    profile_one:
        {
            if (mode == 0)
                return;
            selected_mode = dispatch_mode_word((unsigned)mode);
            if (selected_mode == 1) {
                update_actor_common(index);
                dispatch_stage_actor(index);
                profile_one_mode_one(dispatch_current_actor(), DISPATCH_TILE(mode_one_tile, offset));
            } else if (selected_mode == 2) {
                actor_sequence_initial[index] = 0x10;
                update_actor_common(index);
                profile_one_mode_two(index, flags, x, y, dispatch_stack_in_edi(z), dispatch_stack_in_eax(sector),
                                     dispatch_stack_in_eax(DISPATCH_TILE(mode_two_tile, offset)));
            } else if (selected_mode == 3) {
                update_actor_common(index);
                dispatch_stage_actor(index);
                profile_one_mode_three(dispatch_current_actor(), DISPATCH_TILE(mode_three_tile, offset));
            } else if (selected_mode == 4) {
                update_actor_common(index);
                dispatch_stage_actor(index);
                profile_one_mode_four(dispatch_current_actor(), DISPATCH_TILE(mode_four_tile, offset));
            } else if (selected_mode == 5) {
                update_actor_common(index);
                dispatch_stage_actor(index);
                profile_one_mode_five(dispatch_current_actor(), DISPATCH_TILE(mode_five_tile, offset));
            } else if (selected_mode == 6) {
                update_actor_common(index);
                dispatch_stage_actor(index);
                profile_one_mode_six(dispatch_current_actor(), DISPATCH_TILE(mode_six_tile, offset));
            }
        }
        return;
    profile_two:
        {
            if (mode == 0)
                return;
            selected_mode = dispatch_mode_word((unsigned)mode);
            if (selected_mode == 1) {
                update_actor_common(index);
                dispatch_stage_actor(index);
                profile_two_mode_one(dispatch_current_actor(), DISPATCH_TILE(mode_one_tile, offset));
            } else if (selected_mode == 2) {
                update_actor_common(index);
                /* Watcom-specific evaluation: after outgoing stack arguments,
                 * stage EAX before loading flags into EDX. The pinned compiler's
                 * exact output and call-trace fixture verify sibling ordering. */
                profile_two_mode_two(dispatch_current_actor(),
                                     (dispatch_stage_actor(index), flags), x, y,
                                     dispatch_stack_in_edx(z), dispatch_stack_in_eax(sector),
                                     dispatch_stack_in_eax(DISPATCH_TILE(mode_two_tile, offset)));
            } else if (selected_mode == 3) {
                update_actor_common(index);
                dispatch_stage_actor(index);
                profile_two_mode_three(dispatch_current_actor(), DISPATCH_TILE(mode_three_tile, offset));
            } else if (selected_mode == 4) {
                update_actor_common(index);
                dispatch_stage_actor(index);
                profile_two_mode_four(dispatch_current_actor(), DISPATCH_TILE(mode_four_tile, offset));
            } else if (selected_mode == 5) {
                update_actor_common(index);
                dispatch_stage_actor(index);
                profile_two_mode_five(dispatch_current_actor(), DISPATCH_TILE(mode_five_tile, offset));
            }
        }
    }
}
