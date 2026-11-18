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
/* The short sign branch skips exactly the following compiler-emitted NEG. */
extern unsigned long skip_nonnegative_distance(unsigned long);
#pragma aux skip_nonnegative_distance = "test eax,eax" "db 79h, 02h" /* marker-rel8 0,+1 */ parm nomemory [eax] value [eax] modify exact [];
extern unsigned long distance_in_eax(unsigned long);
#pragma aux distance_in_eax = parm [eax] value [eax] modify exact [];
extern unsigned long distance_in_edx(unsigned long);
#pragma aux distance_in_edx = parm [edx] value [edx] modify exact [];
extern unsigned long coordinate_in_ecx(unsigned long);
#pragma aux coordinate_in_ecx = parm [ecx] value [ecx] modify exact [];

void play_crusher_sound(const CrusherPosition *crusher, int mode)
{
    int sound;
    unsigned long x_distance, y_distance;

    if (!crusher)
        report_game_error(null_crusher_sound);
    /* Both crusher modes use sample 4. Watcom retains the mode comparison. */
    sound = hold_sound_index(mode == 1 ? 4 : 4);
    /* Use unsigned subtraction/negation to retain 32-bit wrapping, even at LONG_MIN. */
    x_distance = skip_nonnegative_distance((unsigned long)player_x[0] - (unsigned long)crusher->x);
    x_distance = distance_in_edx(distance_in_eax(0UL - x_distance));
    y_distance = skip_nonnegative_distance((unsigned long)player_y[0] - coordinate_in_ecx((unsigned long)crusher->y));
    y_distance = distance_in_eax(0UL - y_distance);
    /* Watcom reinterprets the wrapped sum as a signed 32-bit value. */
    if ((long)(y_distance + x_distance) < 8674)
        play_sound(sound, crusher->x, crusher->y, 0);
}
