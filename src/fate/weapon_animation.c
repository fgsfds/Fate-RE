/* Weapon animation state machine. Only fully guarded exact phases are linked.
 * Clock subtraction wraps in 32 bits. Signed word narrowing follows Watcom.
 * Frame lookup addresses the mutable DATA image, including slot-zero reads
 * before the nominal frame table; resolved lookups must stay inside DATA.
 * Definition slots and displayed/selected/requested slots must be 0..7.
 */
#ifdef WEAPON_ACTIVE_STATE_CONTEXT
#define update_weapon_animation update_weapon_animation_state_context
#elif defined(WEAPON_TRANSFER_CONTEXT)
#define update_weapon_animation update_weapon_animation_transfer_context
#endif
typedef struct {
    short base_tile, ready_tile;
    short lower_start, lower_end;
    short primary_start, primary_end, primary_fire, primary_projectile;
    short secondary_start, secondary_end, secondary_fire, secondary_projectile;
} WeaponAnimation;

enum {
    WEAPON_COUNT = 8,
    FRAMES_PER_WEAPON = 24,
    FRAME_OFFSET_BASE_WORD = 0x12868 / sizeof(short),
    DEFAULT_WEAPON_TILE = 1053,
    IDLE = 0,
    LOWERING = 1,
    START_RAISING = 2,
    RAISING = 3,
    FIRING = 4
};

extern const WeaponAnimation weapon_animations[WEAPON_COUNT];
/* A complete DATA-image view keeps reachable non-table reads in bounds. */
extern short weapon_frame_words[0x28a300UL / sizeof(short)];
#ifdef WEAPON_TRANSFER_CONTEXT
/* Separate X/Y views both bind to the same full mutable DATA object. */
extern short weapon_frame_x_words[0x28a300UL / sizeof(short)];
extern short weapon_frame_y_words[0x28a300UL / sizeof(short)];
#endif
extern volatile unsigned long game_clock;
extern unsigned long last_frame_tick;
extern volatile short weapon_input_bits, weapon_action, weapon_animation_state;
extern volatile short selected_weapon, displayed_weapon, weapon_tile;
extern volatile short frame_direction, animation_limit, requested_weapon;
extern volatile short projectile_frame, projectile_type;
extern short weapon_x_offset, weapon_y_offset;

extern void fire_player_projectile(int type);
#pragma aux fire_player_projectile parm [eax] modify exact [eax];

extern int keep_tick(int);
#pragma aux keep_tick = "" parm nomemory [eax] value [eax] modify exact [];

extern short keep_state(short);
#pragma aux keep_state = "" parm nomemory [dx] value [dx] modify exact [];

#ifdef WEAPON_ACTIVE_STATE_CONTEXT
/* Promote the actual signed state once, keeping the tick lifetime in EAX. */
extern int keep_active_state(int);
#pragma aux keep_active_state = "" parm nomemory [edx] value [edx] modify exact [];
#else
#define active_state state
#endif

#ifdef WEAPON_TRANSFER_CONTEXT
/* Register-only identities preserve their actual input at each boundary. */
extern int keep_row_offset(int);
#pragma aux keep_row_offset = "" parm nomemory [edx] value [edx] modify exact [];
extern short keep_displayed(short);
#pragma aux keep_displayed = "" parm nomemory [si] value [si] modify exact [];
extern short keep_frame(short);
#pragma aux keep_frame = "" parm nomemory [bx] value [bx] modify exact [];
extern int keep_byte_offset(int);
#pragma aux keep_byte_offset = "" parm nomemory [eax] value [eax] modify exact [];
extern short keep_screen_x(short);
#pragma aux keep_screen_x = "" parm nomemory [dx] value [dx] modify exact [];

#endif

void update_weapon_animation(void);
#pragma aux update_weapon_animation modify exact [eax];
void update_weapon_animation(void)
{
#ifdef WEAPON_TRANSFER_CONTEXT
    int advance, index;
#else
    int advance;
#endif
#ifdef WEAPON_ACTIVE_STATE_CONTEXT
    int active_state;
#endif
    short state, request, selected, displayed;
    short tile, limit, next, previous, fire_tile, direction;
    short frame, x, y;
    int offset;

    if ((long)(game_clock - last_frame_tick) > 6) {
        last_frame_tick = game_clock;
        advance = 1;
    } else {
        advance = 0;
    }
    advance = keep_tick(advance);
    state = keep_state(weapon_animation_state);
    if (state != IDLE)
        goto advance_animation;

    /* Casting to unsigned for the shift retains original input bits 13-15. */
    request = (short)(((unsigned short)weapon_input_bits >> 13) & 7);
    selected = selected_weapon;
    requested_weapon = request;
    if (request != selected) {
        weapon_tile = weapon_animations[selected].lower_start;
        limit = weapon_animations[selected].lower_end;
        displayed_weapon = selected;
        animation_limit = limit;
        tile = weapon_tile;
        limit = animation_limit;
        weapon_animation_state = LOWERING;
        if (tile > limit)
            goto reverse;
        frame_direction = 0;
        goto offsets;
    }

    if (weapon_action == 1) {
        request = requested_weapon;
        displayed_weapon = request;
#ifdef WEAPON_TRANSFER_CONTEXT
        tile = weapon_animations[request].primary_start;
        index = requested_weapon;
        weapon_tile = tile;
        limit = weapon_animations[index].primary_end;
        index = requested_weapon;
        animation_limit = limit;
        fire_tile = weapon_animations[index].primary_fire;
        index = requested_weapon;
        projectile_frame = fire_tile;
        direction = weapon_animations[index].primary_projectile;
#else
        weapon_tile = weapon_animations[request].primary_start;
        animation_limit = weapon_animations[requested_weapon].primary_end;
        projectile_frame = weapon_animations[requested_weapon].primary_fire;
        direction = weapon_animations[requested_weapon].primary_projectile;
#endif
        limit = animation_limit;
        projectile_type = direction;
        tile = weapon_tile;
        weapon_animation_state = FIRING;
        frame_direction = (short)((tile <= limit) - 1);
        fire_tile = projectile_frame;
        if (fire_tile == weapon_tile)
            goto fire;
        goto offsets;
    }
    if (weapon_action != 2)
        goto offsets;
    if (weapon_animations[requested_weapon].secondary_start == 0)
        goto offsets;

    request = requested_weapon;
    displayed_weapon = request;
#ifdef WEAPON_TRANSFER_CONTEXT
    tile = weapon_animations[request].secondary_start;
    index = requested_weapon;
    weapon_tile = tile;
    limit = weapon_animations[index].secondary_end;
    index = requested_weapon;
    animation_limit = limit;
    fire_tile = weapon_animations[index].secondary_fire;
    index = requested_weapon;
    projectile_frame = fire_tile;
    direction = weapon_animations[index].secondary_projectile;
#else
    weapon_tile = weapon_animations[request].secondary_start;
    animation_limit = weapon_animations[requested_weapon].secondary_end;
    projectile_frame = weapon_animations[requested_weapon].secondary_fire;
    direction = weapon_animations[requested_weapon].secondary_projectile;
#endif
    limit = animation_limit;
    projectile_type = direction;
    tile = weapon_tile;
    weapon_animation_state = FIRING;
    frame_direction = (short)((tile <= limit) - 1);
    fire_tile = projectile_frame;
    if (fire_tile == weapon_tile)
        goto fire;
    goto offsets;

advance_animation:
#ifdef WEAPON_ACTIVE_STATE_CONTEXT
    active_state = keep_active_state((int)state);
#endif
    if (active_state == LOWERING) {
        if (frame_direction == 0) {
            tile = weapon_tile;
            if (tile >= animation_limit)
                goto begin_raising;
            if (advance)
                weapon_tile = (short)(tile + 1);
            goto offsets;
        }
        tile = weapon_tile;
        if (tile <= animation_limit)
            goto begin_raising;
        if (advance)
            weapon_tile = (short)(tile - 1);
        goto offsets;
    begin_raising:
        weapon_animation_state = START_RAISING;
        goto offsets;
    }

    if (active_state == START_RAISING) {
        request = requested_weapon;
        weapon_animation_state = RAISING;
        displayed_weapon = request;
        tile = weapon_animations[request].base_tile;
        limit = weapon_animations[request].ready_tile;
        weapon_tile = tile;
        animation_limit = limit;
        if (tile > limit)
            goto reverse;
        frame_direction = 0;
        goto offsets;
    }

    next = (short)(weapon_tile + 1);
    previous = (short)(weapon_tile - 1);
    if (active_state == RAISING) {
        if (frame_direction == 0) {
            tile = weapon_tile;
            if (tile >= animation_limit)
                goto finish_raising;
            if (advance)
                weapon_tile = next;
            goto offsets;
        }
        tile = weapon_tile;
        if (tile <= animation_limit)
            goto finish_raising;
        if (advance)
            weapon_tile = previous;
        goto offsets;
    finish_raising:
        selected_weapon = requested_weapon;
        weapon_animation_state = IDLE;
        goto offsets;
    }

    if (active_state != FIRING || !advance)
        goto offsets;
    direction = frame_direction;
    if (direction == 0) {
        tile = weapon_tile;
        if (tile >= animation_limit) {
            request = requested_weapon;
            displayed_weapon = request;
            tile = weapon_animations[request].ready_tile;
            weapon_animation_state = IDLE;
            goto store_ready_tile;
        }
        fire_tile = projectile_frame;
        weapon_tile = next;
        if (next == fire_tile)
            goto fire;
        goto offsets;
    }
    tile = weapon_tile;
    if (tile <= animation_limit) {
        weapon_animation_state = IDLE;
        request = requested_weapon;
        displayed_weapon = request;
        tile = weapon_animations[request].ready_tile;
        goto store_ready_tile;
    }
    fire_tile = projectile_frame;
    weapon_tile = previous;
    if (previous == fire_tile)
        goto fire;
    goto offsets;

store_ready_tile:
    weapon_tile = tile;
    goto offsets;

reverse:
    frame_direction = -1;
    goto offsets;

fire:
    fire_player_projectile((int)projectile_type);

offsets:
#ifdef WEAPON_TRANSFER_CONTEXT
    displayed = keep_displayed(displayed_weapon);
    if (displayed != 0) {
        index = keep_row_offset((int)displayed * (int)sizeof(WeaponAnimation));
        frame = keep_frame(weapon_tile);
        frame = keep_frame((short)(frame - *(const short *)
                          ((const char *)&weapon_animations + index)));
    } else {
        frame = keep_frame((short)(weapon_tile - DEFAULT_WEAPON_TILE));
    }
    index = keep_row_offset((int)displayed_weapon * 3);
    offset = keep_byte_offset((int)frame * 4 + index * 32);
    x = keep_screen_x(*(short *)((char *)&weapon_frame_x_words +
                                 FRAME_OFFSET_BASE_WORD * (int)sizeof(short) + offset));
    y = *(short *)((char *)&weapon_frame_y_words +
                   (FRAME_OFFSET_BASE_WORD + 1) * (int)sizeof(short) + offset);
    weapon_x_offset = x;
    weapon_y_offset = y;
#else
    displayed = displayed_weapon;
    if (displayed != 0) {
        tile = weapon_tile;
        frame = (short)(tile - weapon_animations[displayed].base_tile);
    } else {
        frame = (short)(weapon_tile - DEFAULT_WEAPON_TILE);
    }
    offset = (int)displayed_weapon * FRAMES_PER_WEAPON + (int)frame;
    offset = FRAME_OFFSET_BASE_WORD + offset * 2;
    x = weapon_frame_words[offset];
    y = weapon_frame_words[offset + 1];
    weapon_x_offset = x;
    weapon_y_offset = y;
#endif
}
