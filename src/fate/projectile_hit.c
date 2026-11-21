extern short hit_actor_index[], hit_sprite_sector[];
extern unsigned char hit_sprite_lotag[];
extern short hit_actor_health[];
extern short hit_sprite_cstat[], player_sprite, held_item, holding_sprite;
extern char hit_sprite_owner[];
extern char hit_sprite_tile[];
extern long hit_sprite_z[], sector_floor_z[];
extern unsigned char hit_sprite_xrepeat[], actor_kind[];
extern void adjust_status_value(int), start_sequence(int);
#pragma aux adjust_status_value parm [eax] modify exact [eax];

extern int hit_actor_offset(void);
#pragma aux hit_actor_offset = value [edx] modify exact [];

extern short target_in_bx(void);
#pragma aux target_in_bx = value [bx] modify exact [];

#pragma aux start_sequence parm [eax] modify exact [eax];

extern short projectile_damage(void);
#pragma aux projectile_damage = "" value [cx] modify exact [];
extern int projectile_in_eax(int);
#pragma aux projectile_in_eax = "" parm [eax] value [eax] modify exact [];
extern int projectile_offset_in_eax(void);
#pragma aux projectile_offset_in_eax = "" value [eax] modify exact [];
extern short projectile_index_in_di(void);
#pragma aux projectile_index_in_di = "" value [di] modify exact [];
extern short held_item_in_cx(short);
#pragma aux held_item_in_cx = "" parm [cx] value [cx] modify exact [];
extern int clear_item_in_esi(int);
#pragma aux clear_item_in_esi = "" parm [esi] value [esi] modify exact [];

extern int projectile_in_ecx(int);
#pragma aux projectile_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern int projectile_in_ebx(int);
#pragma aux projectile_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern unsigned char projectile_in_bl(unsigned char);
#pragma aux projectile_in_bl = "" parm [bl] value [bl] modify exact [];
extern unsigned char projectile_in_bh(unsigned char);
#pragma aux projectile_in_bh = "" parm [bh] value [bh] modify exact [];
extern int saved_hit_target(void);
#pragma aux saved_hit_target = "" value [esi] modify exact [];

extern void stage_zero_collision(int);
#pragma aux stage_zero_collision = "" parm [edi] modify exact [];
extern short staged_collision(void);
#pragma aux staged_collision = "" value [di] modify exact [];
extern void hold_floor_before_clear(int);
#pragma aux hold_floor_before_clear = "" parm [ebx] modify exact [edi];
extern void repeat_to_bl(unsigned char);
#pragma aux repeat_to_bl = "" parm [bl] modify exact [];
extern unsigned char repeat_in_bl(void);
#pragma aux repeat_in_bl = "" value [bl] modify exact [];
extern void finish_collision_store(void);
#pragma aux finish_collision_store = "" modify exact [ebx];

extern short projectile_in_ax(short);
#pragma aux projectile_in_ax = "" parm [ax] value [ax] modify exact [];
extern void save_hit_target(int);
#pragma aux save_hit_target = "" parm [esi] modify exact [];
extern void save_hit_actor(int);
#pragma aux save_hit_actor = "" parm [edx] modify exact [];
extern void save_hit_offset(int);
#pragma aux save_hit_offset = "" parm [eax] modify exact [];

extern void save_target_in_ebx(int);
#pragma aux save_target_in_ebx = "" parm [ebx] modify exact [];
extern void save_projectile_in_edi(int);
#pragma aux save_projectile_in_edi = "" parm [edi] modify exact [];
extern short original_projectile(void);
#pragma aux original_projectile = "" value [dx] modify exact [];
extern int original_projectile_wide(void);
#pragma aux original_projectile_wide = "" value [edx] modify exact [];
extern int original_target(void);
#pragma aux original_target = "" value [eax] modify exact [];

/* Keep the tag in AX while a recognized projectile updates ECX damage. */
extern void set_damage_for_tag(unsigned short tag, int damage);
#pragma aux set_damage_for_tag = "" parm [ax] [ecx] modify exact [];

extern void apply_projectile_hit(int, int, int);
#pragma aux apply_projectile_hit parm [eax] [edx] [ecx] modify exact [eax edx];

void apply_projectile_hit(int target, int projectile, int damage)
{
    unsigned short tag;
    int sequence_sprite, sprite_offset;
    short held, empty;
    int sector, floor_offset, floor;
    unsigned char repeats, kind;
    short found_actor;

    save_target_in_ebx(original_target());
    save_projectile_in_edi(original_projectile_wide());
    sprite_offset = projectile_in_eax(projectile_in_eax(original_projectile()) * 44);
    tag = (unsigned short)projectile_in_ax(*(short *)(hit_sprite_lotag + sprite_offset));
    if (tag < 0xa00)
        goto check_light;
    if (tag <= 0xa00)
        goto second;
    if (tag < 0x3000)
        goto actor;
    if (tag <= 0x3000)
        goto third;
    if (tag == 0x4200)
        goto fourth;
    goto actor;

check_light:
    if (tag != 0x100)
        goto actor;
    set_damage_for_tag(tag, -200);
    goto actor;
second:
    set_damage_for_tag(tag, -125);
    goto actor;
third:
    set_damage_for_tag(tag, -300);
    goto actor;
fourth:
    set_damage_for_tag(tag, -25);
actor:
    save_hit_target(target_in_bx());
    found_actor = projectile_in_ax(hit_actor_index[saved_hit_target()]);
    save_hit_actor(found_actor);
    save_hit_offset(saved_hit_target() * 44);
    if (hit_actor_offset() == -1)
        goto non_actor;
    hit_actor_health[hit_actor_offset()] += projectile_damage();
    if (hit_actor_health[hit_actor_offset()] > 0)
        goto survive;
    /* Drop the sprite to the floor, disable collision and widen it for the death sequence. */
    sector = projectile_in_ecx(*(short *)((char *)hit_sprite_sector + projectile_offset_in_eax()));
    floor_offset = projectile_in_ebx(sector * 5);
    floor = projectile_in_ebx(sector_floor_z[floor_offset * 2]);
    *(long *)((char *)hit_sprite_z + projectile_offset_in_eax()) = floor;
    hold_floor_before_clear(floor);
    stage_zero_collision(0);
    repeat_to_bl(hit_sprite_xrepeat[projectile_offset_in_eax()]);
    *(short *)((char *)hit_sprite_cstat + projectile_offset_in_eax()) = staged_collision();
    finish_collision_store();
    repeats = projectile_in_bl(repeat_in_bl() * 2);
    hit_sprite_xrepeat[projectile_offset_in_eax()] = repeats;
    kind = projectile_in_bh(3);
    sequence_sprite = projectile_in_eax(saved_hit_target());
    actor_kind[hit_actor_offset()] = kind;
    goto play;
survive:
    sprite_offset = projectile_in_eax(projectile_in_eax(projectile_index_in_di()) * 44);
    if (projectile_in_eax(*(short *)(hit_sprite_owner + sprite_offset)) != 1)
        goto normal;
    actor_kind[hit_actor_offset()] = 5;
    return;
normal:
    actor_kind[hit_actor_offset()] = 4;
    return;

non_actor:
    if (target_in_bx() == player_sprite) {
        adjust_status_value(projectile_in_eax(projectile_damage()));
        goto start;
    }
    held = held_item_in_cx(held_item);
    /* Release the held item when the hit sprite uses its tile. */
    if (held == *(short *)(hit_sprite_tile + projectile_offset_in_eax())) {
        empty = (short)clear_item_in_esi(0);
        held_item = empty;
        holding_sprite = empty;
    }
start:
    sequence_sprite = projectile_in_eax(target_in_bx());
play:
    start_sequence(sequence_sprite);
}
