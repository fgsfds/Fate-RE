/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

extern long current_brightness, brightness_video_mode;
extern unsigned char *palookup[];
extern unsigned char brightness_table[];

/* The shared return consumes this register frame and shade slot. */
extern long begin_brightness(long level, const unsigned char *rgb);
#pragma aux begin_brightness = "push ebx" "push ecx" "push esi" "push edi" "push ebp" \
    "sub esp,4" "mov edi,edx" parm [eax] [edx] value [eax] modify exact [edi];
extern long brightness_in_eax(long level);
#pragma aux brightness_in_eax = "" parm [eax] value [eax] modify exact [];
extern long stored_brightness(void);
#pragma aux stored_brightness = value [eax] modify exact [];
extern long zero_brightness(void);
#pragma aux zero_brightness = "xor ebx,ebx" value [ebx] modify exact [ebx];

extern void begin_ega_shades(void);
#pragma aux begin_ega_shades = "mov ebp,0fh" "xor ecx,ecx" modify exact [ecx];
extern long shade_color(void);
#pragma aux shade_color = value [ecx] modify exact [];
extern long shade_level(void);
#pragma aux shade_level = value [ebx] modify exact [];
extern void next_shade_color(void);
#pragma aux next_shade_color = "inc ecx" modify exact [ecx];
/* Keep half the RGB sum in ESI and the current shade-table column in EAX. */
extern void begin_color_shades(void);
#pragma aux begin_color_shades = "mov eax,ecx" "shl eax,2" "mov edx,ecx" "sub eax,ecx" \
    "xor edx,ecx" "xor ebx,ebx" "mov dl,[edi+eax*1+1]" "mov bl,[edi+eax]" \
    "movzx esi,byte ptr [edi+eax*1+2]" "add edx,ebx" "mov eax,palookup" \
    "add esi,edx" "add eax,ecx" "xor ebx,ebx" "sar esi,1" modify exact [eax ebx edx esi];
extern long shade_intensity(void);
#pragma aux shade_intensity = value [esi] modify exact [];
extern long save_ega_shade(long shade);
#pragma aux save_ega_shade = "mov [esp],edx" parm [edx] value [edx] modify exact [];
extern void limit_ega_shade(void);
#pragma aux limit_ega_shade = "mov [esp],ebp" modify exact [];
extern void write_ega_shade(void);
#pragma aux write_ega_shade = "mov dl,[esp]" "inc ebx" "mov [eax],dl" \
    "add eax,100h" modify exact [eax ebx edx];

extern void set_dac_index_zero(void);
#pragma aux set_dac_index_zero = "mov edx,3c8h" "xor eax,eax" "out dx,al" modify exact [eax edx];
extern void begin_dac_rows(void);
#pragma aux begin_dac_rows = "xor ebx,ebx" modify exact [ebx];
extern void begin_dac_colors(void);
#pragma aux begin_dac_colors = "xor ecx,ecx" modify exact [ecx];
extern long dac_row(void);
#pragma aux dac_row = value [ebx] modify exact [];
extern long dac_column(void);
#pragma aux dac_column = value [ecx] modify exact [];
extern void next_dac_row(void);
#pragma aux next_dac_row = "inc ebx" modify exact [ebx];
extern void next_dac_column(void);
#pragma aux next_dac_column = "inc ecx" modify exact [ecx];
extern void write_ega_red(void);
#pragma aux write_ega_red = "mov eax,current_brightness" "mov edx,ecx" "shl eax,6" \
    "mov al,[eax+edx*4+brightness_table]" "mov edx,3c9h" "and eax,0ffh" "out dx,al" \
    modify exact [eax edx];
extern void write_ega_green(void);
#pragma aux write_ega_green = "xor eax,eax" "out dx,al" modify exact [eax];
extern void write_ega_blue(void);
#pragma aux write_ega_blue = "mov edx,current_brightness" "mov eax,ebx" "shl edx,6" \
    "mov al,[edx+eax*4+brightness_table]" "mov edx,3c9h" "and eax,0ffh" "out dx,al" \
    modify exact [eax edx];
extern void write_rgb_channel(void);
#pragma aux write_rgb_channel = "mov al,[ecx+edi]" "mov edx,current_brightness" \
    "and eax,0ffh" "shl edx,6" "mov al,[edx+eax*1+brightness_table]" "mov edx,3c9h" \
    "and eax,0ffh" "out dx,al" modify exact [eax edx];
extern void finish_ega_brightness(void);
#pragma aux finish_ega_brightness aborts modify exact [];
extern void finish_rgb_brightness(void);
#pragma aux finish_rgb_brightness aborts modify exact [];
#pragma aux setbrightness modify exact [eax ebx ecx edx esi edi];

void setbrightness(long level, const unsigned char *rgb)
{
    current_brightness = brightness_in_eax(begin_brightness(level, rgb) & 255);
    if (stored_brightness() < 0)
        current_brightness = zero_brightness();
    if (current_brightness > 15)
        current_brightness = 15;
    if (brightness_video_mode != 7)
        goto rgb_dac;

    /* Video mode 7 builds a 32-level shade table for the 16-color renderer. */
    begin_ega_shades();
    goto check_shade_color;
    do {
        begin_color_shades();
        goto check_shade_level;
        do {
            long shade = ((31 - shade_level()) * shade_intensity()) >> 7;

            if (save_ega_shade(shade) > 15)
                limit_ega_shade();
            write_ega_shade();
check_shade_level:;
        } while (shade_level() < 32);
        next_shade_color();
check_shade_color:;
    } while (shade_color() < 256);

    set_dac_index_zero();
    /* Red and blue span a 16-by-16 grid with green fixed at zero. */
    begin_dac_rows();
    goto check_dac_row;
    do {
        begin_dac_colors();
        goto check_dac_column;
        do {
            write_ega_red();
            write_ega_green();
            write_ega_blue();
            next_dac_column();
check_dac_column:;
        } while (dac_column() < 16);
        next_dac_row();
check_dac_row:;
    } while (dac_row() < 16);
    finish_ega_brightness();

rgb_dac:
    set_dac_index_zero();
    begin_dac_colors();
    goto check_rgb;
    do {
        write_rgb_channel();
        next_dac_column();
check_rgb:;
    } while (dac_column() < 768);
    finish_rgb_brightness();
}
