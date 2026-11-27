#pragma pack(push, 1)
typedef struct {
    char prefix[0x21];
    long speed;
} Crusher;
typedef struct {
    short wall_index, wall_count;
    long ceiling, floor;
    char tail[28];
} CrusherSector;
#pragma pack(pop)

extern short numsectors, player_sector;
extern long player_horizon;
extern CrusherSector sector[];
extern const char crusher_bad_sector[], crusher_null_record[];
extern void report_game_error(const char *);
#pragma aux report_game_error modify exact [eax];
extern void adjust_status_value(short);
#pragma aux adjust_status_value modify exact [eax ebx ecx edx];

/* Keep the original register allocation for the two sector lookups. */
extern short keep_current_sector(short);
#pragma aux keep_current_sector = "" parm [si] value [si] modify exact [];
void check_crushed_player(const Crusher *crusher, short sector_index)
{
    short current;
    if (sector_index < 0 || sector_index >= numsectors)
        report_game_error(crusher_bad_sector);
    if (!crusher)
        report_game_error(crusher_null_record);
    current = keep_current_sector(player_sector);
    if (sector_index == current &&
        sector[current].floor - 0x4000 < sector[sector_index].ceiling) {
        if (player_horizon > 100)
            player_horizon = 100;
        player_horizon -= (crusher->speed >> 1) + 8;
        if (player_horizon < 0)
            player_horizon = 0;
        adjust_status_value((short)(-((unsigned long)crusher->speed << 4)));
    }
}
