/* Two unchanged compiler sections surround the C row setup from
 * gameplay_row.c. Every byte of the production controller comes from C. */
/* Apply inventory overrides, advance gameplay, and carry out level transitions. */
typedef unsigned long GameplayWord;
#pragma pack(push, 1)
typedef struct { short value, active; } GameplaySectorWord;
typedef struct { GameplayWord value, y; } GameplaySectorCoordinate;
typedef struct { short value; unsigned char gap[38]; } GameplayHitag;
typedef struct { GameplayWord value; unsigned char gap[40]; } GameplaySpriteCoordinate;
typedef struct { short value; unsigned char gap[4]; } GameplayLevelIcon;
#pragma pack(pop)

extern unsigned char inventory_override_request;
extern short inventory_override, previous_override;
extern GameplayWord status_right_tenths, saved_status_right;
extern short item_enabled[], item_stock[], item_alternate_stock[];
extern short saved_item_enabled[], saved_item_stock[], saved_item_alternate_stock[];
extern short left_icon, middle_icon, right_icon, effect_count, status_flag;
extern short saved_left_icon, saved_middle_icon, saved_right_icon;
extern short saved_effect_count, saved_status_flag;
extern volatile GameplayWord game_clock;
extern GameplayWord last_step_clock, last_sequence_clock;
extern short advance_clock;
/* Separate aliases retain each interleaved field's original address and stride. */
extern GameplaySectorWord level_sector_ids[][32], level_sector_active[][32];
extern GameplaySectorCoordinate level_sector_x[][32], level_sector_y[][32];
extern GameplayHitag sector_hitag[];
extern GameplayWord player_x, player_y;
extern signed char actor_active[], current_level, destination_level, loaded_level;
extern unsigned char actor_level[], modified_levels[];
extern short actor_sprite[], level_sector_count[], player_sector, special_sector;
extern GameplaySpriteCoordinate sprite_x[], sprite_y[];
extern GameplayLevelIcon level_left_icon[], level_middle_icon[], level_right_icon[];
extern const char mod_extension[];
extern short destination_entry;
extern GameplayWord destination_x, destination_y;

extern int select_item(int);
#pragma aux select_item parm [eax] value [eax] modify exact [eax];
extern void refresh_inventory(void), check_teleport_terminals(void);
#pragma aux refresh_inventory modify exact [eax];
#pragma aux check_teleport_terminals modify exact [eax];
extern long absolute_long(long);
#pragma aux absolute_long parm [eax] value [eax] modify exact [eax];
extern void activate_sector(int), update_sector_events(void), update_periodic_sequences(void);
#pragma aux activate_sector parm [eax] modify exact [eax];
#pragma aux update_sector_events modify exact [eax];
#pragma aux update_periodic_sequences modify exact [eax];
extern void update_proximity_sprites(void), update_float_sprites(void);
extern void update_moving_sprite_physics(void), update_projectiles(void);
extern void update_sector_panning(void), update_fall_triggers(void);
#pragma aux update_proximity_sprites modify exact [eax];
#pragma aux update_float_sprites modify exact [eax];
#pragma aux update_moving_sprite_physics modify exact [eax];
#pragma aux update_projectiles modify exact [eax];
#pragma aux update_sector_panning modify exact [eax];
#pragma aux update_fall_triggers modify exact [eax];
extern void update_level_effects(int), update_actor_states(void);
#pragma aux update_level_effects parm [eax] modify exact [eax];
#pragma aux update_actor_states modify exact [eax];
/* This callee saves EBX/ECX/ESI/EDI/EBP, but leaves EDX changed. */
extern int save_level_and_load_board(int, const char *);
#pragma aux save_level_and_load_board parm [eax] [edx] value [eax] modify exact [eax edx];
/* Four register arguments and one callee-popped stack word (RET 4). */
extern void initialize_destination(int, GameplayWord, GameplayWord, int, unsigned);
#pragma aux initialize_destination parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];

extern int gameplay_eax(int);
#pragma aux gameplay_eax = "" parm nomemory [eax] value [eax] modify exact [];
extern unsigned short gameplay_edi(unsigned);
#pragma aux gameplay_edi = "" parm nomemory [edi] value [di] modify exact [];

extern unsigned gameplay_edx(unsigned);
#pragma aux gameplay_edx = "" parm nomemory [edx] value [edx] modify exact [];

extern unsigned gameplay_ecx(unsigned);
#pragma aux gameplay_ecx = "" parm nomemory [ecx] value [ecx] modify exact [];

void update_gameplay(void);
#pragma aux update_gameplay modify exact [eax];
void update_gameplay(void)
{
    short index;
    unsigned actor, stock, new_level;
    int level, slot, actor_index, column;
    short sector, sprite_index;
    short tag;
    short nearby;
    GameplayWord trigger_x, trigger_y;

    if (inventory_override_request > 0) {
        inventory_override_request = 0;
        inventory_override = (short)~(unsigned short)inventory_override;
        if (inventory_override == 0)
            select_item(0x13);
        else
            select_item(0x12);
    }
    if (inventory_override != previous_override) {
        previous_override = inventory_override;
        if (inventory_override != 0) {
            saved_status_right = status_right_tenths;
            index = 1;
            goto check_save_item;
        save_item:
            saved_item_enabled[slot] = item_enabled[slot];
            saved_item_stock[slot] = item_stock[slot];
            saved_item_alternate_stock[slot] = item_alternate_stock[slot];
            ++index;
        check_save_item:
            if ((slot = gameplay_eax((short)index)) <= 8) goto save_item;
            saved_left_icon = left_icon;
            saved_middle_icon = middle_icon;
            saved_right_icon = right_icon;
            saved_effect_count = effect_count;
            saved_status_flag = status_flag;
        } else {
            status_right_tenths = saved_status_right;
            index = 1;
            goto check_restore_item;
        restore_item:
            item_enabled[slot] = saved_item_enabled[slot];
            item_stock[slot] = saved_item_stock[slot];
            item_alternate_stock[slot] = saved_item_alternate_stock[slot];
            ++index;
        check_restore_item:
            if ((slot = gameplay_eax((short)index)) <= 8) goto restore_item;
            refresh_inventory();
            left_icon = saved_left_icon;
            middle_icon = saved_middle_icon;
            right_icon = saved_right_icon;
            effect_count = saved_effect_count;
            status_flag = saved_status_flag;
        }
    }
    if (inventory_override != 0) {
        status_right_tenths = 1000;
        index = 1;
        nearby = gameplay_edi(1);
        stock = gameplay_edx(250);
        goto check_grant_item;
    grant_item:
        item_enabled[slot] = (short)nearby;
        item_stock[slot] = (short)stock;
        item_alternate_stock[slot] = (short)stock;
        index += nearby;
    check_grant_item:
        if ((slot = gameplay_eax((short)index)) <= 3) goto grant_item;
        left_icon = 1;
        middle_icon = 1;
        right_icon = 1;
        effect_count = 50;
        status_flag = 1;
    }

    if ((long)(game_clock - last_step_clock) >= 15) {
        advance_clock = 1;
        last_step_clock = game_clock;
    } else {
        advance_clock = (short)gameplay_ecx(0);
    }
    check_teleport_terminals();
    index = 1;
    goto check_sector_count;
check_sector_trigger:
    trigger_y = stock;
    column = (int)gameplay_ecx((unsigned)(int)index);
    sector = level_sector_ids[(unsigned)trigger_y][gameplay_eax(column)].value;
    trigger_y = (GameplayWord)(long)sector;
    tag = sector_hitag[(long)trigger_y].value;
    tag &= 255;
    if (gameplay_eax(tag) != 1)
        goto advance_sector;
    trigger_x = level_sector_x[stock][column].value;
    trigger_y = level_sector_x[stock][column].y;
    nearby = 0;
    if (absolute_long((long)(trigger_x - player_x)) < 1500 &&
        absolute_long((long)(trigger_y - player_y)) < 1500)
        nearby = 1;
    actor = 0;
    goto check_actor_count;
check_actor_distance:
    if (actor_active[actor_index] != -1 &&
        (column = (int)actor_level[actor_index]) == (int)current_level) {
        sprite_index = actor_sprite[actor_index];
        if (absolute_long((long)(trigger_x - sprite_x[sprite_index].value)) < 1500 &&
            absolute_long((long)(trigger_y - sprite_y[sprite_index].value)) < 1500)
            nearby = 1;
    }
    ++actor;
check_actor_count:
    if ((actor_index = gameplay_eax((short)actor)) <= 500) goto check_actor_distance;
    if (gameplay_eax(nearby) == 1) {
        if (level_sector_ids[current_level][(short)index].active == 0)
            activate_sector(sector);
    } else {
        if (gameplay_eax(level_sector_ids[(int)gameplay_edx((unsigned)(int)current_level)][gameplay_eax((short)index)].active) == 1)
            activate_sector(sector);
    }
advance_sector:
    ++index;
check_sector_count:
    stock = (unsigned)(int)current_level;
    if ((short)index <= level_sector_count[stock]) goto check_sector_trigger;
    update_sector_events();
    tag = sector_hitag[player_sector].value;
    tag &= 0x400;
    if (gameplay_eax(tag) != 0)
        special_sector = player_sector;
    if ((long)(game_clock - last_sequence_clock) >= 12) {
        update_periodic_sequences();
        last_sequence_clock = game_clock;
    }
    update_proximity_sprites();
    update_float_sprites();
    update_moving_sprite_physics();
    update_projectiles();
    update_sector_panning();
    update_fall_triggers();
    update_level_effects(current_level);

    if (destination_level != -1) {
        current_level = destination_level;
        destination_level = -1;
        if (current_level != loaded_level) {
            column = loaded_level;
            level_left_icon[column].value = left_icon;
            level_middle_icon[column].value = middle_icon;
            level_right_icon[column].value = right_icon;
            modified_levels[column] = 1;
            save_level_and_load_board(column, mod_extension);
            initialize_destination(-1, destination_x, destination_y,
                                   destination_entry, modified_levels[current_level]);
            new_level = (unsigned)(int)current_level;
            left_icon = level_left_icon[new_level].value;
            middle_icon = level_middle_icon[new_level].value;
            right_icon = level_right_icon[new_level].value;
            loaded_level = current_level;
        }
    }
    update_actor_states();
}
