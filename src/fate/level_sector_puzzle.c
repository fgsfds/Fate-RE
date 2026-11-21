/* Board-three floor-tile puzzle and key/exit triggers.
 * Record views begin at the named field. Watcom 10.5 compiles this algorithm
 * twice: entry/tail and activation contexts. Only three consecutive verified
 * phases are linked; five existing jumps receive displacement-only binding.
 * Empty auxiliaries stage actual C values and emit no assembly instructions.
 * The activation callee preserves EDX, including the zero tag carried through
 * that call. Packed indices assume valid game data; signed narrowing follows
 * the historical compiler's 16-bit behavior.
 */
#ifdef PUZZLE_ACTIVATION_CONTEXT
#define update_level_sector_puzzle puzzle_activation_context
#endif
#pragma pack(push, 1)
typedef struct { short tile; char remainder[38]; } PuzzleSectorTile;
typedef struct { short tile; char remainder[42]; } PuzzleSpriteTile;
typedef struct { short sprite; unsigned short target; } PuzzleTrigger;
typedef struct { long x, y, z; } PuzzlePosition;
#pragma pack(pop)

extern PuzzleSectorTile sector_floor_tile[];
extern PuzzleSpriteTile sprite_tile[];
extern PuzzleTrigger trigger_sprite[];
extern short sector_14_lotag, sector_15_lotag, sector_30_lotag;
extern short sector_30_wall_start, sector_30_wall_count;
extern short sector_107_floor_tile, sector_108_floor_tile, sector_109_floor_tile;
extern short trigger_count, wall_tile, transition_marker;
extern unsigned char destination_level;
extern long player_x, player_y, last_tile_step, game_clock;
extern long puzzle_solved, key_sprite_consumed;
extern long previous_effect_active, effect_active;
extern PuzzlePosition effect_x;
extern long effect_y, destination_x, destination_y;

extern long absolute_long(long);
#pragma aux absolute_long parm [eax] value [eax] modify exact [eax];
extern void activate_sector(long);
#pragma aux activate_sector parm [eax] modify exact [eax];
#ifdef PUZZLE_ACTIVATION_CONTEXT
/* The sector-activation callee returns with the incoming EDX intact. */
extern int activate_sector_carry_tag(long sector, int clear_tag);
#pragma aux activate_sector_carry_tag "activate_sector_" parm [eax] [edx] value [edx] modify exact [eax];
#endif
extern void remove_sprite(long);
#pragma aux remove_sprite parm [eax] modify exact [eax];
extern void spawn_level_effect(short, short, short, const PuzzlePosition *, short);
#pragma aux spawn_level_effect parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void update_level_sector_puzzle(void);
#pragma aux update_level_sector_puzzle modify exact [eax];

extern int puzzle_int_eax(int);
#pragma aux puzzle_int_eax = "" parm [eax] value [eax] modify exact [];
extern int puzzle_int_ecx(int);
#pragma aux puzzle_int_ecx = "" parm [ecx] value [ecx] modify exact [];
extern int puzzle_int_edx(int);
#pragma aux puzzle_int_edx = "" parm [edx] value [edx] modify exact [];

extern short puzzle_tile_di(short);
#pragma aux puzzle_tile_di = "" parm nomemory [di] value [di] modify exact [];

#ifdef PUZZLE_ACTIVATION_CONTEXT
extern int puzzle_enabled_edi(int);
#pragma aux puzzle_enabled_edi = "" parm [edi] value [edi] modify exact [];

/* Keep the two tag values in the store and preserved-call registers. */
extern int puzzle_prepare_tags(int open_tag, int clear_tag);
#pragma aux puzzle_prepare_tags = "" parm [eax] [edx] value [eax] modify exact [];

#endif
void update_level_sector_puzzle(void)
{
    short index, base_tile, tile, wall_end, inner, exit_count;
    short sprite;
    unsigned short target;
    int selected;

    if (puzzle_solved != 0)
        goto check_key_trigger;
    index = 0;
    sector_14_lotag = 0;
    sector_30_lotag = 0;
    sector_15_lotag = 0;
    if (absolute_long((long)((unsigned long)player_x - 0x7e6eUL)) < 0x400 &&
        absolute_long((long)((unsigned long)player_y - 0x6408UL)) < 0x400) {
        index = 107;
        effect_x.x = 0x7e6e;
        effect_y = 0x6408;
        base_tile = 0x68e;
    } else if (absolute_long((long)((unsigned long)player_x - 0x93f6UL)) < 0x400 &&
               absolute_long((long)((unsigned long)player_y - 0x79f7UL)) < 0x400) {
        index = 109;
        effect_x.x = 0x93f6;
        effect_y = 0x79f7;
        base_tile = 0x691;
    } else if (absolute_long((long)((unsigned long)player_x - 0x69f8UL)) < 0x400 &&
               absolute_long((long)((unsigned long)player_y - 0x79eaUL)) < 0x400) {
        index = 108;
        effect_x.x = 0x69f8;
        effect_y = 0x79ea;
        base_tile = 0x694;
    } else {
        index = -1;
    }
    if ((long)((unsigned long)game_clock - (unsigned long)last_tile_step) <= 0xb4)
        goto check_key_trigger;
    last_tile_step = game_clock;
    if ((selected = puzzle_int_eax(index)) > -1) {
        int limit;
        tile = puzzle_tile_di(sector_floor_tile[selected].tile);
        limit = puzzle_int_ecx(base_tile) + 2;
        ++tile;
        sector_floor_tile[selected].tile = tile;
        if ((long)tile > limit)
            sector_floor_tile[selected].tile = base_tile;
    }
    if (puzzle_int_eax(sector_107_floor_tile) == 0x68f &&
        puzzle_int_eax(sector_109_floor_tile) == 0x693 &&
        puzzle_int_eax(sector_108_floor_tile) == 0x694) {
#ifdef PUZZLE_ACTIVATION_CONTEXT
        int enabled = puzzle_enabled_edi(1);
        int clear_tag = 0;
        sector_30_lotag = (short)puzzle_prepare_tags(6, clear_tag);
        puzzle_solved = enabled;
        clear_tag = activate_sector_carry_tag(30, clear_tag);
        index = sector_30_wall_start;
        wall_end = (short)((unsigned short)sector_30_wall_count + (unsigned short)index);
        sector_30_lotag = (short)clear_tag;
#else
        sector_30_lotag = 6;
        puzzle_solved = 1;
        activate_sector(30);
        index = sector_30_wall_start;
        wall_end = (short)((unsigned short)sector_30_wall_count + (unsigned short)index);
        sector_30_lotag = 0;
#endif
        /* Original empty wall walk shares the later trigger/effect index. */
        for (; index < wall_end; ++index)
            ;
    }

check_key_trigger:
    if (puzzle_solved == 1 && key_sprite_consumed == 0) {
        index = 1;
        goto check_key_index;
scan_key:
        sprite = trigger_sprite[index].sprite;
        target = trigger_sprite[index].target;
        if (puzzle_int_ecx(target) < 0x8000 &&
            puzzle_int_eax((unsigned short)(target - 0x4000U)) == 0x6a &&
            puzzle_int_edx(sprite_tile[sprite].tile) == 0x20f) {
            remove_sprite(sprite);
            wall_tile = 0x689;
            sector_14_lotag = 6;
            key_sprite_consumed = 1;
            activate_sector(14);
            sector_14_lotag = 0;
            sector_15_lotag = 6;
            activate_sector(15);
            sector_15_lotag = 0;
        }
        index = (short)((unsigned short)index + 1U);
check_key_index:
        if (index <= trigger_count)
            goto scan_key;
    }

    effect_active = 0;
    if (puzzle_solved == 0 && index > -1) {
        effect_active = 1;
        spawn_level_effect(30, 6, 6, &effect_x, -3600);
    }
    if (effect_active != previous_effect_active) {
        if (effect_active == 1) {
            /* Preserve the original nested empty loops in the source. */
            for (index = 0; puzzle_int_eax(index) <= 5; ++index)
                for (inner = 0; puzzle_int_edx(inner) <= 5; ++inner)
                    ;
        }
        previous_effect_active = effect_active;
    }

    index = 1;
    exit_count = trigger_count;
    goto check_exit_index;
scan_exit:
    sprite = trigger_sprite[index].sprite;
    target = trigger_sprite[index].target;
    if (puzzle_int_ecx(target) < 0x8000 &&
        puzzle_int_eax((unsigned short)(target - 0x4000U)) == 0x29 &&
        puzzle_int_eax(sprite_tile[sprite].tile) == 0x224) {
        transition_marker = 0x336;
        destination_x = 0x2ee5;
        destination_y = 0x17ff;
        destination_level = 4;
    }
    index = (short)((unsigned short)index + 1U);
check_exit_index:
    if (index <= exit_count)
        goto scan_exit;
}
