/* Startup configuration for the actor slots of every board. */
#ifdef ACTOR_CLOBBER_CONTEXT
#define ACTOR_DESTINATION_CONTEXT 1
#define ACTOR_DESTINATION_VALUES 1
#define ACTOR_DESTINATION_CLOBBERS 1
#endif

enum { ACTOR_SLOTS = 501, ACTOR_DISABLED = -1 };

typedef struct {
    long x, y, parameter_one, parameter_two;
} ActorDestination;

typedef struct {
    long x, y, z;
} SavedActorPosition;

typedef struct {
    short first, next;
} ActorWaypoints;

typedef struct {
    short base, mode_one, mode_two, mode_three, mode_four;
    short mode_five, mode_six, reserved_seven, reserved_eight;
} ActorTiles;

typedef char actor_destination_stride[(sizeof(ActorDestination) == 16) ? 1 : -1];
typedef char saved_actor_position_stride[(sizeof(SavedActorPosition) == 12) ? 1 : -1];
typedef char startup_actor_waypoints_stride[(sizeof(ActorWaypoints) == 4) ? 1 : -1];
typedef char startup_actor_tile_rows_stride[(sizeof(ActorTiles) == 18) ? 1 : -1];

extern ActorDestination startup_actor_destinations[ACTOR_SLOTS];
extern SavedActorPosition startup_saved_actor_positions[ACTOR_SLOTS];
extern ActorWaypoints startup_actor_waypoints[ACTOR_SLOTS];
extern ActorTiles startup_actor_tile_rows[ACTOR_SLOTS];
extern long actor_z_offset[ACTOR_SLOTS];
extern short actor_health[ACTOR_SLOTS], saved_actor_lotag[ACTOR_SLOTS];
extern signed char actor_enabled[ACTOR_SLOTS];
extern unsigned char actor_board[ACTOR_SLOTS], actor_mode[ACTOR_SLOTS];
extern unsigned char actor_profile[ACTOR_SLOTS], actor_sequence_initial[ACTOR_SLOTS];
extern unsigned char actor_projectile_type[ACTOR_SLOTS];

extern short actor_slot_in_ax(short);
#pragma aux actor_slot_in_ax = "" parm [ax] value [ax] modify exact [];

#ifndef ACTOR_DESTINATION_CONTEXT
#ifdef ACTOR_DISABLE_CONTEXT
extern int promoted_slot(int);
#pragma aux promoted_slot = "" parm nomemory [edx] value [edx] modify exact [edx];
void board_actor_disable_context(void);
#pragma aux board_actor_disable_context modify exact [eax];
#else
void board_actor_configuration_context(void);
#pragma aux board_actor_configuration_context modify exact [eax];
#endif
#endif

#ifdef ACTOR_DESTINATION_CONTEXT
/* The empty auxiliaries carry their actual input through the named register. */
extern long actor_destination_zero_in_ebx(long);
#pragma aux actor_destination_zero_in_ebx = "" parm [ebx] value [ebx] modify exact [];
#ifdef ACTOR_DESTINATION_VALUES
extern long actor_destination_value_in_esi(long);
#ifdef ACTOR_DESTINATION_CLOBBERS
#pragma aux actor_destination_value_in_esi = "" parm [esi] value [esi] modify exact [esi];
#else
#pragma aux actor_destination_value_in_esi = "" parm [esi] value [esi] modify exact [];
#endif
extern long actor_destination_value_in_edi(long);
#ifdef ACTOR_DESTINATION_CLOBBERS
#pragma aux actor_destination_value_in_edi = "" parm [edi] value [edi] modify exact [edi];
#else
#pragma aux actor_destination_value_in_edi = "" parm [edi] value [edi] modify exact [];
#endif
extern long actor_destination_value_in_eax(long);
#pragma aux actor_destination_value_in_eax = "" parm [eax] value [eax] modify exact [];
#endif
extern long actor_destination_offset_in_edx(long);
#pragma aux actor_destination_offset_in_edx = "" parm [edx] value [edx] modify exact [];

/* A character view of the complete array preserves the row's byte offset. */
#define destination_at(offset) \
    (*(ActorDestination *)((char *)&startup_actor_destinations + (offset)))

#ifdef ACTOR_DESTINATION_VALUES
#ifdef ACTOR_DESTINATION_CLOBBERS
void board_actor_clobber_context(void);
#pragma aux board_actor_clobber_context modify exact [eax];
#else
void board_actor_value_context(void);
#pragma aux board_actor_value_context modify exact [eax];
#endif
#else
void board_actor_destination_context(void);
#pragma aux board_actor_destination_context modify exact [eax];
#endif

#ifdef ACTOR_DESTINATION_VALUES
#ifdef ACTOR_DESTINATION_CLOBBERS
void board_actor_clobber_context(void)
#else
void board_actor_value_context(void)
#endif
#else
void board_actor_destination_context(void)
#endif
#else
#ifdef ACTOR_DISABLE_CONTEXT
void board_actor_disable_context(void)
#else
void board_actor_configuration_context(void)
#endif
#endif
{
    short slot, configured_slot;
#ifdef ACTOR_DESTINATION_CONTEXT
#ifdef ACTOR_DESTINATION_VALUES
    long destination_offset;
    long destination_value_esi;
    long destination_value_edi;
    long destination_value_eax;
#endif
    long destination_zero;
#endif

#ifdef ACTOR_DISABLE_CONTEXT
    for (slot = 0; promoted_slot((int)slot) <= 500; ++slot)
#else
    for (slot = 0; slot < ACTOR_SLOTS; ++slot)
#endif
        actor_enabled[slot] = ACTOR_DISABLED;

    /* Configure actors in original write order. */
    actor_enabled[1] = 5;
    actor_board[1] = 1;
    startup_saved_actor_positions[1].y = -0x1600L;
    actor_z_offset[1] = 0;
    startup_actor_tile_rows[1].mode_one = 0;
    startup_actor_tile_rows[1].mode_five = 0;
    startup_actor_tile_rows[1].mode_six = 0;
    startup_actor_waypoints[1].first = 0;
    actor_health[2] = 1000;
    startup_saved_actor_positions[1].x = -0x3c00L;
    actor_projectile_type[1] = 3;
    actor_mode[1] = 2;
    startup_actor_destinations[1].x = 0;
    startup_actor_destinations[1].y = 0;
    startup_actor_destinations[1].parameter_one = 0;
    startup_actor_destinations[1].parameter_two = 0;
    actor_z_offset[2] = 0;
    actor_sequence_initial[2] = 16;
    startup_actor_destinations[2].x = 0;
    startup_actor_destinations[2].y = 0;
    startup_actor_destinations[2].parameter_one = 0;
    actor_sequence_initial[1] = 16;
    saved_actor_lotag[1] = 0x2e65;
    startup_actor_tile_rows[1].base = 2562;
    startup_actor_tile_rows[1].mode_two = 2562;
    startup_actor_tile_rows[1].mode_three = 2562;
    startup_actor_tile_rows[1].mode_four = 2562;
    saved_actor_lotag[2] = 0x1a65;
    saved_actor_lotag[3] = 0x1a65;
    startup_actor_tile_rows[3].base = 2672;
    startup_actor_tile_rows[3].mode_two = 2672;
    startup_actor_tile_rows[3].mode_three = 2672;
    startup_actor_tile_rows[3].mode_four = 2672;
    actor_health[1] = 1000;
    actor_profile[1] = 1;
    actor_enabled[2] = 2;
    actor_board[2] = 1;
    actor_mode[2] = 2;
    startup_actor_destinations[2].parameter_two = 0;
    actor_enabled[3] = 2;
    actor_z_offset[3] = 0;
    startup_actor_tile_rows[3].mode_five = 0;
    startup_saved_actor_positions[2].x = -0x2600L;
    startup_saved_actor_positions[2].y = -0x1700L;
    actor_board[3] = 1;
    actor_projectile_type[3] = 0;
    actor_projectile_type[2] = 0;
    startup_actor_tile_rows[2].mode_one = 0;
    startup_actor_tile_rows[2].mode_five = 0;
    startup_actor_tile_rows[2].mode_six = 0;
    startup_actor_waypoints[2].first = 0;
    actor_sequence_initial[3] = 16;
    actor_profile[3] = 1;
    actor_profile[2] = 1;
    startup_saved_actor_positions[3].y = 0x6a00L;
    startup_actor_tile_rows[2].base = 2672;
    startup_actor_tile_rows[2].mode_two = 2672;
    startup_actor_tile_rows[2].mode_three = 2672;
    startup_actor_tile_rows[2].mode_four = 2672;
    actor_health[3] = 1000;
    startup_saved_actor_positions[3].x = 0x300L;
    startup_actor_tile_rows[3].mode_one = 0;
    actor_mode[3] = 2;
    startup_actor_tile_rows[3].mode_six = 0;
    startup_actor_waypoints[3].first = 0;
    actor_health[4] = 1000;
    actor_enabled[5] = 0;
    actor_enabled[4] = 0;
    actor_board[4] = 1;
    startup_actor_tile_rows[4].mode_two = 2296;
    startup_actor_tile_rows[4].mode_three = 2296;
    startup_actor_tile_rows[4].mode_four = 2296;
    startup_actor_destinations[3].x = 0;
    startup_actor_destinations[3].y = 0;
    startup_actor_destinations[3].parameter_one = 0;
    startup_actor_destinations[3].parameter_two = 0;
    actor_z_offset[4] = 0;
    actor_projectile_type[4] = 2;
    saved_actor_lotag[5] = 0x565;
    startup_saved_actor_positions[4].x = -0x4100L;
    startup_saved_actor_positions[4].y = 0x200L;
    actor_health[5] = 1000;
    actor_health[21] = 1000;
    actor_profile[4] = 1;
    actor_mode[4] = 2;
    actor_board[21] = 2;
    actor_sequence_initial[4] = 16;
    actor_board[5] = 1;
    startup_actor_tile_rows[4].base = 2406;
    startup_actor_tile_rows[4].mode_one = 2406;
    startup_actor_tile_rows[4].mode_five = 2406;
    startup_actor_tile_rows[4].mode_six = 2406;
    startup_actor_tile_rows[5].base = 2406;
    startup_actor_tile_rows[5].mode_one = 2406;
    actor_sequence_initial[21] = 16;
    actor_projectile_type[21] = 2;
    saved_actor_lotag[4] = 0x565;
    startup_saved_actor_positions[5].x = -0x1e00L;
    startup_actor_waypoints[4].first = 0;
    startup_saved_actor_positions[5].y = -0x100L;
    actor_sequence_initial[5] = 16;
    startup_actor_destinations[4].x = 0;
    startup_actor_destinations[4].y = 0;
    startup_actor_destinations[4].parameter_one = 0;
    startup_actor_destinations[4].parameter_two = 0;
    actor_z_offset[5] = 0;
    startup_actor_destinations[5].x = 0;
    startup_actor_destinations[5].y = 0;
    startup_actor_destinations[5].parameter_one = 0;
    startup_actor_destinations[5].parameter_two = 0;
    actor_z_offset[21] = 0;
    actor_projectile_type[5] = 2;
    startup_actor_tile_rows[5].mode_five = 2406;
    startup_actor_tile_rows[5].mode_six = 2406;
    saved_actor_lotag[21] = 0x565;
    actor_profile[5] = 1;
    actor_mode[5] = 2;
    startup_actor_tile_rows[5].mode_two = 2296;
    startup_actor_tile_rows[5].mode_three = 2296;
    startup_actor_tile_rows[5].mode_four = 2296;
    startup_actor_waypoints[5].first = 0;
    startup_saved_actor_positions[21].x = 0x100L;
    actor_enabled[21] = 0;
    startup_saved_actor_positions[21].y = 0x5600L;
    actor_profile[21] = 1;
    actor_mode[21] = 1;
    startup_actor_tile_rows[21].base = 2406;
    startup_actor_tile_rows[21].mode_one = 2406;
    startup_actor_tile_rows[21].mode_five = 2406;
    startup_actor_tile_rows[21].mode_six = 2406;
    startup_actor_destinations[21].x = 0;
    startup_actor_destinations[21].y = 0;
    startup_actor_destinations[21].parameter_one = 0;
    startup_actor_destinations[21].parameter_two = 0;
    actor_enabled[41] = 4;
    actor_board[41] = 3;
    actor_z_offset[41] = 0;
    startup_actor_destinations[41].parameter_one = 0x91a5L;
    startup_actor_tile_rows[21].mode_two = 2296;
    startup_actor_tile_rows[21].mode_three = 2296;
    startup_actor_tile_rows[21].mode_four = 2296;
    startup_actor_waypoints[21].first = 0;
    startup_saved_actor_positions[41].y = 0x92a0L;
    actor_sequence_initial[41] = 8;
    startup_actor_destinations[41].x = 0x6c5aL;
    startup_actor_destinations[42].parameter_one = 0;
    startup_saved_actor_positions[41].x = 0x6c5aL;
    startup_actor_destinations[41].y = 0x92a0L;
    startup_actor_destinations[41].parameter_two = 0x92a0L;
    actor_projectile_type[41] = 1;
    saved_actor_lotag[41] = 0x765;
    startup_actor_tile_rows[41].base = 2488;
    startup_actor_tile_rows[41].mode_one = 2488;
    startup_actor_tile_rows[41].mode_two = 2488;
    startup_actor_tile_rows[41].mode_three = 2488;
    startup_actor_tile_rows[41].mode_four = 2488;
    startup_actor_tile_rows[41].mode_five = 2488;
    actor_health[42] = 1000;
    actor_health[41] = 1000;
    saved_actor_lotag[42] = 0x865;
    actor_profile[41] = 2;
    actor_board[42] = 3;
    startup_actor_destinations[42].x = 0;
    startup_actor_destinations[42].parameter_two = 0;
    actor_mode[41] = 5;
    startup_actor_destinations[42].y = 0;
    startup_saved_actor_positions[42].y = 0x7a00L;
    startup_actor_tile_rows[42].base = 2488;
    startup_actor_tile_rows[42].mode_one = 2488;
    startup_actor_tile_rows[42].mode_two = 2488;
    startup_actor_tile_rows[42].mode_three = 2488;
    startup_actor_tile_rows[42].mode_four = 2488;
    startup_actor_tile_rows[42].mode_five = 2488;
    startup_actor_waypoints[41].first = 0;
    actor_enabled[42] = 4;
    actor_sequence_initial[42] = 5;
    startup_actor_waypoints[42].first = 0;
    startup_saved_actor_positions[42].x = 0x9400L;
    actor_z_offset[42] = 0;
    actor_enabled[43] = 4;
    startup_saved_actor_positions[43].y = 0x7a00L;
    actor_projectile_type[42] = 1;
    actor_board[43] = 3;
    actor_profile[42] = 2;
    actor_mode[42] = 2;
    startup_saved_actor_positions[43].x = 0x6de8L;
    actor_z_offset[43] = 0;
    actor_projectile_type[43] = 1;
    actor_profile[43] = 2;
    actor_mode[43] = 2;
    startup_actor_destinations[43].x = 0;
    startup_actor_destinations[43].y = 0;
    startup_actor_destinations[43].parameter_one = 0;
    actor_z_offset[61] = 0;
    actor_sequence_initial[43] = 5;
    saved_actor_lotag[43] = 0x965;
    startup_actor_destinations[43].parameter_two = 0;
    startup_actor_tile_rows[43].base = 2488;
    startup_actor_tile_rows[43].mode_one = 2488;
    startup_actor_tile_rows[43].mode_two = 2488;
    startup_actor_tile_rows[43].mode_three = 2488;
    startup_actor_tile_rows[43].mode_four = 2488;
    startup_actor_tile_rows[43].mode_five = 2488;
    actor_health[61] = 1000;
    saved_actor_lotag[61] = 0x1165;
    startup_actor_destinations[61].y = -0x900L;
    actor_health[43] = 1000;
    actor_board[61] = 4;
    startup_saved_actor_positions[61].y = -0x900L;
    startup_actor_waypoints[43].first = 0;
    startup_actor_destinations[61].x = -0x2600L;
    actor_z_offset[62] = 0;
    startup_saved_actor_positions[61].x = -0x2600L;
    actor_sequence_initial[61] = 16;
    actor_mode[61] = 5;
    actor_enabled[61] = 0;
    startup_actor_tile_rows[62].mode_two = 2296;
    startup_actor_tile_rows[62].mode_three = 2296;
    startup_actor_tile_rows[62].mode_four = 2296;
    actor_projectile_type[61] = 2;
    startup_actor_tile_rows[61].base = 2406;
    startup_actor_tile_rows[61].mode_one = 2406;
    startup_actor_tile_rows[61].mode_two = 2296;
    startup_actor_tile_rows[61].mode_three = 2296;
    startup_actor_tile_rows[61].mode_four = 2296;
    startup_actor_tile_rows[61].mode_five = 2406;
    startup_saved_actor_positions[61].z = 0x1c48L;
    startup_actor_destinations[62].x = 0;
    startup_actor_destinations[62].y = 0;
    actor_profile[61] = 1;
    startup_actor_waypoints[61].first = 0;
    actor_enabled[62] = 0;
    actor_board[62] = 4;
    startup_actor_destinations[61].parameter_one = -0x5e80L;
    startup_actor_destinations[61].parameter_two = -0x880L;
    startup_saved_actor_positions[62].x = 0x1400L;
    startup_saved_actor_positions[62].y = 0x1200L;
    actor_health[62] = 1000;
    actor_projectile_type[62] = 2;
    saved_actor_lotag[62] = 0x565;
    actor_sequence_initial[62] = 16;
    actor_profile[62] = 1;
    actor_mode[62] = 6;
    startup_actor_tile_rows[62].base = 2406;
    startup_actor_tile_rows[62].mode_one = 2406;
    startup_actor_tile_rows[62].mode_five = 2406;
    startup_actor_tile_rows[62].mode_six = 2406;
    startup_actor_waypoints[62].first = 0;
    startup_actor_destinations[62].parameter_one = 0;
    startup_actor_destinations[62].parameter_two = 0;
    actor_z_offset[63] = 0;
    actor_board[63] = 4;
    startup_saved_actor_positions[63].y = 0x13c0L;
    startup_actor_destinations[63].y = 0x13c0L;
    startup_saved_actor_positions[64].z = 0x1c00L;
    actor_enabled[63] = 0;
    actor_health[63] = 1000;
    startup_saved_actor_positions[63].x = 0x23c0L;
    actor_projectile_type[63] = 2;
    saved_actor_lotag[63] = 0x1365;
    saved_actor_lotag[64] = 0x565;
    startup_actor_destinations[64].x = 0;
    startup_actor_destinations[64].y = 0;
    startup_actor_destinations[64].parameter_one = 0;
    startup_actor_destinations[64].parameter_two = 0;
    startup_saved_actor_positions[65].y = 0;
    actor_z_offset[65] = 0;
    saved_actor_lotag[65] = 0x565;
    startup_actor_tile_rows[63].base = 2406;
    startup_actor_tile_rows[63].mode_one = 2406;
    startup_actor_tile_rows[63].mode_five = 2406;
    startup_actor_tile_rows[63].mode_six = 2406;
    startup_actor_destinations[63].x = 0x23c0L;
    actor_sequence_initial[63] = 16;
    actor_profile[63] = 1;
    actor_mode[63] = 0;
    startup_actor_destinations[63].parameter_two = 0x1cc0L;
    actor_z_offset[64] = 0;
    startup_actor_tile_rows[63].mode_two = 2296;
    startup_actor_tile_rows[63].mode_three = 2296;
    startup_actor_tile_rows[63].mode_four = 2296;
    startup_actor_waypoints[63].first = 5;
    startup_actor_destinations[63].parameter_one = 0x3980L;
    actor_board[64] = 4;
    startup_actor_tile_rows[64].base = 2406;
    startup_actor_tile_rows[64].mode_one = 2406;
    startup_actor_tile_rows[64].mode_five = 2406;
    actor_enabled[64] = 0;
    startup_saved_actor_positions[64].x = -0x2c00L;
    startup_saved_actor_positions[64].y = 0x100L;
    actor_sequence_initial[64] = 16;
    startup_actor_waypoints[64].first = 13;
    actor_health[64] = 1000;
    actor_projectile_type[64] = 2;
    actor_board[65] = 4;
    startup_actor_tile_rows[64].mode_two = 2296;
    startup_actor_tile_rows[64].mode_three = 2296;
    startup_actor_tile_rows[64].mode_four = 2296;
    startup_saved_actor_positions[65].z = 0x1c00L;
    startup_actor_tile_rows[65].mode_two = 2296;
    actor_profile[64] = 1;
    actor_mode[64] = 3;
    actor_sequence_initial[65] = 16;
    actor_projectile_type[65] = 2;
    actor_profile[65] = 1;
    actor_enabled[65] = 0;
    actor_health[65] = 1000;
    actor_mode[65] = 3;
    startup_saved_actor_positions[65].x = -0x1900L;
    startup_actor_tile_rows[65].base = 2406;
    startup_actor_tile_rows[65].mode_one = 2406;
    startup_actor_tile_rows[65].mode_three = 2296;
    startup_actor_tile_rows[65].mode_four = 2296;
    startup_actor_tile_rows[65].mode_five = 2406;
    startup_actor_destinations[65].x = 0;
    startup_actor_destinations[65].y = 0;
    startup_actor_destinations[65].parameter_one = 0;
    startup_actor_destinations[65].parameter_two = 0;
    actor_board[66] = 4;
    startup_saved_actor_positions[66].x = -0x2200L;
    startup_saved_actor_positions[66].y = 0x1280L;
    actor_z_offset[66] = 0;
    startup_actor_waypoints[65].first = 18;
    startup_saved_actor_positions[66].z = 0x1c00L;
    actor_mode[66] = 3;
    actor_sequence_initial[66] = 16;
    saved_actor_lotag[66] = 0x565;
    startup_actor_tile_rows[66].base = 2406;
    startup_actor_tile_rows[66].mode_one = 2406;
    startup_actor_tile_rows[66].mode_five = 2406;
    startup_actor_tile_rows[66].mode_two = 2296;
    startup_actor_tile_rows[66].mode_three = 2296;
    startup_actor_tile_rows[66].mode_four = 2296;
    startup_saved_actor_positions[67].y = 0x1980L;
    startup_actor_destinations[67].y = 0x1980L;
    actor_enabled[66] = 0;
    actor_health[66] = 1000;
    startup_actor_waypoints[66].first = 23;
    actor_health[67] = 1000;
    startup_actor_tile_rows[67].mode_two = 2296;
    startup_actor_tile_rows[67].mode_three = 2296;
    startup_actor_tile_rows[67].mode_four = 2296;
    actor_projectile_type[66] = 2;
    startup_actor_destinations[66].x = 0;
    startup_actor_destinations[66].y = 0;
    startup_actor_destinations[66].parameter_one = 0;
    startup_actor_destinations[66].parameter_two = 0;
    startup_saved_actor_positions[68].y = 0x1d80L;
    actor_board[67] = 4;
    startup_saved_actor_positions[67].x = -0x4e00L;
    actor_projectile_type[67] = 2;
    startup_actor_destinations[67].x = -0x4e00L;
    startup_actor_destinations[67].parameter_two = 0xe80L;
    actor_profile[66] = 1;
    actor_enabled[67] = 0;
    actor_sequence_initial[67] = 16;
    actor_profile[67] = 1;
    actor_mode[67] = 4;
    startup_saved_actor_positions[68].x = 0x200L;
    actor_z_offset[67] = 0;
    saved_actor_lotag[67] = 0x1465;
    startup_actor_tile_rows[67].base = 2406;
    startup_actor_tile_rows[67].mode_one = 2406;
    startup_actor_tile_rows[67].mode_five = 2406;
    startup_actor_destinations[67].parameter_one = -0x3580L;
    actor_enabled[68] = 0;
    actor_board[68] = 4;
    startup_actor_waypoints[67].first = 0;
    actor_health[68] = 1000;
    actor_z_offset[68] = 0;
    actor_sequence_initial[68] = 16;
    actor_projectile_type[68] = 2;
    actor_mode[68] = 4;
    startup_actor_destinations[68].y = 0x1d80L;
    saved_actor_lotag[68] = 0x1565;
    actor_profile[68] = 1;
    startup_actor_tile_rows[68].base = 2406;
    startup_actor_tile_rows[68].mode_one = 2406;
    startup_actor_tile_rows[68].mode_five = 2406;
    startup_actor_destinations[68].parameter_one = -0x780L;
    actor_board[69] = 4;
    actor_projectile_type[69] = 2;
    actor_profile[69] = 1;
    startup_actor_tile_rows[68].mode_two = 2296;
    startup_actor_tile_rows[68].mode_three = 2296;
    startup_actor_tile_rows[68].mode_four = 2296;
    startup_saved_actor_positions[69].y = 0x2200L;
    startup_actor_waypoints[68].first = 0;
    startup_actor_destinations[68].parameter_two = 0x1000L;
    actor_enabled[69] = 0;
    startup_saved_actor_positions[69].z = 0x1c00L;
    actor_mode[69] = 3;
    actor_enabled[70] = 0;
    startup_actor_destinations[68].x = 0x200L;
    startup_saved_actor_positions[70].x = 0x2e80L;
    startup_saved_actor_positions[69].x = -0x1200L;
    actor_sequence_initial[69] = 16;
    startup_actor_tile_rows[69].base = 2406;
    startup_actor_tile_rows[69].mode_one = 2406;
    startup_actor_tile_rows[69].mode_two = 2296;
    startup_actor_tile_rows[69].mode_three = 2296;
    startup_actor_tile_rows[69].mode_four = 2296;
    startup_actor_tile_rows[69].mode_five = 2406;
    actor_board[70] = 4;
    actor_z_offset[69] = 0;
    actor_health[69] = 1000;
    startup_actor_waypoints[69].first = 26;
    actor_sequence_initial[70] = 16;
    saved_actor_lotag[70] = 0x1865;
    startup_actor_tile_rows[70].base = 2406;
    startup_actor_tile_rows[70].mode_one = 2406;
    startup_actor_tile_rows[70].mode_five = 2406;
    saved_actor_lotag[69] = 0x1265;
    startup_actor_destinations[69].x = 0;
    startup_actor_destinations[69].y = 0;
    startup_actor_destinations[69].parameter_one = 0;
    startup_actor_destinations[69].parameter_two = 0;
    startup_saved_actor_positions[70].y = 0x2800L;
    actor_z_offset[70] = 0;
    actor_health[70] = 1000;
    startup_actor_waypoints[70].first = 0;
    startup_actor_destinations[70].y = 0;
    startup_saved_actor_positions[70].z = -0x1800L;
    actor_projectile_type[70] = 2;
    startup_actor_destinations[70].x = 0;
    startup_actor_destinations[70].parameter_one = 0;
    startup_actor_destinations[70].parameter_two = 0;
    startup_actor_tile_rows[70].mode_two = 2296;
    startup_actor_tile_rows[70].mode_three = 2296;
    startup_actor_tile_rows[70].mode_four = 2296;
    actor_profile[70] = 1;
    actor_mode[70] = 2;
    actor_enabled[71] = 0;
    startup_saved_actor_positions[71].x = 0x2e80L;
    actor_z_offset[71] = 0;
    startup_actor_waypoints[71].first = 0;
    actor_board[71] = 4;
    startup_saved_actor_positions[71].y = 0x2a00L;
    actor_health[71] = 1000;
    startup_actor_tile_rows[71].mode_two = 2296;
    startup_actor_tile_rows[71].mode_three = 2296;
    startup_actor_tile_rows[71].mode_four = 2296;
    actor_projectile_type[71] = 2;
    startup_actor_tile_rows[72].base = 2406;
    startup_actor_tile_rows[72].mode_one = 2406;
    startup_actor_tile_rows[72].mode_five = 2406;
    startup_actor_destinations[72].x = 0;
    startup_actor_destinations[72].y = 0;
    startup_actor_destinations[72].parameter_one = 0;
    startup_actor_destinations[72].parameter_two = 0;
    actor_z_offset[73] = 0;
    startup_saved_actor_positions[71].z = -0x1800L;
    saved_actor_lotag[71] = 0x1665;
    startup_actor_destinations[71].x = 0;
    startup_actor_destinations[71].y = 0;
    startup_actor_destinations[71].parameter_one = 0;
    startup_actor_destinations[71].parameter_two = 0;
    actor_enabled[72] = 0;
    actor_z_offset[72] = 0;
    actor_profile[71] = 1;
    actor_mode[71] = 2;
    startup_actor_waypoints[72].first = 0;
    actor_sequence_initial[71] = 16;
    actor_board[72] = 4;
    saved_actor_lotag[72] = 0x1765;
    actor_board[73] = 4;
    startup_saved_actor_positions[72].z = -0x1000L;
    startup_actor_tile_rows[71].base = 2406;
    startup_actor_tile_rows[71].mode_one = 2406;
    startup_actor_tile_rows[71].mode_five = 2406;
    startup_saved_actor_positions[72].x = 0x2e80L;
    startup_saved_actor_positions[73].z = -0x1000L;
    actor_sequence_initial[73] = 16;
    actor_health[72] = 1000;
    startup_saved_actor_positions[72].y = 0x600L;
    actor_sequence_initial[72] = 16;
    actor_health[73] = 1000;
    startup_actor_tile_rows[73].mode_two = 2296;
    startup_actor_tile_rows[73].mode_three = 2296;
    startup_actor_tile_rows[73].mode_four = 2296;
    actor_projectile_type[72] = 2;
    startup_actor_tile_rows[72].mode_two = 2296;
    startup_actor_tile_rows[72].mode_three = 2296;
    startup_actor_tile_rows[72].mode_four = 2296;
    actor_profile[72] = 1;
    actor_mode[72] = 2;
    actor_enabled[73] = 0;
    actor_projectile_type[73] = 2;
    startup_saved_actor_positions[73].x = 0x2e80L;
    startup_saved_actor_positions[73].y = 0x800L;
    saved_actor_lotag[73] = 0x1765;
    actor_mode[73] = 2;
    actor_profile[73] = 1;
    startup_actor_tile_rows[73].base = 2406;
    startup_actor_tile_rows[73].mode_one = 2406;
    startup_actor_tile_rows[73].mode_five = 2406;
    startup_actor_waypoints[73].first = 0;
    startup_actor_destinations[73].x = 0;
    actor_z_offset[74] = 0;
    actor_profile[74] = 1;
    startup_actor_destinations[73].y = 0;
    startup_actor_destinations[73].parameter_one = 0;
    startup_actor_destinations[73].parameter_two = 0;
    actor_board[74] = 4;
    startup_saved_actor_positions[74].y = -0x900L;
    actor_enabled[74] = 0;
    startup_saved_actor_positions[74].z = 0x1c48L;
    actor_mode[74] = 5;
    startup_saved_actor_positions[75].z = 0x2c00L;
    startup_saved_actor_positions[74].x = -0x2000L;
    actor_projectile_type[74] = 2;
    saved_actor_lotag[74] = 0x565;
    startup_actor_tile_rows[74].base = 2406;
    startup_actor_tile_rows[74].mode_one = 2406;
    startup_actor_tile_rows[74].mode_two = 2296;
    startup_actor_tile_rows[74].mode_three = 2296;
    startup_actor_tile_rows[74].mode_four = 2296;
    startup_actor_tile_rows[74].mode_five = 2406;
    startup_actor_destinations[74].parameter_one = 0x1380L;
    startup_saved_actor_positions[81].y = 0xb80L;
    actor_sequence_initial[74] = 16;
    startup_actor_destinations[74].x = -0x2000L;
    startup_saved_actor_positions[75].x = -0x1b80L;
    startup_actor_waypoints[74].first = 0;
    startup_actor_destinations[74].y = -0x900L;
    startup_actor_destinations[74].parameter_two = -0x900L;
    actor_board[75] = 4;
    actor_health[74] = 1000;
    actor_z_offset[75] = 0;
    actor_health[75] = 1000;
    startup_actor_tile_rows[75].mode_two = 2296;
    startup_actor_tile_rows[75].mode_three = 2296;
    startup_actor_tile_rows[75].mode_four = 2296;
    actor_enabled[75] = 0;
    startup_saved_actor_positions[75].y = -0x2200L;
    actor_sequence_initial[75] = 16;
    actor_projectile_type[75] = 2;
    actor_mode[75] = 3;
    saved_actor_lotag[81] = 0x500;
    saved_actor_lotag[75] = 0x565;
    startup_actor_tile_rows[75].base = 2406;
    startup_actor_tile_rows[75].mode_one = 2406;
    startup_actor_tile_rows[75].mode_five = 2406;
    startup_saved_actor_positions[81].x = -0xb000L;
    actor_profile[75] = 1;
    actor_enabled[81] = 0;
    actor_mode[81] = 0;
    startup_actor_waypoints[75].first = 8;
    startup_actor_destinations[75].x = 0;
    startup_actor_destinations[75].y = 0;
    startup_actor_destinations[75].parameter_one = 0;
    startup_actor_destinations[75].parameter_two = 0;
    startup_actor_tile_rows[81].base = 2296;
    actor_health[81] = 1000;
    actor_board[81] = 5;
    actor_z_offset[81] = 0;
    actor_projectile_type[81] = 2;
    actor_sequence_initial[81] = 16;
    actor_profile[81] = 1;
    startup_actor_tile_rows[81].mode_two = 2296;
    startup_actor_tile_rows[81].mode_three = 2296;
    startup_actor_tile_rows[81].mode_four = 2296;
    startup_actor_tile_rows[81].mode_one = 2406;
    startup_actor_tile_rows[81].mode_five = 2406;
    startup_actor_destinations[81].x = 0;
    startup_actor_destinations[81].y = 0;
    startup_actor_destinations[81].parameter_one = 0;
    startup_actor_destinations[81].parameter_two = 0;
    startup_saved_actor_positions[82].y = 0x1100L;
    actor_z_offset[82] = 0;
    startup_actor_waypoints[81].first = 0;
    actor_enabled[82] = 0;
    actor_board[82] = 5;
    actor_projectile_type[82] = 2;
    actor_mode[82] = 0;
    startup_saved_actor_positions[83].y = 0x1700L;
    saved_actor_lotag[83] = 0x500;
    startup_saved_actor_positions[82].x = -0xb300L;
    actor_sequence_initial[82] = 16;
    saved_actor_lotag[82] = 0x1700;
    startup_actor_tile_rows[82].base = 2296;
    startup_actor_tile_rows[82].mode_one = 2406;
    startup_actor_tile_rows[82].mode_two = 2296;
    startup_actor_tile_rows[82].mode_three = 2296;
    startup_actor_tile_rows[82].mode_four = 2296;
    startup_actor_tile_rows[82].mode_five = 2406;
    startup_actor_destinations[83].parameter_two = 0;
    startup_saved_actor_positions[84].y = 0x1d00L;
    startup_saved_actor_positions[83].x = -0xb280L;
    actor_health[82] = 1000;
    actor_profile[82] = 1;
    startup_actor_waypoints[82].first = 0;
    actor_board[83] = 5;
    actor_health[83] = 1000;
    startup_actor_tile_rows[83].base = 2296;
    startup_actor_tile_rows[83].mode_two = 2296;
    startup_actor_tile_rows[83].mode_three = 2296;
    startup_actor_tile_rows[83].mode_four = 2296;
    startup_actor_destinations[82].x = 0;
    startup_actor_destinations[82].y = 0;
    startup_actor_destinations[82].parameter_one = 0;
    startup_actor_destinations[82].parameter_two = 0;
    actor_z_offset[83] = 0;
    actor_sequence_initial[83] = 16;
    actor_projectile_type[83] = 2;
    actor_enabled[83] = 0;
    startup_actor_waypoints[83].first = 0;
    actor_profile[83] = 1;
    actor_mode[83] = 0;
    startup_actor_destinations[83].parameter_one = 0;
    actor_z_offset[84] = 0;
    startup_actor_destinations[83].y = 0;
    startup_saved_actor_positions[84].x = -0xb000L;
    startup_actor_tile_rows[83].mode_one = 2406;
    startup_actor_tile_rows[83].mode_five = 2406;
    startup_actor_destinations[83].x = 0;
    actor_board[84] = 5;
    actor_enabled[84] = 0;
    actor_sequence_initial[84] = 16;
    actor_health[84] = 1000;
    actor_projectile_type[84] = 2;
    saved_actor_lotag[84] = 0x1700;
    startup_actor_tile_rows[84].base = 2296;
    startup_actor_tile_rows[84].mode_two = 2296;
    startup_actor_tile_rows[84].mode_three = 2296;
    startup_actor_tile_rows[84].mode_four = 2296;
    startup_saved_actor_positions[85].x = -0x7f00L;
    startup_saved_actor_positions[85].y = 0x2100L;
    saved_actor_lotag[85] = 0x1765;
    startup_actor_destinations[85].y = 0x2100L;
    actor_profile[84] = 1;
    actor_mode[84] = 0;
    startup_actor_waypoints[84].first = 0;
    startup_actor_destinations[84].x = 0;
    startup_actor_destinations[84].y = 0;
    startup_actor_destinations[84].parameter_one = 0;
    startup_actor_destinations[84].parameter_two = 0;
    startup_actor_tile_rows[85].base = 2406;
    startup_actor_tile_rows[85].mode_one = 2406;
    startup_actor_tile_rows[85].mode_five = 2406;
    startup_actor_destinations[85].parameter_two = 0x680L;
    startup_saved_actor_positions[86].y = 0x2e00L;
    startup_actor_tile_rows[84].mode_one = 2406;
    startup_actor_tile_rows[84].mode_five = 2406;
    actor_enabled[85] = 0;
    actor_board[85] = 5;
    actor_z_offset[85] = 0;
    startup_actor_waypoints[85].first = 0;
    startup_actor_tile_rows[86].mode_two = 2296;
    startup_actor_tile_rows[86].mode_three = 2296;
    startup_actor_tile_rows[86].mode_four = 2296;
    actor_sequence_initial[85] = 16;
    actor_health[85] = 1000;
    actor_projectile_type[85] = 2;
    actor_board[86] = 5;
    startup_saved_actor_positions[86].x = -0x7000L;
    actor_profile[85] = 1;
    actor_mode[85] = 4;
    startup_actor_tile_rows[85].mode_two = 2296;
    startup_actor_tile_rows[85].mode_three = 2296;
    startup_actor_tile_rows[85].mode_four = 2296;
    actor_z_offset[86] = 0;
    actor_projectile_type[86] = 2;
    actor_profile[86] = 1;
    startup_actor_destinations[85].x = -0x7f00L;
    startup_actor_destinations[85].parameter_one = -0x7f00L;
    actor_sequence_initial[86] = 16;
    actor_mode[86] = 3;
    actor_enabled[86] = 0;
    actor_health[86] = 1000;
    startup_actor_tile_rows[86].base = 2406;
    startup_actor_tile_rows[86].mode_one = 2406;
    startup_actor_tile_rows[86].mode_five = 2406;
    saved_actor_lotag[86] = 0x565;
    startup_actor_waypoints[86].first = 62;
    startup_actor_destinations[86].x = 0;
    startup_actor_destinations[86].y = 0;
    startup_actor_destinations[86].parameter_one = 0;
    startup_actor_destinations[86].parameter_two = 0;
    actor_enabled[87] = 0;
    actor_z_offset[87] = 0;
    actor_health[87] = 1000;
    actor_board[87] = 5;
    startup_saved_actor_positions[87].x = -0x6100L;
    startup_saved_actor_positions[87].y = 0x2280L;
    saved_actor_lotag[87] = 0x565;
    actor_board[88] = 5;
    actor_mode[87] = 3;
    actor_sequence_initial[87] = 16;
    startup_actor_tile_rows[87].base = 2406;
    startup_actor_tile_rows[87].mode_one = 2406;
    startup_actor_tile_rows[87].mode_five = 2406;
    startup_saved_actor_positions[88].y = 0x3400L;
    actor_sequence_initial[88] = 16;
    startup_actor_tile_rows[88].mode_two = 2296;
    startup_actor_tile_rows[88].mode_three = 2296;
    startup_actor_tile_rows[88].mode_four = 2296;
    startup_actor_tile_rows[87].mode_two = 2296;
    startup_actor_tile_rows[87].mode_three = 2296;
    startup_actor_tile_rows[87].mode_four = 2296;
    startup_actor_waypoints[87].first = 67;
    startup_actor_tile_rows[88].base = 2406;
    startup_actor_tile_rows[88].mode_one = 2406;
    startup_actor_tile_rows[88].mode_five = 2406;
    startup_saved_actor_positions[89].y = 0x2b00L;
    saved_actor_lotag[89] = 0x565;
    startup_actor_destinations[89].y = 0x2b00L;
    actor_projectile_type[87] = 2;
    startup_actor_destinations[87].x = 0;
    startup_actor_destinations[87].y = 0;
    startup_actor_destinations[87].parameter_one = 0;
    startup_actor_destinations[87].parameter_two = 0;
    startup_saved_actor_positions[88].x = -0x6480L;
    startup_actor_waypoints[88].first = 70;
    actor_profile[87] = 1;
    actor_enabled[88] = 0;
    startup_saved_actor_positions[89].x = -0x5380L;
    actor_z_offset[89] = 0;
    actor_z_offset[88] = 0;
    saved_actor_lotag[88] = 0x1765;
    actor_projectile_type[89] = 2;
    startup_actor_tile_rows[89].base = 2406;
    startup_actor_tile_rows[89].mode_one = 2406;
    startup_actor_tile_rows[89].mode_five = 2406;
    actor_health[88] = 1000;
    startup_actor_destinations[88].x = 0;
    startup_actor_destinations[88].y = 0;
    startup_actor_destinations[88].parameter_one = 0;
    startup_actor_destinations[88].parameter_two = 0;
    actor_projectile_type[88] = 2;
    actor_profile[89] = 1;
    startup_actor_waypoints[89].first = 0;
    actor_mode[88] = 3;
    actor_board[89] = 5;
    actor_profile[88] = 1;
    actor_enabled[89] = 0;
    actor_sequence_initial[89] = 16;
    actor_health[89] = 1000;
    startup_actor_tile_rows[89].mode_two = 2296;
    startup_actor_tile_rows[89].mode_three = 2296;
    startup_actor_tile_rows[89].mode_four = 2296;
    actor_mode[89] = 4;
    startup_actor_destinations[89].x = -0x5380L;
    startup_actor_destinations[89].parameter_two = 0x2b00L;
    actor_projectile_type[90] = 2;
    actor_profile[90] = 1;
    startup_actor_destinations[89].parameter_one = -0x6a80L;
    actor_board[90] = 5;
    startup_saved_actor_positions[90].x = -0x3980L;
    saved_actor_lotag[90] = 0x1665;
    startup_actor_tile_rows[90].mode_two = 2296;
    startup_actor_tile_rows[90].mode_three = 2296;
    startup_actor_tile_rows[90].mode_four = 2296;
    startup_actor_destinations[90].x = -0x3980L;
    startup_saved_actor_positions[90].y = 0x4a80L;
    actor_mode[90] = 5;
    startup_actor_destinations[90].y = 0x4a80L;
    actor_enabled[90] = 0;
    actor_z_offset[90] = 0;
    startup_actor_destinations[90].parameter_two = 0x2980L;
    startup_saved_actor_positions[91].x = -0x3300L;
    actor_mode[91] = 4;
    startup_actor_tile_rows[90].base = 2406;
    startup_actor_tile_rows[90].mode_one = 2406;
    startup_actor_tile_rows[90].mode_five = 2406;
    startup_saved_actor_positions[91].y = 0x2880L;
    startup_actor_destinations[91].y = 0x2880L;
    actor_sequence_initial[90] = 16;
    startup_actor_destinations[90].parameter_one = -0x5000L;
    saved_actor_lotag[91] = 0x1a65;
    startup_actor_tile_rows[91].base = 2672;
    startup_actor_tile_rows[91].mode_one = 2672;
    startup_actor_tile_rows[91].mode_two = 2672;
    startup_actor_tile_rows[91].mode_three = 2672;
    startup_actor_tile_rows[91].mode_four = 2672;
    startup_actor_tile_rows[91].mode_five = 2672;
    startup_actor_tile_rows[91].mode_six = 2672;
    startup_actor_destinations[91].x = -0x3300L;
    startup_actor_waypoints[90].first = 0;
    startup_saved_actor_positions[92].y = 0x2780L;
    actor_health[90] = 1000;
    actor_board[91] = 5;
    startup_actor_destinations[91].parameter_two = 0x2b00L;
    actor_health[92] = 4000;
    actor_enabled[91] = 2;
    actor_enabled[92] = 2;
    actor_z_offset[91] = 0;
    actor_sequence_initial[91] = 16;
    actor_board[92] = 5;
    actor_health[91] = 4000;
    actor_projectile_type[91] = 0;
    actor_sequence_initial[92] = 16;
    actor_profile[91] = 1;
    startup_actor_destinations[91].parameter_one = -0x5080L;
    saved_actor_lotag[92] = 0x1a65;
    actor_projectile_type[92] = 0;
    startup_actor_waypoints[91].first = 0;
    startup_saved_actor_positions[92].x = -0x1f80L;
    actor_profile[92] = 1;
    actor_z_offset[92] = 0;
    startup_actor_tile_rows[92].base = 2672;
    startup_actor_tile_rows[92].mode_one = 2672;
    startup_actor_tile_rows[92].mode_two = 2672;
    startup_actor_tile_rows[92].mode_three = 2672;
    startup_actor_tile_rows[92].mode_four = 2672;
    actor_mode[92] = 4;
    startup_actor_tile_rows[92].mode_five = 2672;
    startup_actor_tile_rows[92].mode_six = 2672;
    startup_actor_destinations[92].x = -0x1f80L;
    startup_actor_destinations[92].y = 0x2780L;
    startup_actor_waypoints[92].first = 0;
    actor_enabled[93] = 0;
    actor_board[93] = 5;
    actor_projectile_type[93] = 2;
    startup_actor_destinations[92].parameter_one = -0x2e80L;
    startup_saved_actor_positions[93].x = -0x1b00L;
    startup_saved_actor_positions[93].y = 0x3380L;
    startup_actor_destinations[93].y = 0x3380L;
    startup_actor_destinations[93].parameter_two = 0x3380L;
    startup_actor_destinations[92].parameter_two = 0x4000L;
    actor_z_offset[93] = 0;
    actor_sequence_initial[93] = 16;
    actor_profile[93] = 1;
    actor_health[93] = 1000;
    actor_mode[93] = 4;
    startup_saved_actor_positions[94].y = 0x800L;
    startup_actor_destinations[94].y = 0x800L;
    startup_actor_destinations[94].parameter_two = 0x800L;
    startup_saved_actor_positions[95].y = 0x800L;
    saved_actor_lotag[93] = 0x1665;
    startup_actor_tile_rows[93].base = 2406;
    startup_actor_tile_rows[93].mode_one = 2406;
    startup_actor_tile_rows[93].mode_five = 2406;
    actor_health[94] = 1000;
    startup_actor_tile_rows[94].base = 2406;
    startup_actor_tile_rows[94].mode_one = 2406;
    startup_actor_tile_rows[94].mode_five = 2406;
    startup_actor_tile_rows[93].mode_two = 2296;
    startup_actor_tile_rows[93].mode_three = 2296;
    startup_actor_tile_rows[93].mode_four = 2296;
    startup_saved_actor_positions[94].x = -0x4800L;
    startup_actor_destinations[94].x = -0x4800L;
    startup_actor_waypoints[93].first = 0;
    actor_board[94] = 5;
    actor_mode[94] = 4;
    startup_actor_waypoints[94].first = 0;
    startup_actor_destinations[93].parameter_one = -0x4b00L;
    startup_saved_actor_positions[95].x = -0x3580L;
    startup_actor_destinations[93].x = -0x1830L;
    actor_z_offset[94] = 0;
    actor_enabled[95] = 0;
    actor_enabled[94] = 0;
    actor_health[95] = 1000;
    actor_sequence_initial[94] = 16;
    actor_projectile_type[94] = 2;
    saved_actor_lotag[94] = 0x1865;
    actor_profile[94] = 1;
    startup_actor_tile_rows[94].mode_two = 2296;
    startup_actor_tile_rows[94].mode_three = 2296;
    startup_actor_tile_rows[94].mode_four = 2296;
    actor_projectile_type[95] = 2;
    actor_profile[95] = 1;
    startup_actor_destinations[94].parameter_one = 0x980L;
    actor_z_offset[95] = 0;
    actor_mode[95] = 3;
    actor_board[95] = 5;
    saved_actor_lotag[95] = 0x565;
    startup_actor_tile_rows[95].base = 2406;
    actor_sequence_initial[95] = 16;
    startup_actor_tile_rows[95].mode_one = 2406;
    startup_actor_tile_rows[95].mode_five = 2406;
    startup_saved_actor_positions[96].y = 0x800L;
    startup_actor_destinations[96].y = 0x800L;
    startup_actor_destinations[96].parameter_two = 0x800L;
    startup_actor_tile_rows[95].mode_two = 2296;
    startup_actor_tile_rows[95].mode_three = 2296;
    startup_actor_tile_rows[95].mode_four = 2296;
    actor_board[96] = 5;
    startup_saved_actor_positions[96].x = -0x500L;
    actor_z_offset[96] = 0;
    startup_actor_tile_rows[96].base = 2672;
    startup_actor_tile_rows[96].mode_one = 2672;
    startup_actor_tile_rows[96].mode_two = 2672;
    startup_actor_tile_rows[96].mode_three = 2672;
    startup_actor_tile_rows[96].mode_four = 2672;
    startup_actor_tile_rows[96].mode_five = 2672;
    startup_actor_tile_rows[96].mode_six = 2672;
    startup_actor_waypoints[95].first = 73;
    startup_saved_actor_positions[97].y = -0x1980L;
    startup_saved_actor_positions[98].y = -0x1980L;
    actor_sequence_initial[96] = 16;
    actor_mode[96] = 4;
    startup_actor_destinations[95].x = 0;
    startup_actor_destinations[95].y = 0;
    startup_actor_destinations[95].parameter_one = 0;
    startup_actor_destinations[95].parameter_two = 0;
    startup_actor_waypoints[96].first = 0;
    actor_health[96] = 4000;
    actor_enabled[97] = 0;
    startup_actor_tile_rows[97].mode_two = 2296;
    startup_actor_tile_rows[97].mode_three = 2296;
    startup_actor_tile_rows[97].mode_four = 2296;
    actor_enabled[96] = 2;
    startup_saved_actor_positions[97].x = -0x2680L;
    actor_projectile_type[96] = 0;
    actor_z_offset[97] = 0;
    actor_projectile_type[97] = 2;
    startup_actor_destinations[96].x = -0x500L;
    startup_saved_actor_positions[98].x = -0x1500L;
    saved_actor_lotag[96] = 0x1a65;
    actor_health[97] = 1000;
    actor_profile[97] = 1;
    actor_board[97] = 5;
    actor_profile[96] = 1;
    startup_actor_tile_rows[97].base = 2406;
    startup_actor_tile_rows[97].mode_one = 2406;
    startup_actor_tile_rows[97].mode_five = 2406;
    actor_board[98] = 5;
    actor_sequence_initial[97] = 16;
    startup_actor_destinations[96].parameter_one = -0x5200L;
    startup_actor_waypoints[97].first = 76;
    saved_actor_lotag[97] = 0x1665;
    actor_mode[97] = 3;
    startup_actor_destinations[97].x = 0;
    startup_actor_destinations[97].y = 0;
    startup_actor_destinations[97].parameter_one = 0;
    startup_actor_destinations[97].parameter_two = 0;
    actor_z_offset[98] = 0;
    actor_enabled[98] = 0;
    actor_sequence_initial[98] = 16;
    actor_health[98] = 1000;
    actor_projectile_type[98] = 2;
    saved_actor_lotag[98] = 0x565;
    actor_mode[98] = 3;
    startup_actor_tile_rows[98].base = 2406;
    startup_actor_tile_rows[98].mode_one = 2406;
    startup_actor_tile_rows[98].mode_five = 2406;
    actor_board[99] = 5;
    startup_saved_actor_positions[99].y = -0x1b80L;
    actor_sequence_initial[99] = 16;
    actor_health[99] = 1000;
    startup_actor_destinations[99].y = -0x1b80L;
    actor_profile[98] = 1;
    startup_actor_waypoints[98].first = 80;
    actor_projectile_type[99] = 2;
    startup_actor_tile_rows[99].mode_two = 2296;
    startup_actor_tile_rows[99].mode_three = 2296;
    startup_actor_tile_rows[99].mode_four = 2296;
    startup_actor_destinations[99].parameter_one = -0x4b00L;
    startup_saved_actor_positions[100].y = -0x2c80L;
    startup_actor_destinations[100].y = -0x2c80L;
    startup_actor_tile_rows[98].mode_two = 2296;
    startup_actor_tile_rows[98].mode_three = 2296;
    startup_actor_tile_rows[98].mode_four = 2296;
    startup_saved_actor_positions[99].x = -0x3600L;
    actor_profile[99] = 1;
    startup_actor_destinations[99].x = -0x3600L;
    startup_actor_destinations[99].parameter_two = -0x3280L;
    startup_saved_actor_positions[100].x = -0x3600L;
    actor_health[100] = 1000;
    startup_actor_destinations[98].x = 0;
    startup_actor_destinations[98].y = 0;
    startup_actor_destinations[98].parameter_one = 0;
    startup_actor_destinations[98].parameter_two = 0;
    actor_z_offset[99] = 0;
    actor_z_offset[100] = 0;
    actor_projectile_type[100] = 2;
    saved_actor_lotag[100] = 0x1865;
    startup_actor_tile_rows[100].base = 2406;
    startup_actor_tile_rows[100].mode_one = 2406;
    startup_actor_tile_rows[100].mode_five = 2406;
    actor_enabled[99] = 0;
    saved_actor_lotag[99] = 0x1565;
    actor_profile[100] = 1;
    startup_actor_waypoints[100].first = 0;
    startup_actor_destinations[100].parameter_two = -0x1580L;
    actor_enabled[101] = 0;
    startup_actor_tile_rows[99].base = 2406;
    startup_actor_tile_rows[99].mode_one = 2406;
    startup_actor_tile_rows[99].mode_five = 2406;
    actor_mode[99] = 4;
    startup_actor_destinations[100].parameter_one = -0x4f00L;
    startup_actor_waypoints[99].first = 0;
    actor_enabled[100] = 0;
    actor_mode[100] = 4;
    actor_board[100] = 5;
    startup_actor_tile_rows[100].mode_two = 2296;
    startup_actor_tile_rows[100].mode_three = 2296;
    startup_actor_tile_rows[100].mode_four = 2296;
    actor_sequence_initial[100] = 16;
    startup_actor_destinations[100].x = -0x3600L;
    actor_board[101] = 5;
    actor_sequence_initial[101] = 16;
    startup_saved_actor_positions[101].x = -0x1600L;
    startup_saved_actor_positions[101].y = -0x3400L;
    actor_z_offset[101] = 0;
    saved_actor_lotag[101] = 0x565;
    actor_mode[101] = 4;
    startup_actor_tile_rows[101].mode_two = 2296;
    startup_actor_tile_rows[101].mode_three = 2296;
    startup_actor_tile_rows[101].mode_four = 2296;
    startup_actor_destinations[101].x = -0x1600L;
    startup_actor_destinations[101].y = -0x3400L;
    startup_actor_destinations[101].parameter_two = -0x3400L;
    startup_saved_actor_positions[102].x = -0x1600L;
    actor_projectile_type[101] = 2;
    actor_health[101] = 1000;
    startup_actor_destinations[101].parameter_one = -0x2b80L;
    startup_saved_actor_positions[102].y = -0x3d80L;
    actor_projectile_type[102] = 2;
    saved_actor_lotag[102] = 0x565;
    startup_actor_tile_rows[102].base = 2406;
    startup_actor_tile_rows[102].mode_one = 2406;
    startup_actor_tile_rows[102].mode_five = 2406;
    startup_actor_destinations[102].y = -0x3d80L;
    startup_actor_destinations[102].parameter_two = -0x3d80L;
    actor_profile[101] = 1;
    actor_enabled[102] = 0;
    actor_board[102] = 5;
    actor_profile[102] = 1;
    startup_actor_waypoints[102].first = 0;
    startup_saved_actor_positions[103].y = -0x5380L;
    startup_actor_tile_rows[101].base = 2406;
    startup_actor_tile_rows[101].mode_one = 2406;
    startup_actor_tile_rows[101].mode_five = 2406;
    actor_z_offset[102] = 0;
    actor_health[102] = 1000;
    startup_actor_tile_rows[102].mode_two = 2296;
    startup_actor_tile_rows[102].mode_three = 2296;
    startup_actor_tile_rows[102].mode_four = 2296;
    startup_saved_actor_positions[103].x = 0x980L;
    startup_actor_waypoints[101].first = 0;
    actor_sequence_initial[102] = 16;
    startup_actor_destinations[102].x = -0x1600L;
    startup_actor_destinations[102].parameter_one = -0x2a80L;
    startup_actor_waypoints[103].first = 84;
    actor_mode[102] = 4;
    actor_board[103] = 5;
    actor_z_offset[103] = 0;
    actor_enabled[103] = 2;
    actor_sequence_initial[103] = 16;
    actor_health[103] = 4000;
    saved_actor_lotag[103] = 0x1a65;
    actor_projectile_type[103] = 0;
    startup_actor_tile_rows[103].base = 2672;
    startup_actor_tile_rows[103].mode_one = 2672;
    startup_actor_tile_rows[103].mode_two = 2672;
    startup_actor_tile_rows[103].mode_three = 2672;
    startup_actor_tile_rows[103].mode_four = 2672;
    startup_actor_tile_rows[103].mode_five = 2672;
    startup_actor_tile_rows[103].mode_six = 2672;
    actor_mode[103] = 3;
    actor_profile[103] = 1;
#ifdef ACTOR_DESTINATION_CONTEXT
    destination_zero = actor_destination_zero_in_ebx(0L);
    startup_actor_destinations[103].x = destination_zero;
#else
    startup_actor_destinations[103].x = 0;
#endif

    configured_slot = actor_slot_in_ax(103);
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = actor_destination_zero_in_ebx(destination_zero);
#else
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(104);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 5;
    startup_saved_actor_positions[configured_slot].x = 0x1b00L;
    startup_saved_actor_positions[configured_slot].y = -0x4280L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x1700;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 0;
    startup_actor_tile_rows[configured_slot].base = 2296;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_esi = actor_destination_value_in_esi(0);
    destination_at(destination_offset).x = destination_value_esi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0);
    destination_at(destination_offset).y = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_eax = actor_destination_value_in_eax(0);
    destination_at(destination_offset).parameter_two = destination_value_eax;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#endif
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(105);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 5;
    startup_saved_actor_positions[configured_slot].x = 0x1f40L;
    startup_saved_actor_positions[configured_slot].y = -0x4000L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x500;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 0;
    startup_actor_tile_rows[configured_slot].base = 2296;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0);
    destination_at(destination_offset).x = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
    destination_zero = actor_destination_zero_in_ebx(0L);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = actor_destination_zero_in_ebx(destination_zero);
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(106);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 5;
    startup_saved_actor_positions[configured_slot].x = 0x24c0L;
    startup_saved_actor_positions[configured_slot].y = -0x3f40L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x1700;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 0;
    startup_actor_tile_rows[configured_slot].base = 2296;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    destination_zero = actor_destination_zero_in_ebx(0L);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = actor_destination_zero_in_ebx(destination_zero);
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(107);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 5;
    startup_saved_actor_positions[configured_slot].x = 0x1ac0L;
    startup_saved_actor_positions[configured_slot].y = -0x30c0L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x500;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 0;
    startup_actor_tile_rows[configured_slot].base = 2296;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_esi = actor_destination_value_in_esi(0);
    destination_at(destination_offset).x = destination_value_esi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).y = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_one = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_two = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#endif
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(108);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 5;
    startup_saved_actor_positions[configured_slot].x = 0x1f80L;
    startup_saved_actor_positions[configured_slot].y = -0x3340L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x500;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 0;
    startup_actor_tile_rows[configured_slot].base = 2296;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0);
    destination_at(destination_offset).x = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_one = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_two = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#endif
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(109);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 5;
    startup_saved_actor_positions[configured_slot].x = 0x24c0L;
    startup_saved_actor_positions[configured_slot].y = -0x33c0L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x1700;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 0;
    startup_actor_tile_rows[configured_slot].base = 2296;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(110);
    actor_enabled[configured_slot] = 2;
    actor_board[configured_slot] = 5;
    startup_saved_actor_positions[configured_slot].x = 0x4700L;
    startup_saved_actor_positions[configured_slot].y = -0x63c0L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 4000;
    actor_projectile_type[configured_slot] = 0;
    saved_actor_lotag[configured_slot] = 0x1a65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 3;
    startup_actor_tile_rows[configured_slot].base = 2672;
    startup_actor_tile_rows[configured_slot].mode_one = 2672;
    startup_actor_tile_rows[configured_slot].mode_two = 2672;
    startup_actor_tile_rows[configured_slot].mode_three = 2672;
    startup_actor_tile_rows[configured_slot].mode_four = 2672;
    startup_actor_tile_rows[configured_slot].mode_five = 2672;
    startup_actor_tile_rows[configured_slot].mode_six = 2672;
    startup_actor_waypoints[configured_slot].first = 89;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_esi = actor_destination_value_in_esi(0);
    destination_at(destination_offset).x = destination_value_esi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).y = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_one = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_two = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#endif
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(111);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 5;
    startup_saved_actor_positions[configured_slot].x = 0x2c80L;
    startup_saved_actor_positions[configured_slot].y = -0x9b80L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x1265;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 3;
    startup_actor_tile_rows[configured_slot].base = 2406;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_waypoints[configured_slot].first = 95;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0);
    destination_at(destination_offset).x = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).y = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_one = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_two = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#endif
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(112);
    actor_enabled[configured_slot] = 2;
    actor_board[configured_slot] = 5;
    startup_saved_actor_positions[configured_slot].x = 0x6d80L;
    startup_saved_actor_positions[configured_slot].y = -0x4c00L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 4000;
    actor_projectile_type[configured_slot] = 0;
    saved_actor_lotag[configured_slot] = 0x1a65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 3;
    startup_actor_tile_rows[configured_slot].base = 2672;
    startup_actor_tile_rows[configured_slot].mode_one = 2672;
    startup_actor_tile_rows[configured_slot].mode_two = 2672;
    startup_actor_tile_rows[configured_slot].mode_three = 2672;
    startup_actor_tile_rows[configured_slot].mode_four = 2672;
    startup_actor_tile_rows[configured_slot].mode_five = 2672;
    startup_actor_tile_rows[configured_slot].mode_six = 2672;
    startup_actor_waypoints[configured_slot].first = 100;
#ifdef ACTOR_DESTINATION_CONTEXT
    destination_zero = actor_destination_zero_in_ebx(0L);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = actor_destination_zero_in_ebx(destination_zero);
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(113);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 6;
    startup_saved_actor_positions[configured_slot].x = -0xc00L;
    startup_saved_actor_positions[configured_slot].y = 0x3700L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x4665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 2;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_esi = actor_destination_value_in_esi(0);
    destination_at(destination_offset).x = destination_value_esi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).y = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_one = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_two = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#endif
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(114);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 6;
    startup_saved_actor_positions[configured_slot].x = -0x800L;
    startup_saved_actor_positions[configured_slot].y = 0x3700L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x865;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 2;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0);
    destination_at(destination_offset).x = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_one = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_two = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#endif
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(115);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 6;
    startup_saved_actor_positions[configured_slot].x = -0x500L;
    startup_saved_actor_positions[configured_slot].y = 0x3700L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x4665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 2;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(116);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 6;
    startup_saved_actor_positions[configured_slot].x = -0x1000L;
    startup_saved_actor_positions[configured_slot].y = -0xc00L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x4665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 5;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0x1000L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = -0xc00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0x1000L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = -0x1e00L;
#else
    startup_actor_destinations[configured_slot].x = -0x1000L;
    startup_actor_destinations[configured_slot].y = -0xc00L;
    startup_actor_destinations[configured_slot].parameter_one = -0x1000L;
    startup_actor_destinations[configured_slot].parameter_two = -0x1e00L;
#endif

    configured_slot = actor_slot_in_ax(117);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 6;
    startup_saved_actor_positions[configured_slot].x = 0xd00L;
    startup_saved_actor_positions[configured_slot].y = -0x1200L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x4665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 3;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 29;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_esi = actor_destination_value_in_esi(0);
    destination_at(destination_offset).x = destination_value_esi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).y = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_one = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_two = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#endif
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(118);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 6;
    startup_saved_actor_positions[configured_slot].x = 0x3700L;
    startup_saved_actor_positions[configured_slot].y = -0x2400L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x765;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 3;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 33;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(119);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 6;
    startup_saved_actor_positions[configured_slot].x = 0x2800L;
    startup_saved_actor_positions[configured_slot].y = 0xf00L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x4665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 3;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 36;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_esi = actor_destination_value_in_esi(0);
    destination_at(destination_offset).x = destination_value_esi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).y = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_one = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_two = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#endif
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(120);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 6;
    startup_saved_actor_positions[configured_slot].x = 0x1c80L;
    startup_saved_actor_positions[configured_slot].y = 0x3600L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x4665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 3;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 39;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0);
    destination_at(destination_offset).x = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).y = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_one = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_two = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#endif
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(121);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 6;
    startup_saved_actor_positions[configured_slot].x = -0x1080L;
    startup_saved_actor_positions[configured_slot].y = 0x4d00L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x4665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 3;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 43;
#ifdef ACTOR_DESTINATION_CONTEXT
    destination_zero = actor_destination_zero_in_ebx(0L);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = actor_destination_zero_in_ebx(destination_zero);
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(122);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 6;
    startup_saved_actor_positions[configured_slot].x = 0x2980L;
    startup_saved_actor_positions[configured_slot].y = 0x6a00L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x4665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 5;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0x2980L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0x6a00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0x4280L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0x6880L;
#else
    startup_actor_destinations[configured_slot].x = 0x2980L;
    startup_actor_destinations[configured_slot].y = 0x6a00L;
    startup_actor_destinations[configured_slot].parameter_one = 0x4280L;
    startup_actor_destinations[configured_slot].parameter_two = 0x6880L;
#endif

    configured_slot = actor_slot_in_ax(123);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 6;
    startup_saved_actor_positions[configured_slot].x = 0x1900L;
    startup_saved_actor_positions[configured_slot].y = 0x3b00L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x965;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0x1900L);
    destination_at(destination_offset).x = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0x1900L;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0x3b00L;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_one = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0x1900L;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = -0x100L;
#else
    startup_actor_destinations[configured_slot].x = 0x1900L;
    startup_actor_destinations[configured_slot].y = 0x3b00L;
    startup_actor_destinations[configured_slot].parameter_one = 0x1900L;
    startup_actor_destinations[configured_slot].parameter_two = -0x100L;
#endif

    configured_slot = actor_slot_in_ax(124);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 6;
    startup_saved_actor_positions[configured_slot].x = 0x2580L;
    startup_saved_actor_positions[configured_slot].y = -0x3400L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x4665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0x2580L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = -0x3400L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0x380L;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0x1a80L);
    destination_at(destination_offset).parameter_two = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0x1a80L;
#endif
#else
    startup_actor_destinations[configured_slot].x = 0x2580L;
    startup_actor_destinations[configured_slot].y = -0x3400L;
    startup_actor_destinations[configured_slot].parameter_one = -0x380L;
    startup_actor_destinations[configured_slot].parameter_two = 0x1a80L;
#endif

    configured_slot = actor_slot_in_ax(125);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 6;
    startup_saved_actor_positions[configured_slot].x = -0xf00L;
    startup_saved_actor_positions[configured_slot].y = -0xb80L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x3665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 5;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0xf00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = -0xb80L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0x200L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = -0x454L;
#else
    startup_actor_destinations[configured_slot].x = -0xf00L;
    startup_actor_destinations[configured_slot].y = -0xb80L;
    startup_actor_destinations[configured_slot].parameter_one = 0x200L;
    startup_actor_destinations[configured_slot].parameter_two = -0x454L;
#endif

    configured_slot = actor_slot_in_ax(126);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 6;
    startup_saved_actor_positions[configured_slot].x = 0x2180L;
    startup_saved_actor_positions[configured_slot].y = -0x2380L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x4665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0x2180L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = -0x2380L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0xf00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = -0x2380L;
#else
    startup_actor_destinations[configured_slot].x = 0x2180L;
    startup_actor_destinations[configured_slot].y = -0x2380L;
    startup_actor_destinations[configured_slot].parameter_one = 0xf00L;
    startup_actor_destinations[configured_slot].parameter_two = -0x2380L;
#endif

    configured_slot = actor_slot_in_ax(127);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 6;
    startup_saved_actor_positions[configured_slot].x = -0x1a00L;
    startup_saved_actor_positions[configured_slot].y = 0x1880L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x4665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0x1a00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0x1880L;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_esi = actor_destination_value_in_esi(-0x1400L);
    destination_at(destination_offset).parameter_one = destination_value_esi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0x1400L;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(-0x500L);
    destination_at(destination_offset).parameter_two = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = -0x500L;
#endif
#else
    startup_actor_destinations[configured_slot].x = -0x1a00L;
    startup_actor_destinations[configured_slot].y = 0x1880L;
    startup_actor_destinations[configured_slot].parameter_one = -0x1400L;
    startup_actor_destinations[configured_slot].parameter_two = -0x500L;
#endif

    configured_slot = actor_slot_in_ax(128);
    actor_enabled[configured_slot] = 5;
    actor_board[configured_slot] = 6;
    startup_saved_actor_positions[configured_slot].x = 0xc00L;
    startup_saved_actor_positions[configured_slot].y = 0x480L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 3;
    saved_actor_lotag[configured_slot] = 0x2e65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2562;
    startup_actor_tile_rows[configured_slot].mode_one = 2562;
    startup_actor_tile_rows[configured_slot].mode_two = 2562;
    startup_actor_tile_rows[configured_slot].mode_three = 2562;
    startup_actor_tile_rows[configured_slot].mode_four = 2562;
    startup_actor_tile_rows[configured_slot].mode_five = 2562;
    startup_actor_tile_rows[configured_slot].mode_six = 2562;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0xc00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0x480L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0x1a00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0x1680L;
#else
    startup_actor_destinations[configured_slot].x = 0xc00L;
    startup_actor_destinations[configured_slot].y = 0x480L;
    startup_actor_destinations[configured_slot].parameter_one = 0x1a00L;
    startup_actor_destinations[configured_slot].parameter_two = 0x1680L;
#endif

    configured_slot = actor_slot_in_ax(129);
    actor_enabled[configured_slot] = 5;
    actor_board[configured_slot] = 6;
    startup_saved_actor_positions[configured_slot].x = 0x1700L;
    startup_saved_actor_positions[configured_slot].y = 0x380L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 3;
    saved_actor_lotag[configured_slot] = 0x2e65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2562;
    startup_actor_tile_rows[configured_slot].mode_one = 2562;
    startup_actor_tile_rows[configured_slot].mode_two = 2562;
    startup_actor_tile_rows[configured_slot].mode_three = 2562;
    startup_actor_tile_rows[configured_slot].mode_four = 2562;
    startup_actor_tile_rows[configured_slot].mode_five = 2562;
    startup_actor_tile_rows[configured_slot].mode_six = 2562;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0x1700L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0x380L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0x800L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0x1880L;
#else
    startup_actor_destinations[configured_slot].x = 0x1700L;
    startup_actor_destinations[configured_slot].y = 0x380L;
    startup_actor_destinations[configured_slot].parameter_one = 0x800L;
    startup_actor_destinations[configured_slot].parameter_two = 0x1880L;
#endif

    configured_slot = actor_slot_in_ax(130);
    actor_enabled[configured_slot] = 5;
    actor_board[configured_slot] = 6;
    startup_saved_actor_positions[configured_slot].x = -0x2000L;
    startup_saved_actor_positions[configured_slot].y = 0x3a00L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 3;
    saved_actor_lotag[configured_slot] = 0x2e65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2562;
    startup_actor_tile_rows[configured_slot].mode_one = 2562;
    startup_actor_tile_rows[configured_slot].mode_two = 2562;
    startup_actor_tile_rows[configured_slot].mode_three = 2562;
    startup_actor_tile_rows[configured_slot].mode_four = 2562;
    startup_actor_tile_rows[configured_slot].mode_five = 2562;
    startup_actor_tile_rows[configured_slot].mode_six = 2562;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0x2000L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0x3a00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0x3000L;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(-0x100L);
    destination_at(destination_offset).parameter_two = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = -0x100L;
#endif
#else
    startup_actor_destinations[configured_slot].x = -0x2000L;
    startup_actor_destinations[configured_slot].y = 0x3a00L;
    startup_actor_destinations[configured_slot].parameter_one = -0x3000L;
    startup_actor_destinations[configured_slot].parameter_two = -0x100L;
#endif

    configured_slot = actor_slot_in_ax(131);
    actor_enabled[configured_slot] = 5;
    actor_board[configured_slot] = 6;
    startup_saved_actor_positions[configured_slot].x = 0x1100L;
    startup_saved_actor_positions[configured_slot].y = 0x4600L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 3;
    saved_actor_lotag[configured_slot] = 0x2e65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2562;
    startup_actor_tile_rows[configured_slot].mode_one = 2562;
    startup_actor_tile_rows[configured_slot].mode_two = 2562;
    startup_actor_tile_rows[configured_slot].mode_three = 2562;
    startup_actor_tile_rows[configured_slot].mode_four = 2562;
    startup_actor_tile_rows[configured_slot].mode_five = 2562;
    startup_actor_tile_rows[configured_slot].mode_six = 2562;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0x1100L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0x4600L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0x2e00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0x6c00L;
#else
    startup_actor_destinations[configured_slot].x = 0x1100L;
    startup_actor_destinations[configured_slot].y = 0x4600L;
    startup_actor_destinations[configured_slot].parameter_one = 0x2e00L;
    startup_actor_destinations[configured_slot].parameter_two = 0x6c00L;
#endif

    configured_slot = actor_slot_in_ax(146);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = -0x1d00L;
    startup_saved_actor_positions[configured_slot].y = 0xcb00L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x565;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2406;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0x1d00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0xcb00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0xc00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0xcb00L;
#else
    startup_actor_destinations[configured_slot].x = -0x1d00L;
    startup_actor_destinations[configured_slot].y = 0xcb00L;
    startup_actor_destinations[configured_slot].parameter_one = -0xc00L;
    startup_actor_destinations[configured_slot].parameter_two = 0xcb00L;
#endif

    configured_slot = actor_slot_in_ax(147);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = -0xc00L;
    startup_saved_actor_positions[configured_slot].y = 0xcb00L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x565;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2406;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_esi = actor_destination_value_in_esi(-0xc00L);
    destination_at(destination_offset).x = destination_value_esi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0xc00L;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0xcb00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0x1d00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0xcb00L;
#else
    startup_actor_destinations[configured_slot].x = -0xc00L;
    startup_actor_destinations[configured_slot].y = 0xcb00L;
    startup_actor_destinations[configured_slot].parameter_one = -0x1d00L;
    startup_actor_destinations[configured_slot].parameter_two = 0xcb00L;
#endif

    configured_slot = actor_slot_in_ax(148);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = 0x1480L;
    startup_saved_actor_positions[configured_slot].y = 0xc200L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x3665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0x1480L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0xc200L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0x3100L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0xba00L;
#else
    startup_actor_destinations[configured_slot].x = 0x1480L;
    startup_actor_destinations[configured_slot].y = 0xc200L;
    startup_actor_destinations[configured_slot].parameter_one = 0x3100L;
    startup_actor_destinations[configured_slot].parameter_two = 0xba00L;
#endif

    configured_slot = actor_slot_in_ax(149);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = 0x2480L;
    startup_saved_actor_positions[configured_slot].y = 0x9100L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x4665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0x2480L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0x9100L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0x2680L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0xc700L;
#else
    startup_actor_destinations[configured_slot].x = 0x2480L;
    startup_actor_destinations[configured_slot].y = 0x9100L;
    startup_actor_destinations[configured_slot].parameter_one = 0x2680L;
    startup_actor_destinations[configured_slot].parameter_two = 0xc700L;
#endif

    configured_slot = actor_slot_in_ax(150);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = 0x2780L;
    startup_saved_actor_positions[configured_slot].y = 0xad80L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x4665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0x2780L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0xad80L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0x400L;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0xa980L);
    destination_at(destination_offset).parameter_two = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0xa980L;
#endif
#else
    startup_actor_destinations[configured_slot].x = 0x2780L;
    startup_actor_destinations[configured_slot].y = 0xad80L;
    startup_actor_destinations[configured_slot].parameter_one = 0x400L;
    startup_actor_destinations[configured_slot].parameter_two = 0xa980L;
#endif

    configured_slot = actor_slot_in_ax(151);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = 0x3880L;
    startup_saved_actor_positions[configured_slot].y = 0x9280L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x4665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0x3880L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0x9280L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0x1300L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0x9780L;
#else
    startup_actor_destinations[configured_slot].x = 0x3880L;
    startup_actor_destinations[configured_slot].y = 0x9280L;
    startup_actor_destinations[configured_slot].parameter_one = 0x1300L;
    startup_actor_destinations[configured_slot].parameter_two = 0x9780L;
#endif

    configured_slot = actor_slot_in_ax(152);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = -0x3d00L;
    startup_saved_actor_positions[configured_slot].y = 0xb900L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x4665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0x3d00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0xb900L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0x4600L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0xc100L;
#else
    startup_actor_destinations[configured_slot].x = -0x3d00L;
    startup_actor_destinations[configured_slot].y = 0xb900L;
    startup_actor_destinations[configured_slot].parameter_one = -0x4600L;
    startup_actor_destinations[configured_slot].parameter_two = 0xc100L;
#endif

    configured_slot = actor_slot_in_ax(153);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = -0x6200L;
    startup_saved_actor_positions[configured_slot].y = 0xd580L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x4665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0x6200L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0xd580L;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_esi = actor_destination_value_in_esi(-0x4e80L);
    destination_at(destination_offset).parameter_one = destination_value_esi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0x4e80L;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0xe380L);
    destination_at(destination_offset).parameter_two = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0xe380L;
#endif
#else
    startup_actor_destinations[configured_slot].x = -0x6200L;
    startup_actor_destinations[configured_slot].y = 0xd580L;
    startup_actor_destinations[configured_slot].parameter_one = -0x4e80L;
    startup_actor_destinations[configured_slot].parameter_two = 0xe380L;
#endif

    configured_slot = actor_slot_in_ax(154);
    actor_enabled[configured_slot] = 5;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = -0x7300L;
    startup_saved_actor_positions[configured_slot].y = 0xdc80L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 3;
    saved_actor_lotag[configured_slot] = 0x2e65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2562;
    startup_actor_tile_rows[configured_slot].mode_one = 2562;
    startup_actor_tile_rows[configured_slot].mode_two = 2562;
    startup_actor_tile_rows[configured_slot].mode_three = 2562;
    startup_actor_tile_rows[configured_slot].mode_four = 2562;
    startup_actor_tile_rows[configured_slot].mode_five = 2562;
    startup_actor_tile_rows[configured_slot].mode_six = 2562;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0x7300L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0xdc80L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0x5a00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0xd780L;
#else
    startup_actor_destinations[configured_slot].x = -0x7300L;
    startup_actor_destinations[configured_slot].y = 0xdc80L;
    startup_actor_destinations[configured_slot].parameter_one = -0x5a00L;
    startup_actor_destinations[configured_slot].parameter_two = 0xd780L;
#endif

    configured_slot = actor_slot_in_ax(155);
    actor_enabled[configured_slot] = 5;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = -0x6c80L;
    startup_saved_actor_positions[configured_slot].y = 0xdf00L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 3;
    saved_actor_lotag[configured_slot] = 0x2e65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 2;
    startup_actor_tile_rows[configured_slot].base = 2562;
    startup_actor_tile_rows[configured_slot].mode_one = 2562;
    startup_actor_tile_rows[configured_slot].mode_two = 2562;
    startup_actor_tile_rows[configured_slot].mode_three = 2562;
    startup_actor_tile_rows[configured_slot].mode_four = 2562;
    startup_actor_tile_rows[configured_slot].mode_five = 2562;
    startup_actor_tile_rows[configured_slot].mode_six = 2562;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0x6c80L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0xdf00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0x5b00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0xd380L;
#else
    startup_actor_destinations[configured_slot].x = -0x6c80L;
    startup_actor_destinations[configured_slot].y = 0xdf00L;
    startup_actor_destinations[configured_slot].parameter_one = -0x5b00L;
    startup_actor_destinations[configured_slot].parameter_two = 0xd380L;
#endif

    configured_slot = actor_slot_in_ax(157);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = -0x4f00L;
    startup_saved_actor_positions[configured_slot].y = 0x7500L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x565;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 3;
    startup_actor_tile_rows[configured_slot].base = 2406;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_waypoints[configured_slot].first = 56;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(158);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = -0x380L;
    startup_saved_actor_positions[configured_slot].y = 0x6580L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x565;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 3;
    startup_actor_tile_rows[configured_slot].base = 2406;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_waypoints[configured_slot].first = 59;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_esi = actor_destination_value_in_esi(0);
    destination_at(destination_offset).x = destination_value_esi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).y = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_one = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_two = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#endif
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(159);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = -0x2200L;
    startup_saved_actor_positions[configured_slot].y = 0x8d80L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x1865;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2406;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0x2200L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0x8d80L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0x580L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0x8d80L;
#else
    startup_actor_destinations[configured_slot].x = -0x2200L;
    startup_actor_destinations[configured_slot].y = 0x8d80L;
    startup_actor_destinations[configured_slot].parameter_one = 0x580L;
    startup_actor_destinations[configured_slot].parameter_two = 0x8d80L;
#endif

    configured_slot = actor_slot_in_ax(160);
    actor_enabled[configured_slot] = 5;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = -0x1580L;
    startup_saved_actor_positions[configured_slot].y = 0x7200L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 3;
    saved_actor_lotag[configured_slot] = 0x2e65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2562;
    startup_actor_tile_rows[configured_slot].mode_one = 2562;
    startup_actor_tile_rows[configured_slot].mode_two = 2562;
    startup_actor_tile_rows[configured_slot].mode_three = 2562;
    startup_actor_tile_rows[configured_slot].mode_four = 2562;
    startup_actor_tile_rows[configured_slot].mode_five = 2562;
    startup_actor_tile_rows[configured_slot].mode_six = 2562;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0x1580L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0x7200L;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_esi = actor_destination_value_in_esi(-0x1500L);
    destination_at(destination_offset).parameter_one = destination_value_esi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0x1500L;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0xa100L);
    destination_at(destination_offset).parameter_two = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0xa100L;
#endif
#else
    startup_actor_destinations[configured_slot].x = -0x1580L;
    startup_actor_destinations[configured_slot].y = 0x7200L;
    startup_actor_destinations[configured_slot].parameter_one = -0x1500L;
    startup_actor_destinations[configured_slot].parameter_two = 0xa100L;
#endif

    configured_slot = actor_slot_in_ax(161);
    actor_enabled[configured_slot] = 5;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = -0x180L;
    startup_saved_actor_positions[configured_slot].y = 0x8400L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 3;
    saved_actor_lotag[configured_slot] = 0x2e65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2562;
    startup_actor_tile_rows[configured_slot].mode_one = 2562;
    startup_actor_tile_rows[configured_slot].mode_two = 2562;
    startup_actor_tile_rows[configured_slot].mode_three = 2562;
    startup_actor_tile_rows[configured_slot].mode_four = 2562;
    startup_actor_tile_rows[configured_slot].mode_five = 2562;
    startup_actor_tile_rows[configured_slot].mode_six = 2562;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0x180L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0x8400L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0x2580L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0xa500L;
#else
    startup_actor_destinations[configured_slot].x = -0x180L;
    startup_actor_destinations[configured_slot].y = 0x8400L;
    startup_actor_destinations[configured_slot].parameter_one = -0x2580L;
    startup_actor_destinations[configured_slot].parameter_two = 0xa500L;
#endif

    configured_slot = actor_slot_in_ax(162);
    actor_enabled[configured_slot] = 5;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = 0x3480L;
    startup_saved_actor_positions[configured_slot].y = 0xb100L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 3;
    saved_actor_lotag[configured_slot] = 0x2e65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2562;
    startup_actor_tile_rows[configured_slot].mode_one = 2562;
    startup_actor_tile_rows[configured_slot].mode_two = 2562;
    startup_actor_tile_rows[configured_slot].mode_three = 2562;
    startup_actor_tile_rows[configured_slot].mode_four = 2562;
    startup_actor_tile_rows[configured_slot].mode_five = 2562;
    startup_actor_tile_rows[configured_slot].mode_six = 2562;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0x3480L);
    destination_at(destination_offset).x = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0x3480L;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0xb100L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0x2780L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0xa700L;
#else
    startup_actor_destinations[configured_slot].x = 0x3480L;
    startup_actor_destinations[configured_slot].y = 0xb100L;
    startup_actor_destinations[configured_slot].parameter_one = 0x2780L;
    startup_actor_destinations[configured_slot].parameter_two = 0xa700L;
#endif

    configured_slot = actor_slot_in_ax(163);
    actor_enabled[configured_slot] = 5;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = 0x3480L;
    startup_saved_actor_positions[configured_slot].y = 0xa300L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 3;
    saved_actor_lotag[configured_slot] = 0x2e65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2562;
    startup_actor_tile_rows[configured_slot].mode_one = 2562;
    startup_actor_tile_rows[configured_slot].mode_two = 2562;
    startup_actor_tile_rows[configured_slot].mode_three = 2562;
    startup_actor_tile_rows[configured_slot].mode_four = 2562;
    startup_actor_tile_rows[configured_slot].mode_five = 2562;
    startup_actor_tile_rows[configured_slot].mode_six = 2562;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0x3480L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0xa300L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0x2780L;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0xad00L);
    destination_at(destination_offset).parameter_two = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0xad00L;
#endif
#else
    startup_actor_destinations[configured_slot].x = 0x3480L;
    startup_actor_destinations[configured_slot].y = 0xa300L;
    startup_actor_destinations[configured_slot].parameter_one = 0x2780L;
    startup_actor_destinations[configured_slot].parameter_two = 0xad00L;
#endif

    configured_slot = actor_slot_in_ax(164);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = -128;
    startup_saved_actor_positions[configured_slot].y = 0xaf00L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x565;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2406;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -128;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0xaf00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -128;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0xa480L;
#else
    startup_actor_destinations[configured_slot].x = -128;
    startup_actor_destinations[configured_slot].y = 0xaf00L;
    startup_actor_destinations[configured_slot].parameter_one = -128;
    startup_actor_destinations[configured_slot].parameter_two = 0xa480L;
#endif

    configured_slot = actor_slot_in_ax(165);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = -0x100L;
    startup_saved_actor_positions[configured_slot].y = 0xb980L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x565;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 2;
    startup_actor_tile_rows[configured_slot].base = 2406;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0);
    destination_at(destination_offset).x = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
    destination_zero = actor_destination_zero_in_ebx(0L);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(166);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 7;
    startup_saved_actor_positions[configured_slot].x = -0x100L;
    startup_saved_actor_positions[configured_slot].y = 0xc680L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x565;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 2;
    startup_actor_tile_rows[configured_slot].base = 2406;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    destination_zero = actor_destination_zero_in_ebx(0L);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_esi = actor_destination_value_in_esi(0);
    destination_at(destination_offset).parameter_one = destination_value_esi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = actor_destination_zero_in_ebx(destination_zero);
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(209);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 10;
    startup_saved_actor_positions[configured_slot].x = -0x1d00L;
    startup_saved_actor_positions[configured_slot].y = 0xcb00L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x565;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2406;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0x1d00L;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0xcb00L);
    destination_at(destination_offset).y = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0xcb00L;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0xc00L;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_two = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0xcb00L;
#endif
#else
    startup_actor_destinations[configured_slot].x = -0x1d00L;
    startup_actor_destinations[configured_slot].y = 0xcb00L;
    startup_actor_destinations[configured_slot].parameter_one = -0xc00L;
    startup_actor_destinations[configured_slot].parameter_two = 0xcb00L;
#endif

    configured_slot = actor_slot_in_ax(210);
    actor_enabled[configured_slot] = 2;
    actor_board[configured_slot] = 10;
    startup_saved_actor_positions[configured_slot].x = -0x780L;
    startup_saved_actor_positions[configured_slot].y = 0xad0eL;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 0;
    saved_actor_lotag[configured_slot] = 0x1a65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2672;
    startup_actor_tile_rows[configured_slot].mode_one = 2672;
    startup_actor_tile_rows[configured_slot].mode_two = 2672;
    startup_actor_tile_rows[configured_slot].mode_three = 2672;
    startup_actor_tile_rows[configured_slot].mode_four = 2672;
    startup_actor_tile_rows[configured_slot].mode_five = 2672;
    startup_actor_tile_rows[configured_slot].mode_six = 2672;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0x780L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0xac00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0x3300L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0xac00L;
#else
    startup_actor_destinations[configured_slot].x = -0x780L;
    startup_actor_destinations[configured_slot].y = 0xac00L;
    startup_actor_destinations[configured_slot].parameter_one = -0x3300L;
    startup_actor_destinations[configured_slot].parameter_two = 0xac00L;
#endif

    configured_slot = actor_slot_in_ax(211);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 10;
    startup_saved_actor_positions[configured_slot].x = -0x4080L;
    startup_saved_actor_positions[configured_slot].y = 0xb000L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x4665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_esi = actor_destination_value_in_esi(-0x4080L);
    destination_at(destination_offset).x = destination_value_esi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0x4080L;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0xb000L;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_one = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0x4080L;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0x9d00L);
    destination_at(destination_offset).parameter_two = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0x9d00L;
#endif
#else
    startup_actor_destinations[configured_slot].x = -0x4080L;
    startup_actor_destinations[configured_slot].y = 0xb000L;
    startup_actor_destinations[configured_slot].parameter_one = -0x4080L;
    startup_actor_destinations[configured_slot].parameter_two = 0x9d00L;
#endif

    configured_slot = actor_slot_in_ax(212);
    actor_enabled[configured_slot] = 5;
    actor_board[configured_slot] = 10;
    startup_saved_actor_positions[configured_slot].x = -0x2480L;
    startup_saved_actor_positions[configured_slot].y = 0x8d00L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 3;
    saved_actor_lotag[configured_slot] = 0x2e65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2562;
    startup_actor_tile_rows[configured_slot].mode_one = 2562;
    startup_actor_tile_rows[configured_slot].mode_two = 2562;
    startup_actor_tile_rows[configured_slot].mode_three = 2562;
    startup_actor_tile_rows[configured_slot].mode_four = 2562;
    startup_actor_tile_rows[configured_slot].mode_five = 2562;
    startup_actor_tile_rows[configured_slot].mode_six = 2562;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0x2480L;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0x8d00L);
    destination_at(destination_offset).y = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0x8d00L;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0x500L;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_two = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0x8d00L;
#endif
#else
    startup_actor_destinations[configured_slot].x = -0x2480L;
    startup_actor_destinations[configured_slot].y = 0x8d00L;
    startup_actor_destinations[configured_slot].parameter_one = -0x500L;
    startup_actor_destinations[configured_slot].parameter_two = 0x8d00L;
#endif

    configured_slot = actor_slot_in_ax(177);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 24;
    startup_saved_actor_positions[configured_slot].x = -0x6980L;
    startup_saved_actor_positions[configured_slot].y = 0x1f80L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x565;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 5;
    startup_actor_tile_rows[configured_slot].base = 2406;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_tile_rows[configured_slot].mode_six = 2406;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(-0x6980L);
    destination_at(destination_offset).x = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0x6980L;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0x1f80L;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_one = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0x6980L;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = -0x1600L;
#else
    startup_actor_destinations[configured_slot].x = -0x6980L;
    startup_actor_destinations[configured_slot].y = 0x1f80L;
    startup_actor_destinations[configured_slot].parameter_one = -0x6980L;
    startup_actor_destinations[configured_slot].parameter_two = -0x1600L;
#endif

    configured_slot = actor_slot_in_ax(178);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 24;
    startup_saved_actor_positions[configured_slot].x = -0x5f80L;
    startup_saved_actor_positions[configured_slot].y = -0x1800L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x565;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2406;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_tile_rows[configured_slot].mode_six = 2406;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0x5f80L;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(-0x1800L);
    destination_at(destination_offset).y = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = -0x1800L;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0x5f80L;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0x2100L);
    destination_at(destination_offset).parameter_two = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0x2100L;
#endif
#else
    startup_actor_destinations[configured_slot].x = -0x5f80L;
    startup_actor_destinations[configured_slot].y = -0x1800L;
    startup_actor_destinations[configured_slot].parameter_one = -0x5f80L;
    startup_actor_destinations[configured_slot].parameter_two = 0x2100L;
#endif

    configured_slot = actor_slot_in_ax(179);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 24;
    startup_saved_actor_positions[configured_slot].x = -0x6400L;
    startup_saved_actor_positions[configured_slot].y = 0x2200L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x565;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 3;
    startup_actor_tile_rows[configured_slot].base = 2406;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_tile_rows[configured_slot].mode_six = 2406;
    startup_actor_waypoints[configured_slot].first = 105;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_esi = actor_destination_value_in_esi(0);
    destination_at(destination_offset).x = destination_value_esi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).y = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_one = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_two = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#endif
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(180);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 24;
    startup_saved_actor_positions[configured_slot].x = -0x6400L;
    startup_saved_actor_positions[configured_slot].y = 0x1000L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x565;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 1;
    startup_actor_tile_rows[configured_slot].base = 2406;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_tile_rows[configured_slot].mode_six = 2406;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0);
    destination_at(destination_offset).x = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
    destination_zero = actor_destination_zero_in_ebx(0L);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = actor_destination_zero_in_ebx(destination_zero);
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(181);
    actor_enabled[configured_slot] = 0;
    actor_board[configured_slot] = 24;
    startup_saved_actor_positions[configured_slot].x = -0x6400L;
    startup_saved_actor_positions[configured_slot].y = -0x900L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 2;
    saved_actor_lotag[configured_slot] = 0x565;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 2;
    startup_actor_tile_rows[configured_slot].base = 2406;
    startup_actor_tile_rows[configured_slot].mode_one = 2406;
    startup_actor_tile_rows[configured_slot].mode_two = 2296;
    startup_actor_tile_rows[configured_slot].mode_three = 2296;
    startup_actor_tile_rows[configured_slot].mode_four = 2296;
    startup_actor_tile_rows[configured_slot].mode_five = 2406;
    startup_actor_tile_rows[configured_slot].mode_six = 2406;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    destination_zero = actor_destination_zero_in_ebx(0L);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_esi = actor_destination_value_in_esi(0);
    destination_at(destination_offset).parameter_one = destination_value_esi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = actor_destination_zero_in_ebx(destination_zero);
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(182);
    actor_enabled[configured_slot] = 2;
    actor_board[configured_slot] = 24;
    startup_saved_actor_positions[configured_slot].x = -0x4f80L;
    startup_saved_actor_positions[configured_slot].y = 0xb80L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 0;
    saved_actor_lotag[configured_slot] = 0x1a65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2672;
    startup_actor_tile_rows[configured_slot].mode_one = 0;
    startup_actor_tile_rows[configured_slot].mode_two = 2672;
    startup_actor_tile_rows[configured_slot].mode_three = 2672;
    startup_actor_tile_rows[configured_slot].mode_four = 2672;
    startup_actor_tile_rows[configured_slot].mode_five = 0;
    startup_actor_tile_rows[configured_slot].mode_six = 0;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0x4f80L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0xb80L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0x4f80L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = -0x680L;
#else
    startup_actor_destinations[configured_slot].x = -0x4f80L;
    startup_actor_destinations[configured_slot].y = 0xb80L;
    startup_actor_destinations[configured_slot].parameter_one = -0x4f80L;
    startup_actor_destinations[configured_slot].parameter_two = -0x680L;
#endif

    configured_slot = actor_slot_in_ax(183);
    actor_enabled[configured_slot] = 2;
    actor_board[configured_slot] = 24;
    startup_saved_actor_positions[configured_slot].x = -0x3880L;
    startup_saved_actor_positions[configured_slot].y = 0x400L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 0;
    saved_actor_lotag[configured_slot] = 0x1a65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 2;
    startup_actor_tile_rows[configured_slot].base = 2672;
    startup_actor_tile_rows[configured_slot].mode_one = 0;
    startup_actor_tile_rows[configured_slot].mode_two = 2672;
    startup_actor_tile_rows[configured_slot].mode_three = 2672;
    startup_actor_tile_rows[configured_slot].mode_four = 2672;
    startup_actor_tile_rows[configured_slot].mode_five = 0;
    startup_actor_tile_rows[configured_slot].mode_six = 0;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0);
    destination_at(destination_offset).x = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
    destination_zero = actor_destination_zero_in_ebx(0L);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = actor_destination_zero_in_ebx(destination_zero);
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(184);
    actor_enabled[configured_slot] = 2;
    actor_board[configured_slot] = 24;
    startup_saved_actor_positions[configured_slot].x = -0x3400L;
    startup_saved_actor_positions[configured_slot].y = -0x200L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 0;
    saved_actor_lotag[configured_slot] = 0x1a65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 3;
    startup_actor_tile_rows[configured_slot].base = 2672;
    startup_actor_tile_rows[configured_slot].mode_one = 0;
    startup_actor_tile_rows[configured_slot].mode_two = 2672;
    startup_actor_tile_rows[configured_slot].mode_three = 2672;
    startup_actor_tile_rows[configured_slot].mode_four = 2672;
    startup_actor_tile_rows[configured_slot].mode_five = 0;
    startup_actor_tile_rows[configured_slot].mode_six = 0;
    startup_actor_waypoints[configured_slot].first = 108;
#ifdef ACTOR_DESTINATION_CONTEXT
    destination_zero = actor_destination_zero_in_ebx(0L);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_esi = actor_destination_value_in_esi(0);
    destination_at(destination_offset).parameter_one = destination_value_esi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = actor_destination_zero_in_ebx(destination_zero);
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(185);
    actor_enabled[configured_slot] = 5;
    actor_board[configured_slot] = 24;
    startup_saved_actor_positions[configured_slot].x = -0x280L;
    startup_saved_actor_positions[configured_slot].y = 0x1830L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 3;
    saved_actor_lotag[configured_slot] = 0x2e65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2562;
    startup_actor_tile_rows[configured_slot].mode_one = 0;
    startup_actor_tile_rows[configured_slot].mode_two = 2562;
    startup_actor_tile_rows[configured_slot].mode_three = 2562;
    startup_actor_tile_rows[configured_slot].mode_four = 2562;
    startup_actor_tile_rows[configured_slot].mode_five = 0;
    startup_actor_tile_rows[configured_slot].mode_six = 0;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = -0x280L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0x1b00L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = -0x280L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = -0xc00L;
#else
    startup_actor_destinations[configured_slot].x = -0x280L;
    startup_actor_destinations[configured_slot].y = 0x1b00L;
    startup_actor_destinations[configured_slot].parameter_one = -0x280L;
    startup_actor_destinations[configured_slot].parameter_two = -0xc00L;
#endif

    configured_slot = actor_slot_in_ax(186);
    actor_enabled[configured_slot] = 5;
    actor_board[configured_slot] = 24;
    startup_saved_actor_positions[configured_slot].x = 0x380L;
    startup_saved_actor_positions[configured_slot].y = 0x4700L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 3;
    saved_actor_lotag[configured_slot] = 0x2e65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 2;
    startup_actor_tile_rows[configured_slot].base = 2562;
    startup_actor_tile_rows[configured_slot].mode_one = 0;
    startup_actor_tile_rows[configured_slot].mode_two = 2562;
    startup_actor_tile_rows[configured_slot].mode_three = 2562;
    startup_actor_tile_rows[configured_slot].mode_four = 2562;
    startup_actor_tile_rows[configured_slot].mode_five = 0;
    startup_actor_tile_rows[configured_slot].mode_six = 0;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0);
    destination_at(destination_offset).x = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).y = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_one = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_two = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#endif
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(187);
    actor_enabled[configured_slot] = 5;
    actor_board[configured_slot] = 24;
    startup_saved_actor_positions[configured_slot].x = -0x1680L;
    startup_saved_actor_positions[configured_slot].y = 0x6a00L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 16;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 3;
    saved_actor_lotag[configured_slot] = 0x2e65;
    actor_profile[configured_slot] = 1;
    actor_mode[configured_slot] = 3;
    startup_actor_tile_rows[configured_slot].base = 2562;
    startup_actor_tile_rows[configured_slot].mode_one = 0;
    startup_actor_tile_rows[configured_slot].mode_two = 2562;
    startup_actor_tile_rows[configured_slot].mode_three = 2562;
    startup_actor_tile_rows[configured_slot].mode_four = 2562;
    startup_actor_tile_rows[configured_slot].mode_five = 0;
    startup_actor_tile_rows[configured_slot].mode_six = 0;
    startup_actor_waypoints[configured_slot].first = 111;
#ifdef ACTOR_DESTINATION_CONTEXT
    destination_zero = actor_destination_zero_in_ebx(0L);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = actor_destination_zero_in_ebx(destination_zero);
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = actor_destination_zero_in_ebx(destination_zero);
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(188);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 24;
    startup_saved_actor_positions[configured_slot].x = 0x3100L;
    startup_saved_actor_positions[configured_slot].y = 0x900L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x3665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 5;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0x3100L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0x900L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0x3100L;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = -0x1b00L;
#else
    startup_actor_destinations[configured_slot].x = 0x3100L;
    startup_actor_destinations[configured_slot].y = 0x900L;
    startup_actor_destinations[configured_slot].parameter_one = 0x3100L;
    startup_actor_destinations[configured_slot].parameter_two = -0x1b00L;
#endif

    configured_slot = actor_slot_in_ax(189);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 24;
    startup_saved_actor_positions[configured_slot].x = 0x4980L;
    startup_saved_actor_positions[configured_slot].y = 0xc00L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x3665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 4;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0x4980L);
    destination_at(destination_offset).x = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0x4980L;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0xc00L;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_one = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0x4980L;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = -0x500L;
#else
    startup_actor_destinations[configured_slot].x = 0x4980L;
    startup_actor_destinations[configured_slot].y = 0xc00L;
    startup_actor_destinations[configured_slot].parameter_one = 0x4980L;
    startup_actor_destinations[configured_slot].parameter_two = -0x500L;
#endif

    configured_slot = actor_slot_in_ax(190);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 24;
    startup_saved_actor_positions[configured_slot].x = 0x6980L;
    startup_saved_actor_positions[configured_slot].y = -0x1880L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x3665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 3;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 114;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(191);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 24;
    startup_saved_actor_positions[configured_slot].x = 0x6780L;
    startup_saved_actor_positions[configured_slot].y = 0x3500L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x3665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 1;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_esi = actor_destination_value_in_esi(0);
    destination_at(destination_offset).x = destination_value_esi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).y = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_one = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_two = actor_destination_value_in_esi(destination_value_esi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#endif
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif

    configured_slot = actor_slot_in_ax(192);
    actor_enabled[configured_slot] = 4;
    actor_board[configured_slot] = 24;
    startup_saved_actor_positions[configured_slot].x = 0x6080L;
    startup_saved_actor_positions[configured_slot].y = 0x3a80L;
    actor_z_offset[configured_slot] = 0;
    actor_sequence_initial[configured_slot] = 8;
    actor_health[configured_slot] = 1000;
    actor_projectile_type[configured_slot] = 1;
    saved_actor_lotag[configured_slot] = 0x3665;
    actor_profile[configured_slot] = 2;
    actor_mode[configured_slot] = 2;
    startup_actor_tile_rows[configured_slot].base = 2488;
    startup_actor_tile_rows[configured_slot].mode_one = 2488;
    startup_actor_tile_rows[configured_slot].mode_two = 2488;
    startup_actor_tile_rows[configured_slot].mode_three = 2488;
    startup_actor_tile_rows[configured_slot].mode_four = 2488;
    startup_actor_tile_rows[configured_slot].mode_five = 2488;
    startup_actor_waypoints[configured_slot].first = 0;
#ifdef ACTOR_DESTINATION_CONTEXT
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_value_edi = actor_destination_value_in_edi(0);
    destination_at(destination_offset).x = destination_value_edi;
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .x = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .y = 0;
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_one = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_one = 0;
#endif
    configured_slot = actor_slot_in_ax(configured_slot);
#ifdef ACTOR_DESTINATION_VALUES
    destination_offset = actor_destination_offset_in_edx((long)configured_slot * 16L);
    destination_at(destination_offset).parameter_two = actor_destination_value_in_edi(destination_value_edi);
#else
    destination_at(actor_destination_offset_in_edx((long)configured_slot * 16L))
        .parameter_two = 0;
#endif
#else
    startup_actor_destinations[configured_slot].x = 0;
    startup_actor_destinations[configured_slot].y = 0;
    startup_actor_destinations[configured_slot].parameter_one = 0;
    startup_actor_destinations[configured_slot].parameter_two = 0;
#endif
}
