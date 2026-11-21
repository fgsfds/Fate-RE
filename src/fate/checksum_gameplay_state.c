/* Watcom 32-bit ABI: long is 32 bits, short is 16 bits. */
#pragma pack(push, 1)
typedef struct {
    long x, y, z;
    short cstat, picnum;
    signed char shade;
    unsigned char pal, clipdist, filler, xrepeat, yrepeat;
    signed char xoffset, yoffset;
    short sectnum, statnum, angle, owner, xvel, yvel, zvel, lotag, hitag, extra;
} ChecksumSprite;
#pragma pack(pop)

extern long checksum_random_seed;
extern long checksum_checksum_table[256];
extern long checksum_player_x[], checksum_player_y[], checksum_player_z[];
extern long checksum_player_horizon[], checksum_status_right_tenths[];
extern short checksum_player_angle[], checksum_player_sector[];
extern short checksum_first_player, checksum_next_player[];
extern short checksum_hit_sprite_list_head[], checksum_next_sprite_stat[];
extern ChecksumSprite checksum_sprite[];

/* Four-byte table slots contribute only their low word. Each assignment
 * truncates the promoted, nonnegative shifted accumulator back to 16 bits. */
#define CHECKSUM_BYTE(value) \
    checksum = (checksum << 8) ^ (unsigned short)checksum_checksum_table[ \
        ((unsigned short)checksum >> 8) ^ ((value) & 255L)]
/* Operand order preserves Watcom temporary lifetimes at two byte feeds. */
#define CHECKSUM_BYTE_INPUT_FIRST(value) \
    checksum = (checksum << 8) ^ (unsigned short)checksum_checksum_table[ \
        ((value) & 255L) ^ ((unsigned short)checksum >> 8)]
#define CHECKSUM_WORD(value) \
    CHECKSUM_BYTE(value); \
    CHECKSUM_BYTE((value) >> 8)
#define CHECKSUM_LONG(value) \
    CHECKSUM_WORD(value); \
    CHECKSUM_BYTE((value) >> 16); \
    CHECKSUM_BYTE((value) >> 24)

/* Returns an unsigned, zero-extended 16-bit checksum in EAX, including when
 * there are no players or sprites. Upper checksum_random_seed bytes are excluded. */
unsigned long checksum_gameplay_state(void)
{
    unsigned short checksum;
    long player, index;
    ChecksumSprite *item;

    checksum = (unsigned short)checksum_checksum_table[checksum_random_seed & 255L];
    CHECKSUM_BYTE(checksum_random_seed >> 8);

    for (player = checksum_first_player; player >= 0; player = checksum_next_player[player]) {
        CHECKSUM_LONG(checksum_player_x[player]);
        CHECKSUM_LONG(checksum_player_y[player]);
        CHECKSUM_LONG(checksum_player_z[player]);
        CHECKSUM_BYTE(checksum_player_angle[player]);
        CHECKSUM_BYTE_INPUT_FIRST(checksum_player_angle[player] >> 8);
        CHECKSUM_LONG(checksum_player_horizon[player]);
        CHECKSUM_LONG(checksum_status_right_tenths[player]);
        CHECKSUM_WORD(checksum_player_sector[player]);
    }

    for (player = 7; player >= 0; --player) {
        for (index = checksum_hit_sprite_list_head[player]; index >= 0;
             index = checksum_next_sprite_stat[index]) {
            item = &checksum_sprite[index];
            CHECKSUM_LONG(item->x);
            CHECKSUM_WORD(item->y);
            CHECKSUM_BYTE(item->y >> 16);
            CHECKSUM_BYTE_INPUT_FIRST(item->y >> 24);
            CHECKSUM_LONG(item->z);
            CHECKSUM_WORD(item->angle);
        }
    }
    return checksum & 65535UL;
}
