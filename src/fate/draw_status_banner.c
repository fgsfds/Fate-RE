extern const volatile unsigned char character_types[];
extern unsigned char *active_text_message;
extern long status_character_width;
extern long window_bottom, window_top, window_right, window_left;

extern unsigned status_strlen(const unsigned char *);
#pragma aux status_strlen "strlen_" modify exact [eax];
extern void rotatesprite(long, long, long, short, short, signed char, unsigned char,
                         unsigned char, long, long, long, long);
#pragma aux rotatesprite modify exact [eax ebx ecx edx];
/* This entry shares its four-byte stack cleanup with the animated intro. */
extern void release_banner_frame(void);
#pragma aux release_banner_frame = "add esp, 4" modify exact [];
extern void restore_saved_registers(void);
#pragma aux restore_saved_registers aborts modify exact [];

/* Preserve the byte masks from the Watcom character classification table. */
extern unsigned char keep_alpha_mask(unsigned char);
#pragma aux keep_alpha_mask = parm [cl] value [cl] modify exact [];
extern unsigned char keep_digit_mask(unsigned char);
#pragma aux keep_digit_mask = parm [bl] value [bl] modify exact [];


extern void retain_alpha(unsigned);
#pragma aux retain_alpha = parm [ecx] modify exact [];
void draw_status_banner(void)
{
    volatile long length = status_strlen(active_text_message);
    long x = 160 - ((status_strlen(active_text_message) * status_character_width) >> 1);
    long index;

    for (index = 0; index < length; ++index) {
        const unsigned char *character = active_text_message + index;
        unsigned long tile = 0;
        unsigned char type_index = *character + 1;
        unsigned alpha = keep_alpha_mask(character_types[type_index] & 0xc0);
        if (alpha) {
            tile = *character + 0x816;
        } else {
            unsigned digit;
            retain_alpha(alpha);
            digit = keep_digit_mask(character_types[type_index] & 0x20);
            if (digit) {
                tile = *character + 0x7c9;
            } else {
                x += status_character_width;
            }
        }

        if (tile != 0) {
            rotatesprite((long)((unsigned long)x << 16), 54L * 65536L, 65536, 0, tile, -64, 0, 0x92,
                         window_left, window_top, window_right, window_bottom);
            x += status_character_width;
        }
    }

    release_banner_frame();
    restore_saved_registers();
}
