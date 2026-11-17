extern short first_player_sprite, holding_sprite, held_sprite;
extern short actor_sprite[];
extern signed char actor_active[];
extern unsigned char actor_level[];
extern const char level_names[][20], discard_error[];
extern long player_x[], player_y[], player_z[];
extern short player_angle[], player_sector[];

extern int deletesprite(short);
#pragma aux deletesprite modify exact [eax];
extern void report_game_error(const char *);
#pragma aux report_game_error modify exact [eax];
extern char *strcpy(char *, const char *);
#pragma aux strcpy modify exact [eax];
extern char *strcat(char *, const char *);
#pragma aux strcat modify exact [eax];
extern int save_build_map(const char *, const long *, const long *, const long *, const short *, const short *);
#pragma aux save_build_map parm routine [eax] [edx] [ebx] [ecx] modify exact [eax edx ebx ecx];

/* Preserve the Watcom registers for the slot and invalid-sprite marker. */
extern int hold_invalid_sprite(int);
#pragma aux hold_invalid_sprite = parm [edi] value [edi] modify exact [];
extern short hold_actor_sprite(short);
#pragma aux hold_actor_sprite = parm [ax] value [ax] modify exact [];

int discard_level_and_load_board(int level, const char *extension)
{
    char filename[80];
    int actor;

    deletesprite(first_player_sprite);
    if (holding_sprite)
        deletesprite(held_sprite);
    if ((short)level) {
        actor = 0;
        goto check_actor;
        do {
            if (actor_active[actor] != -1 && (short)actor_level[actor] == (short)level) {
                deletesprite(hold_actor_sprite(actor_sprite[actor]));
                actor_sprite[actor] = hold_invalid_sprite(-1);
            }
            ++actor;
        check_actor:
            ;
        } while (actor <= 500);

        actor = 0;
        goto check_slot;
        do {
            if (actor_sprite[actor] != -1)
                report_game_error(discard_error);
            ++actor;
        check_slot:
            ;
        } while (actor <= 500);
    }
    /* The shared board writer records the remaining sprites in the new file. */
    strcpy(filename, level_names[(short)level]);
    strcat(filename, extension);
    return save_build_map(filename, player_x, player_y, player_z, player_angle, player_sector);
}
