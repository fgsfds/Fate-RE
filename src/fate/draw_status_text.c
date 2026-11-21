extern void rotatesprite(long, long, long, short, short, signed char, unsigned char,
                         unsigned char, long, long, long, long);
#pragma aux rotatesprite modify exact [eax edx ebx ecx];

/* Preserve the original Watcom registers for the address and character. */
extern unsigned char hold_glyph(unsigned char);
#pragma aux hold_glyph = parm [dl] value [dl] modify exact [];
extern const unsigned char *hold_message(const unsigned char *);
#pragma aux hold_message = parm [eax] value [eax] modify exact [];

void draw_status_message(long, long, const unsigned char *, long, long);
#pragma aux draw_status_message parm routine [eax] [edx] [ebx] [ecx] modify exact [eax edx ebx ecx];
void draw_status_message(long x, long y, const unsigned char *message, long tile, long unused)
{
    int index = 0;
    unsigned char glyph;
    unsigned char character;
    long right, bottom;

    (void)unused;
    goto check;
    do {
        glyph = hold_glyph(character);
        /* Draw the background cell, then offset the font tile to select the glyph. */
        rotatesprite((x - 64) * 65536L, y * 65536L, 65536L, 0, tile, 0, 0, 0xd8,
                     x, y, right = x + 7, bottom = y + 7);
        rotatesprite((x - (glyph & 15) * 8) * 65536L, (y - (glyph >> 4) * 8) * 65536L, 65536L, 0, tile,
                     0, 0, 0x98, x, y, right, bottom);
        x += 8;
        ++index;
check:
        character = hold_glyph(*hold_message(message + index));
    } while (character);
}
