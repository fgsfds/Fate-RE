extern void rotatesprite(long x, long y, long zoom, short angle, short tile,
                         signed char shade, unsigned char palette, unsigned char flags,
                         long left, long top, long right, long bottom);
#pragma aux rotatesprite modify exact [eax edx ebx ecx];
extern short sintable[];
extern long window_left, window_top, window_right, window_bottom;
extern long weapon_bob_angle, weapon_bob_scale, weapon_bob_limit;
extern unsigned char weapon_idle;
extern long hold_tile(long);
#pragma aux hold_tile = parm [esi] value [esi] modify exact [];

extern long next_y(long);
#pragma aux next_y = parm [edx] value [edx] modify exact [];
extern long use_sine_and_scale(long, long);
#pragma aux use_sine_and_scale = parm [eax] [edx] value [eax] modify exact [];

/* Shade setup also places the horizontal origin in ECX. */
extern int hold_shade_and_x(int, int);
#pragma aux hold_shade_and_x = parm [eax] [ecx] value [eax] modify exact [];
extern int reuse_weapon_x(void);
#pragma aux reuse_weapon_x = value [ecx] modify exact [];

/* Convert the overlay's origins to 16.16 drawing coordinates. The renderer
 * pops the seven stack arguments supplied by C and the tile pushed here. */
extern void draw_scaled_weapon(int x, int y, int bob, long tile, int shade, int palette, int flags,
                               long left, long top, long right, long bottom);
#pragma aux draw_scaled_weapon = \
    "mov ebx, 10000h" \
    "add edx, eax" \
    "mov eax, [weapon_bob_angle]" \
    "push esi" \
    "sar eax, 8" \
    "add edx, 9" \
    "add eax, ecx" \
    "shl edx, 16" \
    "sub eax, 10h" \
    "xor ecx, ecx" \
    "shl eax, 16" \
    "call rotatesprite" \
    parm routine [ecx] [eax] [edx] [esi] modify exact [eax ebx ecx edx];

void draw_weapon_overlay(long tile, int unused, int movement, int running, int x, int y);
#pragma aux draw_weapon_overlay parm routine [eax] [edx] [ebx] [ecx] modify exact [eax edx ebx ecx];
void draw_weapon_overlay(long tile, int unused, int movement, int running, int x, int y)
{
    volatile signed char shade = -64;
    int bob;

    tile = hold_tile(tile);
    if (running)
        weapon_bob_limit = 144;
    else
        weapon_bob_limit = 64;
    weapon_idle = !movement;
    {
        long wave = *(volatile short *)(sintable + (weapon_bob_angle & 2047));
        long scale = *(volatile long *)&weapon_bob_scale;
        bob = next_y(scale * (use_sine_and_scale(wave, scale) >> 11));
    }
    draw_scaled_weapon(reuse_weapon_x(), y, bob, tile, hold_shade_and_x(shade, x), 0, 18,
                       window_left, window_top, window_right, window_bottom);
}
