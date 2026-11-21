extern unsigned char crush_view_kick;
extern long player_horizon[], crush_view_before, crush_view_after;

void schedule_crush_view_kick(short strength)
{
    if (strength < 0 && !crush_view_kick) {
        crush_view_kick = 1;
        crush_view_before = player_horizon[0];
        crush_view_after = (-strength >> 8) + player_horizon[0] + 4;
    }
}

void apply_crush_view_kick(void)
{
    switch (crush_view_kick) {
    case 2:
        player_horizon[0] = crush_view_before;
        crush_view_kick = 0;
        break;
    case 1:
        player_horizon[0] = crush_view_after;
        crush_view_kick = 2;
        break;
    }
}
