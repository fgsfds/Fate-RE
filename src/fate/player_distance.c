extern long player_x, player_y;
extern long labs(long);
#pragma aux labs modify exact [eax];

int player_within_512_xy(long x, long y)
{
    if (labs(player_x - x) < 512 && labs(player_y - y) < 512)
        return 1;
    return 0;
}

int player_within_4096_xy(long x, long y)
{
    if (labs(player_x - x) < 4096 && labs(player_y - y) < 4096)
        return 1;
    return 0;
}
