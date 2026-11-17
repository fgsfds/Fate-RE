#pragma pack(push, 1)
typedef struct {
    char before_position[41];
    long x, y;
} CrusherPosition;
#pragma pack(pop)

extern long player_x[], player_y[];
extern const char null_crusher_sound[];
extern void report_game_error(const char *);
#pragma aux report_game_error modify exact [eax];
extern void play_sound(int sound, long x, long y, int repeat);
#pragma aux play_sound modify exact [eax];
extern int hold_sound_index(int);
#pragma aux hold_sound_index = parm [esi] value [esi] modify exact [];

/* klabs from Build Engine & Tools, Copyright (c) 1993-1997 Ken Silverman.
 * See ../engine/BUILDLIC.TXT.
 */
extern long klabs(long);
#pragma aux klabs = "test eax, eax" "jns skipnegate" "neg eax" "skipnegate:" parm nomemory [eax] modify exact [eax];

void play_crusher_sound(const CrusherPosition *crusher, int mode)
{
    int sound;
    long x_distance, y_distance;

    if (!crusher)
        report_game_error(null_crusher_sound);
    /* Both crusher modes use sample 4. Watcom retains the mode comparison. */
    sound = hold_sound_index(mode == 1 ? 4 : 4);
    x_distance = klabs(player_x[0] - crusher->x);
    y_distance = klabs(player_y[0] - crusher->y);
    if (x_distance + y_distance < 8674)
        play_sound(sound, crusher->x, crusher->y, 0);
}
