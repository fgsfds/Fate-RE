#pragma pack(push, 1)
typedef struct {
    long x, y, z;
    char reserved[26];
    short lotag;
    char tail[4];
} SavedBoardSprite;
typedef struct { long x, y, z; } SavedActorPosition;
#pragma pack(pop)

extern SavedBoardSprite sprite[];
extern SavedActorPosition saved_actor_positions[];
extern short saved_actor_lotag[];
extern int restore_count;
extern long *restore_addresses[], restore_values[];

extern short first_player_sprite, holding_sprite, held_sprite;
extern short actor_sprite[];
extern signed char actor_active[];
extern unsigned char actor_level[];
extern const char level_names[][20], save_error[];
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
#pragma aux hold_invalid_sprite = parm [esi] value [esi] modify exact [];
extern short hold_actor_sprite(short);
#pragma aux hold_actor_sprite = parm [ax] value [ax] modify exact [];

/* The actor path passes its already sign-extended sprite index in EAX. */
extern int delete_actor_sprite(int);
#pragma aux delete_actor_sprite "deletesprite_" parm [eax] modify exact [eax];

int save_level_and_load_board(short level, const char *extension)
{
    char filename[80];
    int actor;

    deletesprite(first_player_sprite);
    if (holding_sprite)
        deletesprite(held_sprite);
    if (level) {
        actor = 0;
        goto check_actor;
        do {
            if (actor_active[actor] != -1 && (short)actor_level[actor] == level) {
                int slot = hold_actor_sprite(actor_sprite[actor]);
                saved_actor_positions[actor].x = sprite[slot].x;
                saved_actor_positions[actor].y = sprite[slot].y;
                {
                    long z = sprite[slot].z;
                    short lotag = sprite[slot].lotag;
                    saved_actor_positions[actor].z = z;
                    saved_actor_lotag[actor] = lotag;
                }
                delete_actor_sprite(slot);
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
                report_game_error(save_error);
            ++actor;
        check_slot:
            ;
        } while (actor <= 500);
    }
    /* Revert transient changes before writing the board. */
    for (actor = restore_count - 1; actor >= 0; --actor)
        *restore_addresses[actor] = restore_values[actor];
    /* The shared board writer records the remaining sprites in the new file. */
    strcpy(filename, level_names[level]);
    strcat(filename, extension);
    return save_build_map(filename, player_x, player_y, player_z, player_angle, player_sector);
}
