/* Shared actor recovery, death, close-range hits and reaction sounds.
 * Empty Watcom auxiliaries preserve the original register lifetimes; all
 * instructions are compiler-generated. Long/int are 32-bit, short is 16-bit.
 * Unsigned-to-signed casts use Watcom's bit-preserving conversion contract.
 */
#pragma pack(push, 1)
typedef struct CommonActorSprite {
    long x, y, z;
    short cstat;
    unsigned char bytes14_17[4];
    unsigned char death_repeat; /* exact offset 18 (0x12), not offset 20 */
    unsigned char bytes19_23[5];
    short sector;
    unsigned char bytes26_43[18];
} CommonActorSprite;
#pragma pack(pop)

extern CommonActorSprite sprite[];
extern unsigned char actor_kind[], actor_recovery_counter[];
extern short actor_sprite[], actor_health[], advance_clock;
extern short alternate_fire_requested;
extern long sector_floor_z[]; /* field at sector base+8, record stride 40 */
extern long player_x, player_y;
extern short player_angle, rotate_player_input_word;
extern unsigned char saved_actor_mode[];
extern unsigned short restored_actor_tiles[]; /* first word of 18-byte rows */

extern void start_sequence(int slot);
#pragma aux start_sequence parm [eax] modify exact [eax];
extern long ksqrt(long squared);
#pragma aux ksqrt parm [eax] modify exact [eax];
extern int getangle(long x, long y);
#pragma aux getangle parm [eax] [edx] modify exact [eax edx];
extern int absolute_int(int value);
#pragma aux absolute_int parm [eax] modify exact [eax];
extern int random_value(void);
#pragma aux random_value modify exact [eax];
extern void play_sound(int sound, long x, long y, int repeat);
#pragma aux play_sound parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];

/* Empty identities constrain original live registers, without stack effects. */
extern int common_actor_in_esi(int value);
#pragma aux common_actor_in_esi = "" parm [esi] value [esi] modify exact [];
extern short common_sprite_in_bx(short value);
#pragma aux common_sprite_in_bx = "" parm [bx] value [bx] modify exact [];
/* Every actor-index identity returns its actual signed C argument unchanged.
 * It constrains only the transient index; full original input remains in ESI. */
extern int common_actor_index_in_eax(int value);
#pragma aux common_actor_index_in_eax = "" parm [eax] value [eax] modify exact [];
extern int common_actor_in_edi(int value);
#pragma aux common_actor_in_edi = "" parm [edi] value [edi] modify exact [];
extern long common_delta_in_ecx(long value);
#pragma aux common_delta_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern long common_delta_in_edx(long value);
#pragma aux common_delta_in_edx = "" parm [edx] value [edx] modify exact [];
extern unsigned long common_square_in_edi(unsigned long value);
#pragma aux common_square_in_edi = "" parm [edi] value [edi] modify exact [];
extern long common_sound_y_in_ebx(long value);
#pragma aux common_sound_y_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern long common_sound_x_in_edi(long value);
#pragma aux common_sound_x_in_edi = "" parm [edi] value [edi] modify exact [];
extern int common_divisor_in_ecx(int value);
#pragma aux common_divisor_in_ecx = "" parm [ecx] value [ecx] modify exact [];

extern unsigned long common_kind_in_edx(unsigned long value);
#pragma aux common_kind_in_edx = "" parm [edx] value [edx] modify exact [];

extern unsigned char common_recovery_in_dl(unsigned char value);
#pragma aux common_recovery_in_dl = "" parm [dl] value [dl] modify exact [];

extern unsigned char common_zero_in_cl(unsigned char value);
#pragma aux common_zero_in_cl = "" parm [cl] value [cl] modify exact [];

/* Death-only register identities: each result is an ordinary C value.
 * ESI's incoming actor value is dead on this returning branch. */
extern int common_death_slot_in_ecx(int value);
#pragma aux common_death_slot_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern unsigned long common_death_offset_in_eax(unsigned long value);
#pragma aux common_death_offset_in_eax = "" parm [eax] value [eax] modify exact [];
extern int common_death_sector_in_ebx(int value);
#pragma aux common_death_sector_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern long common_death_value_in_edx(long value);
#pragma aux common_death_value_in_edx = "" parm [edx] value [edx] modify exact [];
extern int common_death_zero_in_esi(int value);
#pragma aux common_death_zero_in_esi = "" parm [esi] value [esi] modify exact [];
extern unsigned char common_death_byte_in_dl(unsigned char value);
#pragma aux common_death_byte_in_dl = "" parm [dl] value [dl] modify exact [];

extern void common_sequence_argument(int slot);
#pragma aux common_sequence_argument = "" parm [eax] modify exact [];
extern int common_sequence_argument_value(void);
#pragma aux common_sequence_argument_value = value [eax] modify exact [];

extern long common_vector_long_in_eax(long value);
#pragma aux common_vector_long_in_eax = "" parm [eax] value [eax] modify exact [];
extern long common_vector_long_in_ecx(long value);
#pragma aux common_vector_long_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern long common_vector_long_in_edx(long value);
#pragma aux common_vector_long_in_edx = "" parm [edx] value [edx] modify exact [];
extern long common_vector_long_in_edi(long value);
#pragma aux common_vector_long_in_edi = "" parm [edi] value [edi] modify exact [];
extern short common_vector_angle_in_dx(short value);
#pragma aux common_vector_angle_in_dx = "" parm [dx] value [dx] modify exact [];
/* Actual vector register boundaries. Stages consume their real C arguments;
 * getters read the named current register without asserting any upper bits.
 * No helper emits instructions, changes another register, or touches the stack. */
extern void common_vector_stage_ecx(long value);
#pragma aux common_vector_stage_ecx = "" parm [ecx] modify exact [];
extern void common_vector_stage_edx(long value);
#pragma aux common_vector_stage_edx = "" parm [edx] modify exact [];
extern void common_vector_stage_eax(long value);
#pragma aux common_vector_stage_eax = "" parm [eax] modify exact [];
extern long common_vector_raw_ecx(void);
#pragma aux common_vector_raw_ecx = value [ecx] modify exact [];
extern long common_vector_raw_eax(void);
#pragma aux common_vector_raw_eax = value [eax] modify exact [];
extern unsigned long common_vector_raw_edx(void);
#pragma aux common_vector_raw_edx = value [edx] modify exact [];
extern short common_vector_raw_dx(void);
#pragma aux common_vector_raw_dx = value [dx] modify exact [];

/* Attack/reaction partial-register contracts preserve the real untouched bits.
 * Raw unsigned full-register reads allow wrapping subtraction and explicit masks;
 * no getter assumes that the upper bits of a byte/word write were zeroed. */
extern void common_attack_hold_al(unsigned char value);
#pragma aux common_attack_hold_al = "" parm [al] modify exact [];
extern unsigned long common_attack_raw_eax(void);
#pragma aux common_attack_raw_eax = value [eax] modify exact [];
extern void common_attack_hold_eax(unsigned long value);
#pragma aux common_attack_hold_eax = "" parm [eax] modify exact [];
extern void common_attack_hold_cx(unsigned short value);
#pragma aux common_attack_hold_cx = "" parm [cx] modify exact [];
extern unsigned long common_attack_raw_ecx(void);
#pragma aux common_attack_raw_ecx = value [ecx] modify exact [];
extern void common_attack_hold_ecx(unsigned long value);
#pragma aux common_attack_hold_ecx = "" parm [ecx] modify exact [];
extern unsigned short common_attack_raw_cx(void);
#pragma aux common_attack_raw_cx = value [cx] modify exact [];
extern void common_attack_hold_dh(unsigned char value);
#pragma aux common_attack_hold_dh = "" parm [dh] modify exact [];
extern unsigned char common_attack_raw_dh(void);
#pragma aux common_attack_raw_dh = value [dh] modify exact [];
#define COMMON_DELTA(a, b) ((long)((unsigned long)(a) - (unsigned long)(b)))
#define COMMON_WORD(a) ((short)(unsigned short)(a))

void update_actor_common(int actor);
/* The original preserves EBX/ECX/EDX/ESI/EDI and has no local stack frame. */
#pragma aux update_actor_common parm [eax] modify exact [eax];
void update_actor_common(int actor)
{
    int original, index, health_index;
    short slot;
    long dx, dy, sound_x, sound_y;
    unsigned long squared, kind;
    int angle, delta, random, divisor, sound;
    unsigned short tile;
    unsigned char recovery;

    original = common_actor_in_esi(actor);
    index = common_actor_index_in_eax((short)original);
    kind = common_kind_in_edx((unsigned long)actor_kind[index]);
    if (kind == 3UL)
        return;
    recovery = common_recovery_in_dl(actor_recovery_counter[index]);
    slot = common_sprite_in_bx(actor_sprite[index]);
    if (recovery != 0 && advance_clock != 0) {
        ++actor_recovery_counter[index];
        if ((long)common_kind_in_edx((unsigned long)actor_recovery_counter[index]) > 6L) {
            unsigned char zero = common_zero_in_cl(0);
            actor_recovery_counter[index] = zero;
            actor_kind[index] = zero;
        }
    }

    health_index = common_actor_in_edi((short)original);
    if (*(volatile short *)&actor_health[health_index] <= 0) {
        int death_slot, sector, zero;
        unsigned long byte_offset;
        long sector_stride, floor;
        unsigned char repeat, dead_kind;

        death_slot = common_death_slot_in_ecx(slot);
        byte_offset = common_death_offset_in_eax((unsigned long)death_slot * 44UL);
        sector = common_death_sector_in_ebx(
            ((CommonActorSprite *)((unsigned char *)sprite + byte_offset))->sector);
        sector_stride = common_death_value_in_edx(sector);
        sector_stride = common_death_value_in_edx((long)((unsigned long)sector_stride << 2));
        sector_stride = common_death_value_in_edx(
            (long)((unsigned long)sector_stride + (unsigned long)sector));
        floor = common_death_value_in_edx(sector_floor_z[sector_stride * 2]);
        ((CommonActorSprite *)((unsigned char *)sprite + byte_offset))->z = floor;
        zero = common_death_zero_in_esi(0);
        repeat = common_death_byte_in_dl(
            ((CommonActorSprite *)((unsigned char *)sprite + byte_offset))->death_repeat);
        ((CommonActorSprite *)((unsigned char *)sprite + byte_offset))->cstat = (short)zero;
        repeat = common_death_byte_in_dl((unsigned char)(repeat + repeat));
        ((CommonActorSprite *)((unsigned char *)sprite + byte_offset))->death_repeat = repeat;
        dead_kind = common_death_byte_in_dl(3);
        common_sequence_argument(death_slot);
        actor_kind[common_actor_in_edi(health_index)] = dead_kind;
        start_sequence(common_sequence_argument_value());
        return;
    }

    if (alternate_fire_requested == 0)
        goto check_hit_reaction;
    {
        long player_x_edx, player_y_edi, angle_ecx, player_angle_eax;
        long sprite_slot_eax, sprite_offset_eax, input_eax;
        short player_angle_dx;

        sprite_slot_eax = common_vector_long_in_eax((int)slot);
        sprite_offset_eax = common_vector_long_in_eax(
            (long)((unsigned long)sprite_slot_eax * 44UL));
        player_x_edx = common_vector_long_in_edx(player_x);
        dx = common_delta_in_ecx(
            ((CommonActorSprite *)((unsigned char *)sprite + sprite_offset_eax))->x);
        player_y_edi = common_vector_long_in_edi(player_y);
        dx = common_delta_in_ecx(COMMON_DELTA(dx, player_x_edx));
        dy = common_delta_in_edx(
            ((CommonActorSprite *)((unsigned char *)sprite + sprite_offset_eax))->y);
        dy = common_delta_in_edx(COMMON_DELTA(dy, player_y_edi));
        squared = common_square_in_edi((unsigned long)dx * (unsigned long)dx);
        squared = (unsigned long)dy * (unsigned long)dy + squared;
        if (ksqrt((long)squared) >= 350)
            goto check_hit_reaction;

        angle = getangle(dx, dy);
        player_angle_dx = common_vector_angle_in_dx(player_angle);
        angle_ecx = common_vector_long_in_ecx((int)COMMON_WORD(angle));
        player_angle_eax = common_vector_long_in_eax((int)player_angle_dx);
        angle_ecx = common_vector_long_in_ecx(angle_ecx - player_angle_eax);
        delta = absolute_int((int)angle_ecx);
        common_vector_stage_ecx((int)COMMON_WORD(delta));
        common_vector_stage_edx(delta);
        if (common_vector_raw_ecx() > 1024L) {
            common_vector_stage_edx(2047L);
            common_vector_stage_edx(
                (long)(common_vector_raw_edx() -
                       (unsigned long)common_vector_raw_eax()));
        }
        common_vector_stage_eax((int)common_vector_raw_dx());
        if (common_vector_raw_eax() >= 120L)
            goto check_hit_reaction;
        /* Signed16 input widens to EAX before the arithmetic shift. */
        input_eax = common_vector_long_in_eax((int)rotate_player_input_word);
        input_eax = common_vector_long_in_eax(input_eax >> 13);
        if ((unsigned char)input_eax & 7U)
            goto apply_heavy_hit;
    }
    random = random_value();
    if ((random & 3) == 3)
        goto apply_light_hit;
    index = common_actor_index_in_eax((short)original);
    common_attack_hold_al(saved_actor_mode[index]);
    common_attack_hold_eax(common_attack_raw_eax() & 255UL);
    if (common_attack_raw_eax() != 2UL)
        goto check_hit_reaction;

apply_light_hit:
    index = common_actor_index_in_eax((short)original);
    common_attack_hold_cx((unsigned short)actor_health[index]);
    common_attack_hold_dh(5);
    common_attack_hold_ecx(common_attack_raw_ecx() - 200UL);
    actor_kind[index] = common_attack_raw_dh();
    actor_health[index] = COMMON_WORD(common_attack_raw_cx());
    goto check_hit_reaction;
apply_heavy_hit:
    index = common_actor_index_in_eax((short)original);
    actor_kind[index] = 4;
    /* Promotion to int makes the subtraction safe for every signed short. */
    actor_health[index] -= 300;

check_hit_reaction:
    index = common_actor_index_in_eax((short)original);
    common_attack_hold_al(actor_kind[index]);
    common_attack_hold_eax(common_attack_raw_eax() & 255UL);
    if (common_attack_raw_eax() != 4UL && common_attack_raw_eax() != 5UL)
        return;
    index = common_actor_index_in_eax((short)original);
    if (actor_recovery_counter[index] != 0)
        return;
    tile = restored_actor_tiles[index * 9];
    if (tile < 0x9b8)
        goto check_first_sound;
    if (tile <= 0x9b8)
        goto second_sound;
    if (tile < 0xa02)
        goto start_recovery;
    if (tile <= 0xa02)
        goto third_sound;
    if (tile == 0xa70)
        goto fourth_sound;
    goto start_recovery;

check_first_sound:
    if (tile != 0x966)
        goto start_recovery;
    sound_y = common_sound_y_in_ebx(sprite[slot].y);
    sound_x = common_sound_x_in_edi(sprite[slot].x);
    random = random_value();
    divisor = common_divisor_in_ecx(4);
    sound = random % divisor + 0x24;
    goto play_reaction;
second_sound:
    sound_y = common_sound_y_in_ebx(sprite[slot].y);
    sound_x = common_sound_x_in_edi(sprite[slot].x);
    random = random_value();
    divisor = common_divisor_in_ecx(2);
    sound = random % divisor + 0x3a;
    goto play_reaction;
third_sound:
    sound_y = common_sound_y_in_ebx(sprite[slot].y);
    sound_x = common_sound_x_in_edi(sprite[slot].x);
    random = random_value();
    divisor = common_divisor_in_ecx(2);
    sound = random % divisor + 0x57;
    goto play_reaction;
fourth_sound:
    sound_y = common_sound_y_in_ebx(sprite[slot].y);
    sound_x = common_sound_x_in_edi(sprite[slot].x);
    random = random_value();
    divisor = common_divisor_in_ecx(2);
    sound = random % divisor + 0x49;
play_reaction:
    play_sound(sound, sound_x, sound_y, 0);
start_recovery:
    actor_recovery_counter[common_actor_index_in_eax((short)original)] = 3;
}
