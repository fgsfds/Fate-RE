#pragma pack(push, 1)
typedef struct {
    long x, y, z;
    short cstat, picnum;
    signed char shade;
    unsigned char pal, clipdist, filler, xrepeat, yrepeat;
    signed char xoffset, yoffset;
    short sectnum, statnum, ang, owner, xvel, yvel, zvel, lotag, hitag, extra;
} GameSprite;
#pragma pack(pop)

extern GameSprite game_sprites[];
extern long status_right_tenths[], player_x[], player_y[];
extern short player_status_sprite[], viewed_player, status_minimum_width;
extern long presentation_height, presentation_width;
extern const char depleted_status_message[], active_status_format[];
extern char status_message_buffer[];
extern char status_depletion_sound[];

extern unsigned status_sound_random(void);
#pragma aux status_sound_random "krand_" modify exact [eax];
extern void play_positioned_sound(const char *, int, int, long *, long *, int);
#pragma aux play_positioned_sound parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void draw_status_message(long, long, const char *, int, int);
#pragma aux draw_status_message parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern int format_status_message(char *, const char *, ...);
#pragma aux format_status_message "sprintf_" parm caller [] modify exact [eax edx];
extern unsigned long status_message_length(const char *);
#pragma aux status_message_length "strlen_" modify exact [eax];
extern int hold_status_player_index(int);
#pragma aux hold_status_player_index = parm [edi] value [edi] modify exact [];
extern long hold_status_x(long);
#pragma aux hold_status_x = parm [eax] value [eax] modify exact [];

extern long status_in_ebx(long);
#pragma aux status_in_ebx = parm [ebx] value [ebx] modify exact [];
extern int status_change(int);
#pragma aux status_change = parm [edx] value [edx] modify exact [];
extern long status_sum(long, int);
#pragma aux status_sum = "lea ecx, [ebx + edx]" parm [ebx] [edx] value [ecx] modify exact [];
extern long hold_render_status(long);
#pragma aux hold_render_status = parm [edi] value [edi] modify exact [];
/* Center the formatted status label using the original renderer ABI. */
extern void render_status_label(int flags);
#pragma aux render_status_label = \
    "mov eax, offset status_message_buffer" \
    "mov ebx, offset status_message_buffer" \
    "mov edx, [presentation_height]" \
    "call status_message_length" \
    "mov ecx, eax" \
    "mov eax, [presentation_width]" \
    "shl ecx, 2" \
    "sar eax, 1" \
    "sub edx, 18h" \
    "sub eax, ecx" \
    "mov ecx, 49h" \
    "call draw_status_message" \
    parm routine [] modify exact [eax ebx ecx edx];

int adjust_player_status(short player, short change)
{
    long current;

    current = status_in_ebx(status_right_tenths[player]);
    if (current <= 0)
        goto check_depletion;

    current = status_sum(current, status_change(change));
    status_right_tenths[player] = current;
    if (current > 999)
        status_right_tenths[player] = 999;
    {
        int index = hold_status_player_index(player);
        if (status_right_tenths[index] <= 0) {
            status_right_tenths[index] = status_in_ebx(-1);
            play_positioned_sound(status_depletion_sound, 0xfc0 + (status_sound_random() & 127), 256,
                                  &player_x[index], &player_y[index], 1);
            game_sprites[player_status_sprite[index]].picnum = 0x71;
        }
    }

    if (player == viewed_player && status_minimum_width <= presentation_width) {
        long health = hold_render_status(*(long *)((char *)status_right_tenths
                      + hold_status_x(viewed_player * sizeof(long))));
        if (health > 0)
            format_status_message(status_message_buffer, active_status_format, health);
        else
            format_status_message(status_message_buffer, depleted_status_message);
        render_status_label(0x50);
    }

check_depletion:
    return status_right_tenths[player] <= 0;
}
