/* Board-four encounter algorithm used as compiler context for the complete
 * exit-registration / actor-62 phase at 0x1e30b..0x1e410 (261 bytes).
 * Only that phase is linked. The spawn/actor-63 prefix and compiler tables are
 * private context; the historical assembly still implements those paths.
 * The original 184-byte frame, six saved registers and return tail stay in ASM.
 * Empty identities describe actual C values/registers and emit no instructions.
 */
#pragma pack(push, 1)
typedef struct { long x, y; } SpawnPosition;
typedef struct { unsigned char x, y; } SpawnRepeats;
typedef struct { long x, y, z; } EncounterPosition;
typedef struct { short sprite, target; } EncounterTrigger;
typedef struct { short sector, active; } EncounterSectorEvent;
typedef struct { char reserved[34]; short lotag; char tail[4]; } EncounterSector;
typedef struct {
    long x, y, z;
    short cstat, tile;
    signed char shade;
    unsigned char pal, clipdist, filler, xrepeat, yrepeat;
    char reserved[16];
    short lotag, hitag, extra;
} EncounterSprite;
#pragma pack(pop)

typedef struct {
    EncounterPosition position;
    short sector_hint;
    unsigned short padding;
    unsigned long y_shift;
    unsigned long number;
} EncounterSpawn;

extern EncounterSprite sprite[];
extern EncounterSector sector[];
extern EncounterTrigger trigger_sprite[];
extern EncounterSectorEvent board4_sector_events[];
extern short numsectors, trigger_count, tilesizx[];
extern long ticks_per_step;
extern short advance_clock, encounter_clock, rotating_sector_count;
extern short first_trigger_state, second_trigger_state, exit_scan_initialized, exit_scan_index;
extern short encounter_position, first_trigger_sprite, second_trigger_sprite, encounter_sprite_index;
extern const short encounter_sequence[], exit_sequence[];
extern unsigned char first_actor_state, second_actor_state;
extern unsigned char first_actor_kind, second_actor_kind;
extern unsigned char first_actor_mode, second_actor_mode;

extern int random_value(void);
#pragma aux random_value value [eax] modify exact [eax];
extern void play_sound(int, long, long, int);
#pragma aux play_sound parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void updatesector(long, long, short *);
#pragma aux updatesector parm [eax] [edx] [ebx] modify exact [eax ebx edx];
extern short spawn_sprite_at_position(int, const EncounterPosition *, int);
#pragma aux spawn_sprite_at_position parm [eax] [edx] [ebx] value [ax] modify exact [eax ebx edx];

/* The listed-sprite routine saves EDX and returns it intact. */
extern unsigned long add_listed_sprite_keep_number(int, unsigned long);
#pragma aux add_listed_sprite_keep_number "add_listed_sprite_" parm [eax] [edx] value [edx] modify exact [eax];

extern int near_encounter_position(long, long);
#pragma aux near_encounter_position parm [eax] [edx] value [eax] modify exact [eax];
extern void update_actor_common(int);
#pragma aux update_actor_common parm [eax] modify exact [eax];
extern void update_sprite_sequence_state(int, long, long, long, long, const short *);
#pragma aux update_sprite_sequence_state parm routine [eax] [edx] [ebx] [ecx] \
    modify exact [eax ebx ecx edx];
extern void activate_sector(int);
#pragma aux activate_sector parm [eax] modify exact [eax];
/* Native ABI alias: the callee consumes AX and sign-extends it internally.
 * The caller supplies a sign-extended short in EAX; ECX and EBX survive. */
extern int delete_sprite_low_word(int sprite_word);
#pragma aux delete_sprite_low_word "deletesprite_" parm [eax] value [eax] modify exact [eax];

extern int exit_int_eax(int);
#pragma aux exit_int_eax = "" parm [eax] value [eax] modify exact [];
extern int exit_int_ecx(int);
#pragma aux exit_int_ecx = "" parm [ecx] value [ecx] modify exact [];
extern short exit_short_dx(short);
#pragma aux exit_short_dx = "" parm [dx] value [dx] modify exact [];
extern unsigned char exit_byte_bl(unsigned char);
#pragma aux exit_byte_bl = "" parm [bl] value [bl] modify exact [];
extern unsigned char exit_byte_cl(unsigned char);
#pragma aux exit_byte_cl = "" parm [cl] value [cl] modify exact [];
extern int exit_int_ebx(int);
#pragma aux exit_int_ebx = "" parm [ebx] value [ebx] modify exact [];

extern void encounter_exit_context(void);
#pragma aux encounter_exit_context modify exact [eax];

void encounter_exit_context(void)
{
    const SpawnPosition positions[16] = {
        {-10240, -6400}, {-9728, -5632}, {-8960, -5376}, {-7936, -5888},
        {-7424, -5376}, {-9984, -7168}, {-8704, -6656}, {-7936, -7424},
        {-7424, -7168}, {-10752, -9216}, {-10240, -8192}, {-6912, -8448},
        {-9984, -9728}, {-7680, -9728}, {-8704, -10240}, {-9216, -10752}
    };
    const SpawnRepeats repeats[16] = {
        {60, 60}, {30, 30}, {30, 30}, {15, 15},
        {15, 15}, {15, 15}, {15, 15}, {15, 15},
        {15, 15}, {15, 15}, {15, 15}, {7, 7},
        {7, 7}, {7, 7}, {7, 7}, {7, 7}
    };
    EncounterSpawn spawn;
    short index, slot, sector_index;
    short position_choice, repeat_choice;
    short near_first, near_second;
    unsigned x_shift;
    long scaled_width;

    if ((long)encounter_clock == 10)
        goto check_second_trigger_tile;

    if (encounter_clock == 0) {
        for (index = 1; index <= trigger_count; index = (short)((unsigned short)index + 1U)) {
            slot = trigger_sprite[index].sprite;
            if (sprite[slot].hitag != 0x203)
                continue;
            if (sprite[slot].x <= -0x3002L || sprite[slot].x >= -0x1403L)
                continue;
            if (sprite[slot].y <= -0x2d0bL || sprite[slot].y >= -0x1206L)
                continue;

            encounter_clock = 1;
            play_sound(0x88, 0, 0, 0);
            play_sound(0x87, 0, 0, 0);
            rotating_sector_count = 0;
            for (sector_index = 0; sector_index < numsectors; ++sector_index) {
                if (sector[sector_index].lotag == 0xe)
                    sector[sector_index].lotag = 0;
            }
        }
    }

    if (encounter_clock > 0) {
        if (advance_clock != 0)
            encounter_clock = (short)((unsigned short)encounter_clock + 1U);

        spawn.number = 1;
        goto check_spawn_count;
        do {
            position_choice = (short)(random_value() & 15);
            spawn.position.x = positions[position_choice].x;
            spawn.position.y = positions[position_choice].y;
            spawn.position.z = -0xc3faL;

            /* The original passes untouched stack bytes as the first input hint.
             * updatesector tests those bytes and leaves its resulting sector here.
             */
            updatesector(spawn.position.x, spawn.position.y, &spawn.sector_hint);
            slot = spawn_sprite_at_position(0x2b, &spawn.position, spawn.sector_hint);
            sprite[slot].tile = (short)(0x350 + (random_value() & 1));

            repeat_choice = (short)(random_value() & 15);
            x_shift = random_value() & 1U;
            spawn.y_shift = random_value() & 1U;
            sprite[slot].xrepeat = (unsigned char)(repeats[repeat_choice].x >> x_shift);
            sprite[slot].yrepeat = (unsigned char)(repeats[repeat_choice].y >> (unsigned short)spawn.y_shift);

            scaled_width = (long)tilesizx[sprite[slot].tile] * sprite[slot].xrepeat;
            sprite[slot].clipdist = (unsigned char)((unsigned long)scaled_width >> 7);
            spawn.number = add_listed_sprite_keep_number(slot, spawn.number + 1UL);
check_spawn_count:
            ;
        } while ((short)spawn.number <= (long)(2UL * (unsigned long)ticks_per_step));
    }

check_second_trigger_tile:
    if (sprite[first_trigger_sprite].tile == 0x568 && second_trigger_state != 3) {
        if (second_actor_kind != 3)
            second_actor_mode = 2;
        second_trigger_state = 3;
        activate_sector(0x96);
        activate_sector(0x99);
        play_sound(0x7e, 0, 0, 0);
        play_sound(0x8e, 0, 0, 0);
        sprite[first_trigger_sprite].lotag = 0;
    }

    if (second_trigger_state == 0) {
        near_first = (short)near_encounter_position(0x2a00, 0x1000);
        near_second = (short)near_encounter_position(0x2a00, 0x2000);
        if ((near_first | near_second) != 0 || second_actor_kind == 4 || second_actor_kind == 5) {
            second_actor_kind = 0;
            second_trigger_state = 1;
        }
    } else if (second_trigger_state == 1) {
        update_actor_common(0x3f);
        update_sprite_sequence_state(0x3f, 0x3100, 0x1800, 0x410a, 0x1800, encounter_sequence);
        if (sprite[encounter_sprite_index].tile == 0x34b)
            sprite[first_trigger_sprite].tile = 0x568;
        if (second_actor_state == 0)
            second_trigger_state = 2;
    }

    {

    int exit_index;
    short exit_state;
    if (exit_scan_initialized == 0) {
        int enabled = exit_int_ecx(1);
        exit_scan_initialized = (short)enabled;
        exit_scan_index = (short)enabled;
        goto check_scan;
scan:
        if (exit_int_eax(board4_sector_events[exit_index].sector) == 11)
            goto check_actor;
        ++exit_scan_index;
check_scan:
        exit_index = exit_int_eax(exit_scan_index);
        if (exit_index <= 31)
            goto scan;
    }
check_actor:
    if (exit_int_eax(first_actor_kind) == 3 || exit_int_eax(first_trigger_state) == 2)
        return;
    if (exit_int_eax(encounter_position) == 1) {
        int next_state = exit_int_eax(2);
        unsigned char next_mode = exit_byte_bl(1);
        first_trigger_state = (short)next_state;
        first_actor_mode = next_mode;
    }
    exit_state = exit_short_dx(first_trigger_state);
    if (exit_state == 0) {
        if (board4_sector_events[exit_scan_index].active != 0)
            first_trigger_state = 1;
        return;
    }
    if (exit_int_eax(exit_state) == 1) {
        update_actor_common(0x3e);
        update_sprite_sequence_state(0x3e, 0x1df4, 0x18f8, 0x410a, 0x1800, exit_sequence);
        if (first_actor_state == 0) {
            unsigned char next_mode = exit_byte_cl(2);
            int dying_sprite = exit_int_eax(second_trigger_sprite);
            int next_state = exit_int_ebx(2);
            delete_sprite_low_word(dying_sprite);
            first_actor_mode = next_mode;
            first_trigger_state = (short)next_state;
        }
    }
    }
}
