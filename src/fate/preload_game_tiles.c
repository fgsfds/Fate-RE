extern long waloff[];
extern signed char current_board;
extern void loadtile(int);
#pragma aux loadtile modify exact [eax];

#define PRELOAD_RANGE(first, last) \
    do { \
        int tile = (first); \
        do { \
            if (!waloff[tile]) \
                loadtile((short)tile); \
        } while (++tile <= (last)); \
    } while (0)

void preload_game_tiles(void)
{
    int board;

    PRELOAD_RANGE(0x2fe, 0x32a);
    PRELOAD_RANGE(0x3e5, 0x3fb);
    PRELOAD_RANGE(0x5ab, 0x5ad);

    board = current_board;
    if (board == 4 || board == 5 || board == 7)
        PRELOAD_RANGE(0x8f8, 0x9b6);

    board = current_board;
    if (board == 6 || board == 7)
        PRELOAD_RANGE(0x9b8, 0xa01);

    board = current_board;
    if (board == 6 || board == 7)
        PRELOAD_RANGE(0xa02, 0xa6f);

    board = current_board;
    if (board == 5)
        PRELOAD_RANGE(0xa70, 0xadd);
}
