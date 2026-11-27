extern const volatile unsigned char character_types[];
extern const long small_text_character_widths[];
extern long window_bottom, window_top, window_right, window_left;

extern unsigned status_strlen(const unsigned char *);
#pragma aux status_strlen "strlen_" modify exact [eax];
extern unsigned measure_text_and_reset_index(const unsigned char *);
#pragma aux measure_text_and_reset_index = \
    "call status_strlen" \
    "xor edi, edi" \
    parm [eax] value [eax] modify exact [eax edi];
extern int current_text_index(void);
#pragma aux current_text_index = parm [] value [edi] modify exact [];
extern void rotatesprite(long, long, long, short, short, signed char, unsigned char,
                         unsigned char, long, long, long, long);
#pragma aux rotatesprite modify exact [eax ebx ecx edx];

/* Preserve the byte-sized character masks and the incoming text register. */
extern unsigned char keep_alpha_mask(unsigned char);
#pragma aux keep_alpha_mask = parm [cl] value [cl] modify exact [];
extern unsigned char keep_digit_mask(unsigned char);
#pragma aux keep_digit_mask = parm [dl] value [dl] modify exact [];

extern const unsigned char *keep_small_text(const unsigned char *);
#pragma aux keep_small_text = parm [ecx] value [ecx] modify exact [];

/* Watcom pushes the viewport bounds and flags before this adapter.
 * The saved Y and shade fields are then at ESP+20 and ESP+28.
 * rotatesprite consumes all eight stack arguments and preserves X in ESI.
 */
extern long draw_small_glyph(long, unsigned long, unsigned, long, long, long, long);
#pragma aux draw_small_glyph = \
    "movsx eax, byte ptr [esp+1ch]" \
    "mov edx, dword ptr [esp+14h]" \
    "push 0" \
    "shl edx, 16" \
    "push eax" \
    "movsx eax, bx" \
    "xor ecx, ecx" \
    "push eax" \
    "mov eax, esi" \
    "mov ebx, 10000h" \
    "shl eax, 16" \
    "call rotatesprite" \
    parm routine [esi] [ebx] [] value [esi] modify exact [eax ebx ecx edx];

void draw_small_tile_text(long x, long y, long shade, const unsigned char *text, int spacing);
#pragma aux draw_small_tile_text parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
void draw_small_tile_text(long x, long y, long shade, const unsigned char *text, int spacing)
{
    struct {
        long y;
        long length;
        long shade;
        const unsigned char *text;
    } saved;
    int index;
    unsigned length;

    /* Keep these frame slots in the layout used by the renderer adapter. */
    *(volatile long *)&saved.y = y;
    *(volatile long *)&saved.shade = shade;
    *(const unsigned char * volatile *)&saved.text = text;
    length = measure_text_and_reset_index(keep_small_text(text));
    index = current_text_index();
    saved.length = length;

    for (; index < saved.length; ++index) {
        const unsigned char *character = saved.text + index;
        unsigned long tile = 0;
        unsigned char type_index = *character + 1;
        unsigned alpha = keep_alpha_mask(character_types[type_index] & 0xc0);
        if (alpha) {
            tile = *character + 0x7c4;
        } else {
            unsigned digit;
            digit = keep_digit_mask(character_types[type_index] & 0x20);
            if (digit) {
                tile = *character + 0x7c9;
            } else {
                x += small_text_character_widths[spacing];
            }
        }

        if (tile != 0) {
            x = draw_small_glyph(x, tile, 0x92, window_left, window_top,
                                window_right, window_bottom);
            x += small_text_character_widths[spacing];
        }
    }
}
