#include "saveio.h"

/* Fixed-size read fields in original file order. The surrounding
 * game-data routine retains its dynamic records and control flow.
 * Only the field-call body links. The private result is the end
 * of the last completed item, derived from its actual transfer count. */

unsigned char *save_read_fields_0(RuntimeStream *);
#pragma aux save_read_fields_0 parm [edi] value [ebx] modify exact [eax ebx ecx edx];
unsigned char *save_read_fields_0(RuntimeStream *stream)
{
    unsigned result;
    SAVE_FIELD(save_io_read, 0x13ce2, 0x2); /* local_player */
    SAVE_FIELD(save_io_read, 0x19028a, 0x2); /* first_player */
    SAVE_FIELD(save_io_read, 0x18fd78, 0x20); /* next_player */
    return save_data_image+0x18fd78+result*0x20;
}

unsigned char *save_read_fields_1(RuntimeStream *);
#pragma aux save_read_fields_1 parm [esi] value [ebx] modify exact [eax ebx ecx edx];
unsigned char *save_read_fields_1(RuntimeStream *stream)
{
    unsigned result;
    SAVE_FIELD(save_io_read, 0x5ad9c, 0x40); /* player_x */
    SAVE_FIELD(save_io_read, 0x5ad5c, 0x40); /* player_y */
    SAVE_FIELD(save_io_read, 0x5ad1c, 0x40); /* player_z */
    SAVE_FIELD(save_io_read, 0x62f8c, 0x40); /* player_horizon */
    SAVE_FIELD(save_io_read, 0x5ae1c, 0x40); /* board_state_5ae1c */
    SAVE_FIELD(save_io_read, 0x62f4c, 0x40); /* motion_state_62f4c */
    SAVE_FIELD(save_io_read, 0x6308c, 0x20); /* player_angle */
    SAVE_FIELD(save_io_read, 0x5acfc, 0x20); /* player_sector */
    SAVE_FIELD(save_io_read, 0x5acdc, 0x20); /* previous_player_sector */
    SAVE_FIELD(save_io_read, 0x62f2c, 0x20); /* board_state_62f2c */
    SAVE_FIELD(save_io_read, 0x6317c, 0x20); /* board_state_6317c */
    SAVE_FIELD(save_io_read, 0x630bc, 0x40); /* board_state_630bc */
    SAVE_FIELD(save_io_read, 0x6319c, 0x40); /* status_right_tenths */
    SAVE_FIELD(save_io_read, 0x6304c, 0x20); /* board_state_6304c */
    SAVE_FIELD(save_io_read, 0x6306c, 0x20); /* motion_state_6306c */
    SAVE_FIELD(save_io_read, 0x62f1c, 0x10); /* player_mode */
    SAVE_FIELD(save_io_read, 0x630ac, 0x10); /* motion_state_630ac */
    SAVE_FIELD(save_io_read, 0x5addc, 0x20); /* save_state_5addc */
    SAVE_FIELD(save_io_read, 0x5adfc, 0x20); /* save_state_5adfc */
    SAVE_FIELD(save_io_read, 0x5abbc, 0x40); /* save_state_5abbc */
    SAVE_FIELD(save_io_read, 0x5abfc, 0x40); /* save_state_5abfc */
    SAVE_FIELD(save_io_read, 0x289154, 0x2); /* numsectors */
    return save_data_image+0x289154+result*0x2;
}

unsigned char *save_read_fields_2(RuntimeStream *);
#pragma aux save_read_fields_2 parm [esi] value [ebx] modify exact [eax ebx ecx edx];
unsigned char *save_read_fields_2(RuntimeStream *stream)
{
    unsigned result;
    SAVE_FIELD(save_io_read, 0x289152, 0x2); /* numwalls */
    return save_data_image+0x289152+result*0x2;
}

unsigned char *save_read_fields_3(RuntimeStream *);
#pragma aux save_read_fields_3 parm [esi] value [ebx] modify exact [eax ebx ecx edx];
unsigned char *save_read_fields_3(RuntimeStream *stream)
{
    unsigned result;
    SAVE_FIELD(save_io_read, 0x2040a0, 0x2c000); /* sprite */
    SAVE_FIELD(save_io_read, 0x28891e, 0x802); /* engine_28891e */
    SAVE_FIELD(save_io_read, 0x1f6020, 0x2000); /* save_state_1f6020 */
    SAVE_FIELD(save_io_read, 0x1f9ca0, 0x2000); /* engine_1f9ca0 */
    SAVE_FIELD(save_io_read, 0x28811c, 0x802); /* hit_sprite_list_head */
    SAVE_FIELD(save_io_read, 0x1fdca0, 0x2000); /* save_state_1fdca0 */
    SAVE_FIELD(save_io_read, 0x1fbca0, 0x2000); /* next_sprite_stat */
    SAVE_FIELD(save_io_read, 0x770e8, 0x4); /* keyboard_forward */
    SAVE_FIELD(save_io_read, 0x770e4, 0x4); /* keyboard_strafe */
    SAVE_FIELD(save_io_read, 0x770ec, 0x4); /* keyboard_turn */
    SAVE_FIELD(save_io_read, 0x770c8, 0x4); /* selection */
    return save_data_image+0x770c8+result*0x4;
}

unsigned char *save_read_fields_4(RuntimeStream *);
#pragma aux save_read_fields_4 parm [esi] value [ebx] modify exact [eax ebx ecx edx];
unsigned char *save_read_fields_4(RuntimeStream *stream)
{
    unsigned result;
    SAVE_FIELD(save_io_read, 0x7defc, 0x2); /* input_actions */
    SAVE_FIELD(save_io_read, 0x7def7, 0x2); /* board_state_7def7 */
    SAVE_FIELD(save_io_read, 0x770c0, 0x4); /* second_player_selection */
    SAVE_FIELD(save_io_read, 0x7defe, 0x5); /* second_player_input */
    SAVE_FIELD(save_io_read, 0x5ac8c, 0x50); /* board_state_5ac8c */
    SAVE_FIELD(save_io_read, 0x55b6c, 0x50); /* previous_input */
    SAVE_FIELD(save_io_read, 0x1e5ac, 0x50); /* board_filename */
    SAVE_FIELD(save_io_read, 0x3cfa, 0x2); /* listener_index */
    SAVE_FIELD(save_io_read, 0x3cfc, 0x2); /* saved_mouse_buttons */
    SAVE_FIELD(save_io_read, 0x3cfe, 0x2); /* brightness */
    SAVE_FIELD(save_io_read, 0x7ded2, 0x2); /* near_sector */
    SAVE_FIELD(save_io_read, 0x7ded6, 0x2); /* near_sprite */
    SAVE_FIELD(save_io_read, 0x7ded4, 0x2); /* near_wall */
    SAVE_FIELD(save_io_read, 0x770b8, 0x4); /* actor_clock */
    SAVE_FIELD(save_io_read, 0x770ac, 0x4); /* save_state_770ac */
    SAVE_FIELD(save_io_read, 0x770a0, 0x4); /* near_tag_distance */
    SAVE_FIELD(save_io_read, 0x1cf6c, 0x20); /* board_state_1cf6c */
    SAVE_FIELD(save_io_read, 0x7deca, 0x2); /* board_state_7deca */
    SAVE_FIELD(save_io_read, 0x1ccac, 0x20); /* board_state_1ccac */
    SAVE_FIELD(save_io_read, 0x7dece, 0x2); /* board_state_7dece */
    SAVE_FIELD(save_io_read, 0x1cc8c, 0x20); /* board_state_1cc8c */
    SAVE_FIELD(save_io_read, 0x7dec4, 0x2); /* board_state_7dec4 */
    SAVE_FIELD(save_io_read, 0x1ceec, 0x80); /* board_state_1ceec */
    SAVE_FIELD(save_io_read, 0x7decc, 0x2); /* board_state_7decc */
    SAVE_FIELD(save_io_read, 0x1d08c, 0x80); /* board_state_1d08c */
    SAVE_FIELD(save_io_read, 0x7dec2, 0x2); /* board_state_7dec2 */
    SAVE_FIELD(save_io_read, 0x1d10c, 0x20); /* board_state_1d10c */
    SAVE_FIELD(save_io_read, 0x1cc4c, 0x20); /* board_state_1cc4c */
    SAVE_FIELD(save_io_read, 0x1cc6c, 0x20); /* board_state_1cc6c */
    SAVE_FIELD(save_io_read, 0x7dec6, 0x2); /* board_state_7dec6 */
    SAVE_FIELD(save_io_read, 0x1ce2c, 0x40); /* board_state_1ce2c */
    SAVE_FIELD(save_io_read, 0x1ceac, 0x40); /* board_state_1ceac */
    SAVE_FIELD(save_io_read, 0x1cdec, 0x40); /* board_state_1cdec */
    SAVE_FIELD(save_io_read, 0x1ce6c, 0x40); /* board_state_1ce6c */
    SAVE_FIELD(save_io_read, 0x1cd2c, 0x40); /* board_state_1cd2c */
    SAVE_FIELD(save_io_read, 0x7debe, 0x2); /* board_state_7debe */
    SAVE_FIELD(save_io_read, 0x1bb3c, 0x140); /* board_state_1bb3c */
    SAVE_FIELD(save_io_read, 0x1bc7c, 0x40); /* board_state_1bc7c */
    SAVE_FIELD(save_io_read, 0x1babc, 0x40); /* board_state_1babc */
    SAVE_FIELD(save_io_read, 0x1bcbc, 0x40); /* board_state_1bcbc */
    SAVE_FIELD(save_io_read, 0x1c3fc, 0x40); /* board_state_1c3fc */
    SAVE_FIELD(save_io_read, 0x1c12c, 0x40); /* board_state_1c12c */
    SAVE_FIELD(save_io_read, 0x1bafc, 0x40); /* board_state_1bafc */
    SAVE_FIELD(save_io_read, 0x1c43c, 0x400); /* board_state_1c43c */
    SAVE_FIELD(save_io_read, 0x1c83c, 0x400); /* board_state_1c83c */
    SAVE_FIELD(save_io_read, 0x1bab4, 0x8); /* board_state_1bab4 */
    SAVE_FIELD(save_io_read, 0x1cc44, 0x8); /* board_state_1cc44 */
    SAVE_FIELD(save_io_read, 0x7dec0, 0x2); /* board_state_7dec0 */
    SAVE_FIELD(save_io_read, 0x1c2fc, 0x100); /* board_state_1c2fc */
    SAVE_FIELD(save_io_read, 0x1c1fc, 0x100); /* board_state_1c1fc */
    SAVE_FIELD(save_io_read, 0x1baa4, 0x10); /* board_state_1baa4 */
    SAVE_FIELD(save_io_read, 0x1ba94, 0x10); /* board_state_1ba94 */
    SAVE_FIELD(save_io_read, 0x1bd1c, 0x400); /* board_state_1bd1c */
    SAVE_FIELD(save_io_read, 0x1cc3c, 0x8); /* board_state_1cc3c */
    SAVE_FIELD(save_io_read, 0x7debc, 0x2); /* board_state_7debc */
    SAVE_FIELD(save_io_read, 0x1c17c, 0x80); /* board_state_1c17c */
    SAVE_FIELD(save_io_read, 0x1c16c, 0x10); /* board_state_1c16c */
    SAVE_FIELD(save_io_read, 0x1bd0c, 0x10); /* board_state_1bd0c */
    SAVE_FIELD(save_io_read, 0x1c11c, 0x10); /* board_state_1c11c */
    SAVE_FIELD(save_io_read, 0x1bcfc, 0x10); /* board_state_1bcfc */
    SAVE_FIELD(save_io_read, 0x1a214, 0x10); /* board_state_1a214 */
    SAVE_FIELD(save_io_read, 0x1ba34, 0x10); /* board_state_1ba34 */
    SAVE_FIELD(save_io_read, 0x1a224, 0x10); /* board_state_1a224 */
    SAVE_FIELD(save_io_read, 0x1a204, 0x10); /* board_state_1a204 */
    SAVE_FIELD(save_io_read, 0x1ba84, 0x10); /* board_state_1ba84 */
    SAVE_FIELD(save_io_read, 0x199e4, 0x20); /* fini_table_end */
    SAVE_FIELD(save_io_read, 0x1ba44, 0x20); /* board_state_1ba44 */
    SAVE_FIELD(save_io_read, 0x1ba64, 0x20); /* board_state_1ba64 */
    return save_data_image+0x1ba64+result*0x20;
}

unsigned char *save_read_fields_5(RuntimeStream *);
#pragma aux save_read_fields_5 parm [esi] value [ebx] modify exact [eax ebx ecx edx];
unsigned char *save_read_fields_5(RuntimeStream *stream)
{
    unsigned result;
    SAVE_FIELD(save_io_read, 0x1b234, 0x800); /* restore_values */
    SAVE_FIELD(save_io_read, 0x1aa34, 0x800); /* activation_state_1aa34 */
    SAVE_FIELD(save_io_read, 0x19a04, 0x800); /* save_state_19a04 */
    SAVE_FIELD(save_io_read, 0x3e04, 0x4); /* restore_count */
    SAVE_FIELD(save_io_read, 0x287e88, 0x4); /* totalclock */
    SAVE_FIELD(save_io_read, 0x3cea, 0x4); /* last_tick */
    SAVE_FIELD(save_io_read, 0x287e74, 0x4); /* save_state_287e74 */
    SAVE_FIELD(save_io_read, 0x287e78, 0x4); /* board_state_287e78 */
    SAVE_FIELD(save_io_read, 0x289156, 0x2); /* numpalookups */
    SAVE_FIELD(save_io_read, 0x286ba8, 0x4); /* engine_286ba8 */
    SAVE_FIELD(save_io_read, 0x286ba0, 0x4); /* engine_286ba0 */
    return save_data_image+0x286ba0+result*0x4;
}

unsigned char *save_read_fields_6(RuntimeStream *);
#pragma aux save_read_fields_6 parm [esi] value [ebx] modify exact [eax ebx ecx edx];
unsigned char *save_read_fields_6(RuntimeStream *stream)
{
    unsigned result;
    SAVE_FIELD(save_io_read, 0x286b88, 0x4); /* engine_286b88 */
    SAVE_FIELD(save_io_read, 0x1ed1a0, 0x200); /* engine_1ed1a0 */
    SAVE_FIELD(save_io_read, 0x289150, 0x2); /* engine_289150 */
    SAVE_FIELD(save_io_read, 0x202c, 0x4); /* save_state_202c */
    SAVE_FIELD(save_io_read, 0x2030, 0x4); /* last_sequence_clock */
    SAVE_FIELD(save_io_read, 0x2034, 0x4); /* last_frame_tick */
    SAVE_FIELD(save_io_read, 0x7aa3c, 0x34); /* level_sector_count */
    SAVE_FIELD(save_io_read, 0x7639c, 0xd00); /* level_sector_ids */
    SAVE_FIELD(save_io_read, 0x7499c, 0x1a00); /* level_sector_x */
    SAVE_FIELD(save_io_read, 0x7a9a0, 0x9c); /* level_left_icon */
    SAVE_FIELD(save_io_read, 0x2038, 0x2); /* left_icon */
    SAVE_FIELD(save_io_read, 0x203a, 0x2); /* middle_icon */
    SAVE_FIELD(save_io_read, 0x203c, 0x2); /* right_icon */
    SAVE_FIELD(save_io_read, 0x7def0, 0x2); /* activation_sprite_count */
    SAVE_FIELD(save_io_read, 0x7497c, 0x20); /* activation_sprite_index */
    SAVE_FIELD(save_io_read, 0x7496c, 0x10); /* activation_counter */
    SAVE_FIELD(save_io_read, 0x7def2, 0x2); /* smoothed_mouse_dx */
    SAVE_FIELD(save_io_read, 0x203e, 0x2); /* toggled_word */
    SAVE_FIELD(save_io_read, 0x7dea2, 0x1a); /* modified_levels */
    return save_data_image+0x7dea2+result*0x1a;
}

unsigned char *save_read_fields_7(RuntimeStream *);
#pragma aux save_read_fields_7 parm [esi] value [ebx] modify exact [eax ebx ecx edx];
unsigned char *save_read_fields_7(RuntimeStream *stream)
{
    unsigned result;
    SAVE_FIELD(save_io_read, 0x7a998, 0x4); /* destination_x */
    SAVE_FIELD(save_io_read, 0x7a99c, 0x4); /* destination_y */
    SAVE_FIELD(save_io_read, 0x7deee, 0x2); /* destination_entry */
    SAVE_FIELD(save_io_read, 0x2041, 0x21c); /* level_names */
    SAVE_FIELD(save_io_read, 0x7deec, 0x2); /* difficulty_divisor */
    SAVE_FIELD(save_io_read, 0x225d, 0x2); /* effect_count */
    SAVE_FIELD(save_io_read, 0x225f, 0x2); /* effect_speed */
    SAVE_FIELD(save_io_read, 0x2261, 0x2); /* status_flag */
    SAVE_FIELD(save_io_read, 0x2263, 0x2); /* interaction_state_2263 */
    SAVE_FIELD(save_io_read, 0x2265, 0x2); /* toggled_mode */
    SAVE_FIELD(save_io_read, 0x2267, 0x10); /* item_enabled */
    SAVE_FIELD(save_io_read, 0x2277, 0x10); /* item_stock */
    SAVE_FIELD(save_io_read, 0x2287, 0x10); /* item_alternate_stock */
    SAVE_FIELD(save_io_read, 0x2297, 0x2); /* player_action */
    SAVE_FIELD(save_io_read, 0x2299, 0x2); /* save_state_2299 */
    SAVE_FIELD(save_io_read, 0x7a994, 0x4); /* ticks_per_step */
    SAVE_FIELD(save_io_read, 0x7a990, 0x4); /* last_step_clock */
    SAVE_FIELD(save_io_read, 0x229b, 0x2); /* advance_clock */
    SAVE_FIELD(save_io_read, 0x7494c, 0x20); /* board_state_7494c */
    SAVE_FIELD(save_io_read, 0x729dc, 0x20); /* interaction_state_729dc */
    SAVE_FIELD(save_io_read, 0x709dc, 0x2000); /* sprite_actor_index */
    SAVE_FIELD(save_io_read, 0x7dab8, 0x3ea); /* actor_sprite_index */
    SAVE_FIELD(save_io_read, 0x7eac1, 0x1f5); /* actor_board */
    SAVE_FIELD(save_io_read, 0x772c4, 0x177c); /* saved_actor_x */
    SAVE_FIELD(save_io_read, 0x7ecb6, 0x1f5); /* actor_enabled */
    SAVE_FIELD(save_io_read, 0x7d6ce, 0x3ea); /* saved_actor_lotag */
    SAVE_FIELD(save_io_read, 0x7e4e2, 0x1f5); /* actor_sequence_initial */
    SAVE_FIELD(save_io_read, 0x7cefa, 0x3ea); /* actor_health */
    SAVE_FIELD(save_io_read, 0x79214, 0x7d4); /* actor_z_offset */
    SAVE_FIELD(save_io_read, 0x7eeab, 0x1f5); /* actor_projectile_type */
    SAVE_FIELD(save_io_read, 0x7f295, 0x1f5); /* actor_recovery_counter */
    SAVE_FIELD(save_io_read, 0x7f48a, 0x1f5); /* actor_visibility_timer */
    SAVE_FIELD(save_io_read, 0x7e2ed, 0x1f5); /* actor_state */
    SAVE_FIELD(save_io_read, 0x7e6d7, 0x1f5); /* actor_frame */
    SAVE_FIELD(save_io_read, 0x7e0f8, 0x1f5); /* actor_state_byte */
    SAVE_FIELD(save_io_read, 0x799e8, 0x7d4); /* actor_x */
    SAVE_FIELD(save_io_read, 0x7a1bc, 0x7d4); /* actor_y */
    SAVE_FIELD(save_io_read, 0x7d2e4, 0x3ea); /* actor_sector */
    SAVE_FIELD(save_io_read, 0x78a40, 0x7d4); /* actor_first_waypoint */
    SAVE_FIELD(save_io_read, 0x229d, 0x800); /* waypoint_x */
    SAVE_FIELD(save_io_read, 0x729fc, 0x1f50); /* actor_destination_x */
    SAVE_FIELD(save_io_read, 0x7f0a0, 0x1f5); /* actor_kind */
    SAVE_FIELD(save_io_read, 0x7f67f, 0x1f5); /* actor_mode */
    SAVE_FIELD(save_io_read, 0x7e8cc, 0x1f5); /* actor_profile */
    SAVE_FIELD(save_io_read, 0x7abc0, 0x233a); /* actor_tiles */
    SAVE_FIELD(save_io_read, 0x7df03, 0x1f5); /* actor_delay_byte */
    SAVE_FIELD(save_io_read, 0x2a9d, 0x13f); /* template_cstat */
    SAVE_FIELD(save_io_read, 0x2bdc, 0x2); /* weapon_action */
    SAVE_FIELD(save_io_read, 0x2bde, 0x2); /* weapon_animation_state */
    SAVE_FIELD(save_io_read, 0x2be0, 0x2); /* selected_weapon */
    SAVE_FIELD(save_io_read, 0x2be2, 0x2); /* selected_weapon_2be2 */
    SAVE_FIELD(save_io_read, 0x2be4, 0x2); /* weapon_tile */
    SAVE_FIELD(save_io_read, 0x7dee8, 0x2); /* weapon_x_offset */
    SAVE_FIELD(save_io_read, 0x7deea, 0x2); /* weapon_y_offset */
    SAVE_FIELD(save_io_read, 0x2be6, 0x2); /* close_hit_tile */
    SAVE_FIELD(save_io_read, 0x7dee6, 0x2); /* alternate_fire_requested */
    SAVE_FIELD(save_io_read, 0x6f87c, 0x20); /* force_attack_frame */
    SAVE_FIELD(save_io_read, 0x709bc, 0x20); /* defer_mode_change */
    SAVE_FIELD(save_io_read, 0x6f89c, 0x20); /* player_hit_timer */
    SAVE_FIELD(save_io_read, 0x7097c, 0x40); /* player_hit_x */
    SAVE_FIELD(save_io_read, 0x7093c, 0x40); /* player_hit_y */
    SAVE_FIELD(save_io_read, 0x2be8, 0x2); /* moving_sprite_count */
    SAVE_FIELD(save_io_read, 0x6fcbc, 0x800); /* moving_sprites */
    SAVE_FIELD(save_io_read, 0x2bea, 0x2); /* pan_sector_count */
    SAVE_FIELD(save_io_read, 0x704bc, 0x80); /* pan_sectors */
    SAVE_FIELD(save_io_read, 0x2bec, 0x2); /* float_sprite_count */
    SAVE_FIELD(save_io_read, 0x6f8bc, 0x400); /* float_sprite_list */
    SAVE_FIELD(save_io_read, 0x2bee, 0x2); /* projectile_count */
    SAVE_FIELD(save_io_read, 0x7053c, 0x400); /* projectile_list */
    SAVE_FIELD(save_io_read, 0x7dee0, 0x2); /* active */
    SAVE_FIELD(save_io_read, 0x67a3c, 0x400); /* list */
    SAVE_FIELD(save_io_read, 0x2bf0, 0x2); /* map_x */
    SAVE_FIELD(save_io_read, 0x2bf2, 0x2); /* map_scale_or_y */
    SAVE_FIELD(save_io_read, 0x2bf4, 0x2); /* map_offset_y */
    SAVE_FIELD(save_io_read, 0x7dee2, 0x2); /* mouse_buttons */
    SAVE_FIELD(save_io_read, 0x7deda, 0x2); /* mouse_dx */
    SAVE_FIELD(save_io_read, 0x7dedc, 0x2); /* mouse_dy */
    SAVE_FIELD(save_io_read, 0x2bf6, 0x2); /* button_latch_disabled */
    SAVE_FIELD(save_io_read, 0x2bf8, 0x2); /* held_sprite */
    SAVE_FIELD(save_io_read, 0x2bfa, 0x2); /* map_mode */
    SAVE_FIELD(save_io_read, 0x2bfc, 0x2); /* mouse_motion_disabled */
    SAVE_FIELD(save_io_read, 0x3b9d, 0x48); /* inventory_grid */
    return save_data_image+0x3b9d+result*0x48;
}

unsigned char *save_read_fields_8(RuntimeStream *);
#pragma aux save_read_fields_8 parm [esi] value [ebx] modify exact [eax ebx ecx edx];
unsigned char *save_read_fields_8(RuntimeStream *stream)
{
    unsigned result;
    SAVE_FIELD(save_io_read, 0x7dede, 0x2); /* actor_target */
    SAVE_FIELD(save_io_read, 0x7dee4, 0x2); /* special_sector */
    SAVE_FIELD(save_io_read, 0x3be6, 0x2); /* trigger_count */
    SAVE_FIELD(save_io_read, 0x77124, 0x194); /* trigger_sprite */
    return save_data_image+0x77124+result*0x194;
}
