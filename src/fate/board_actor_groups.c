/* Native groups for the first actor and actor 103's startup tile row. */
enum { ACTOR_SLOTS = 501, FIRST_ACTOR = 1, BOARD_FIVE_ACTOR = 103 };

typedef struct {
    long x, y, parameter_one, parameter_two;
} ActorDestination;

typedef struct {
    short base, mode_one, mode_two, mode_three, mode_four;
    short mode_five, mode_six, reserved_seven, reserved_eight;
} ActorTiles;

typedef char actor_destination_stride[(sizeof(ActorDestination) == 16) ? 1 : -1];
typedef char actor_tiles_stride[(sizeof(ActorTiles) == 18) ? 1 : -1];

extern signed char actor_enabled[ACTOR_SLOTS];
extern unsigned char actor_board[ACTOR_SLOTS];
extern ActorDestination actor_destinations[ACTOR_SLOTS];
/* Typed view of the storage exposed elsewhere as the flat actor_tiles array. */
extern ActorTiles actor_tile_rows[ACTOR_SLOTS];

extern signed char actor_template_value(signed char);
#pragma aux actor_template_value = "" parm [ah] value [ah] modify exact [];
extern unsigned char actor_board_value(unsigned char);
#pragma aux actor_board_value = "" parm [dl] value [dl] modify exact [];
extern long destination_clear_value(long);
#pragma aux destination_clear_value = "" parm [esi] value [esi] modify exact [];
extern short actor_tile_value(short);
#pragma aux actor_tile_value = "" parm [cx] value [cx] modify exact [];

void assign_first_actor_board(void);
#pragma aux assign_first_actor_board modify exact [eax];
void clear_first_actor_destination(void);
#pragma aux clear_first_actor_destination modify exact [eax];
void assign_actor_103_tiles(void);
#pragma aux assign_actor_103_tiles modify exact [eax];

void assign_first_actor_board(void)
{
    signed char actor_template = actor_template_value(5);
    unsigned char board = actor_board_value(1);

    actor_enabled[FIRST_ACTOR] = actor_template;
    actor_board[FIRST_ACTOR] = board;
}

void clear_first_actor_destination(void)
{
    long zero = destination_clear_value(0L);

    actor_destinations[FIRST_ACTOR].x = zero;
    actor_destinations[FIRST_ACTOR].y = zero;
    actor_destinations[FIRST_ACTOR].parameter_one = zero;
    actor_destinations[FIRST_ACTOR].parameter_two = zero;
}

void assign_actor_103_tiles(void)
{
    short tile = actor_tile_value(2672);

    actor_tile_rows[BOARD_FIVE_ACTOR].base = tile;
    actor_tile_rows[BOARD_FIVE_ACTOR].mode_one = tile;
    actor_tile_rows[BOARD_FIVE_ACTOR].mode_two = tile;
    actor_tile_rows[BOARD_FIVE_ACTOR].mode_three = tile;
    actor_tile_rows[BOARD_FIVE_ACTOR].mode_four = tile;
    actor_tile_rows[BOARD_FIVE_ACTOR].mode_five = tile;
    actor_tile_rows[BOARD_FIVE_ACTOR].mode_six = tile;
}

