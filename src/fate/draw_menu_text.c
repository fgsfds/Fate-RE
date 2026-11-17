/* Draw menu text with either the palette-font renderer or a shadow pass. */
/* Keep the original callback registers while calculating the draw arguments. */
extern long value_in_eax(long);
#pragma aux value_in_eax = "" parm [eax] value [eax] modify exact [];
extern long value_in_ebx(long);
#pragma aux value_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern long value_in_ecx(long);
#pragma aux value_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern void clear_alpha_register(void);
#pragma aux clear_alpha_register = "xor ecx,ecx" modify exact [ecx];
extern void load_alpha_low_byte(unsigned char);
#pragma aux load_alpha_low_byte = "" parm [cl] modify exact [];
extern long value_in_edx(long);
#pragma aux value_in_edx = "" parm [edx] value [edx] modify exact [];
extern long x_coordinate(void);
#pragma aux x_coordinate = "" value [edi] modify exact [];
extern long y_coordinate(void);
#pragma aux y_coordinate = "" value [edx] modify exact [];
extern long value_eax(void);
#pragma aux value_eax = "" value [eax] modify exact [];
extern long value_ebx(void);
#pragma aux value_ebx = "" value [ebx] modify exact [];
extern long value_ecx(void);
#pragma aux value_ecx = "" value [ecx] modify exact [];
extern void push_eax(long);
#pragma aux push_eax = "push eax" parm [eax] modify exact [];
extern void push_zero(void);
#pragma aux push_zero = "push 0" modify exact [];

extern long keep_x(long);
#pragma aux keep_x = parm [edi] value [edi] modify exact [];

extern const volatile unsigned char character_types[];
extern long menu_font_zoom[], small_text_character_widths[];
extern long presentation_height, presentation_width;

extern unsigned status_strlen(const unsigned char *);
#pragma aux status_strlen "strlen_" modify exact [eax esi];
extern void rotatesprite(long, long, long, short, short, signed char, unsigned char,
                         unsigned char, long, long, long, long);
#pragma aux rotatesprite modify exact [eax ebx ecx edx];
extern int menu_glyph_tile(unsigned char);
#pragma aux menu_glyph_tile modify exact [eax];
extern int draw_screen_text(long, long, long, long, const unsigned char *, long);
#pragma aux draw_screen_text modify exact [eax ebx ecx edx];
extern unsigned char boolean_in_al(unsigned char);
#pragma aux boolean_in_al = "" parm [al] value [al] modify exact [];
/* Draw the shadow and foreground with their original register/stack ABI. */
extern void push_text_for_shadow(const unsigned char *);
#pragma aux push_text_for_shadow = "push ecx" parm [ecx] modify exact [];
extern void store_foreground_shade(long);
#pragma aux store_foreground_shade = "mov [esp+14h],eax" parm [eax] modify exact [];
extern void read_foreground_arguments(void);
#pragma aux read_foreground_arguments = "mov ecx,[esp+0ch]" "mov edx,[esp+8]" modify exact [ebx ecx edx];
extern long foreground_shade(void);
#pragma aux foreground_shade = "mov ecx,[esp+14h]" value [ecx] modify exact [ecx];
extern int call_screen_text(long, long, long, long);
#pragma aux call_screen_text "draw_screen_text_" parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void release_menu_text_frame(void);
#pragma aux release_menu_text_frame = "add esp, 14h" modify exact [];
extern void small_text_return(void);
#pragma aux small_text_return aborts modify exact [];

extern unsigned char keep_alpha_mask(unsigned char);
#pragma aux keep_alpha_mask = parm [cl] value [cl] modify exact [];
extern unsigned char keep_digit_mask(unsigned char);
#pragma aux keep_digit_mask = parm [bl] value [bl] modify exact [];
extern int keep_index(int);
#pragma aux keep_index = parm [esi] value [esi] modify exact [];

extern const unsigned char *incoming_text(void);
#pragma aux incoming_text = value [ecx] modify exact [];
extern long width_in_edx(long);
#pragma aux width_in_edx = parm [edx] value [edx] modify exact [];

extern void used_digit(unsigned);
#pragma aux used_digit = parm [ebx] modify exact [];
/* EDI keeps the x position and EBP keeps the font in the text frame. */
extern void paint_menu_glyph(unsigned long);
#pragma aux paint_menu_glyph = \
    "push 0" "push 0" "push 12h" "mov ebx,dword ptr menu_font_zoom[ebp*4]" \
    "push 0" "movsx eax,byte ptr [esp+24h]" "xor ecx,ecx" "push eax" \
    "movsx eax,dx" "mov edx,[esp+20h]" "push eax" "mov eax,edi" \
    "shl edx,10h" "shl eax,10h" "call rotatesprite" \
    parm [edx] modify exact [eax ebx ecx edx];

extern const unsigned char *initial_text_for_index(const unsigned char *);
#pragma aux initial_text_for_index = parm [eax] value [eax] modify exact [];

void draw_menu_text(long x, long y, long shade, const unsigned char *text, int font);
#pragma aux draw_menu_text parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
void draw_menu_text(long x, long y, long shade, const unsigned char *text, int font)
{
    /* The shadow pass and palette-glyph setup share these frame slots. */
    struct {
        long length, y;
        const unsigned char *text;
        long shade;
        volatile unsigned char alpha;
    } saved;
    int index;
    x = keep_x(x);
    saved.y = y;
    saved.shade = shade;
    saved.text = text;
    if (font == 2) {
        long foreground;
        boolean_in_al(shade == -1);
        push_zero();
        foreground = value_in_eax((unsigned long)value_eax() & 0xff);
        value_in_ebx(0x60);
        foreground = value_in_eax(foreground - 1);
        push_text_for_shadow(incoming_text());
        value_in_ecx(-1);
        store_foreground_shade(foreground);
        call_screen_text(value_in_eax(x_coordinate()), y_coordinate(), value_ebx(), value_ecx());
        push_zero();
        read_foreground_arguments();
        value_in_ebx(0x70);
        value_in_eax(x_coordinate() - 1);
        push_text_for_shadow(incoming_text());
        value_in_edx(y_coordinate() - 1);
        call_screen_text(value_eax(), y_coordinate(), value_ebx(), foreground_shade());
    } else {
        long length = status_strlen(incoming_text());
        index = keep_index(0);
        saved.length = length;
        for (; index < saved.length; index = keep_index(index + 1)) {
            const unsigned char *character = initial_text_for_index(saved.text);
            unsigned long tile = 0;
            character += index;
            if (font == 0) {
                tile = menu_glyph_tile(*character);
            } else {
                unsigned digit;
                unsigned char type_index = *character + 1;
                saved.alpha = keep_alpha_mask(character_types[type_index] & 0xc0);
                clear_alpha_register();
                load_alpha_low_byte(saved.alpha);
                if (value_ecx()) {
                    tile = *character + 0x7c4;
                } else if ((digit = (unsigned)keep_digit_mask(character_types[type_index] & 0x20))) {
                    used_digit(digit);
                    tile = *character + 0x7c9;
                }
            }
            if (tile != 0) {
                push_eax(value_in_eax(presentation_height) - 1);
                push_eax(value_in_eax(presentation_width) - 1);
                paint_menu_glyph(tile);
            }
            x += width_in_edx(small_text_character_widths[font]);
        }
    }
    release_menu_text_frame();
    small_text_return();
}
