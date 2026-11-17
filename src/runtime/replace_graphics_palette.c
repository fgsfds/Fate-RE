extern short adapter_class, palette_size, graphics_error, video_mode;
extern unsigned char graphics_active;
extern long read_previous_palette_entry(short index);
#pragma aux read_previous_palette_entry "read_palette_entry_" modify exact [eax];
/* Preserve the palette write call argument setup order. */
extern void write_palette_color_first(long rgb, short index);
#pragma aux write_palette_color_first "write_palette_entry_" parm [edx] [eax] modify exact [eax edx];
extern void upload_palette_for_mode(const long *colors, short count);
#pragma aux upload_palette_for_mode "upload_palette_entries_" modify exact [eax edx];

long replace_palette_entry(short index, long rgb)
{
    long previous;
    if (index < 0 || index >= palette_size) {
        graphics_error = -4;
        return -1;
    }
    if (adapter_class < 4) {
        graphics_error = -1;
        return -1;
    }
    previous = read_previous_palette_entry(index);
    write_palette_color_first(rgb, index);
    return previous;
}

long replace_palette(const long *colors)
{
    short count;
    if (adapter_class < 4 || video_mode == 7 || video_mode == 15) {
        graphics_error = -1;
        return 0;
    }
    if (graphics_active)
        count = palette_size;
    else
        count = 16;
    upload_palette_for_mode(colors, count);
    return -1;
}

extern long background_color;
extern unsigned char text_attribute;
extern long replace_palette_color_first(long color, short index);
#pragma aux replace_palette_color_first "replace_palette_entry_" parm [edx] [eax] modify exact [eax edx];
extern long find_legacy_palette_index(long color);
#pragma aux find_legacy_palette_index modify exact [eax];
/* CGA BIOS background-color service. */
extern void bios_set_background(int service, long index, int dx, int cx);
#pragma aux bios_set_background = "push bp" "int 10h" "pop bp" parm [eax] [ebx] [edx] [ecx] modify exact [eax ebx ecx edx];

long set_background_color(long color)
{
    long previous = background_color;
    background_color = color;
    if (graphics_active) {
        if (adapter_class == 2 && video_mode != 6)
            bios_set_background(0xb00, find_legacy_palette_index(color), 0, 0);
        else
            replace_palette_color_first(color, 0);
    } else {
        unsigned char index = find_legacy_palette_index(color) & 7;
        text_attribute &= 0x8f;
        text_attribute |= index << 4;
    }
    return previous;
}

/* Keep the fallback loop palette pointer in its original register. */
extern const long *colors_in_ebx(const long *colors);
#pragma aux colors_in_ebx = "" parm [ebx] value [ebx] modify exact [];
/* The compiler treats ECX as scratch during the fallback loop. */
extern void write_palette_fallback(short index, long rgb);
#pragma aux write_palette_fallback "write_palette_entry_" modify exact [eax edx ecx];
extern short upload_bios_palette(const long *colors, short count);
#pragma aux upload_bios_palette modify exact [eax edx];

#pragma aux upload_palette_entries modify exact [eax edx ecx];
void upload_palette_entries(const long *colors, short count)
{
    short i;
    colors = colors_in_ebx(colors);
    if (adapter_class != 5 && upload_bios_palette(colors, count))
        return;
    for (i = 0; i < count; i++)
        write_palette_fallback(i, colors[i]);
}

/* The fallback path preserves the color carried in EBX. */
extern long incoming_palette_value(void);
#pragma aux incoming_palette_value = value [ebx] modify exact [];
extern long palette_value_in_ebx(long value);
#pragma aux palette_value_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern long read_dac_color(int service, short index);
#pragma aux read_dac_color = "push ebp" "int 10h" "pop ebp" "xchg ch,cl" "movzx eax,cx" "shl eax,8" 0x8a 0xc6 parm [eax] [ebx] value [eax] modify exact [eax ebx ecx edx];

long read_palette_entry(short index)
{
    long rgb;
    unsigned short adapter;

    rgb = incoming_palette_value();
    adapter = (unsigned short)adapter_class;
    switch (adapter) {
    case 4:
    case 6:
    case 7:
        rgb = read_dac_color(0x1015, index);
        break;
    case 5:
        rgb = 0;
        break;
    }
    return palette_value_in_ebx(rgb);
}

/* The BIOS consumes separate DAC components in SI, DI, and DX. */
extern unsigned short unpack_palette_components(int index, long packed_rgb);
#pragma aux unpack_palette_components = "mov ecx,eax" "mov eax,edx" "mov edi,edx" "xor dl,dl" "movzx edx,dx" "mov bx,word ptr [adapter_class]" "sar edx,8" "and edi,0ff0000h" "mov esi,edx" "mov edx,eax" "shr edi,10h" "xor dh,dh" parm [eax] [edx] value [bx] modify exact [eax ebx ecx edx esi edi];
extern long packed_palette_rgb(void);
#pragma aux packed_palette_rgb = value [eax] modify exact [];
extern unsigned short palette_video_mode(void);
#pragma aux palette_video_mode = "mov bx,word ptr [video_mode]" value [bx] modify exact [ebx];
extern const unsigned char ega_component_bits[];

extern void prepare_dac_color(void);
#pragma aux prepare_dac_color = "mov eax,1010h" "shl esi,8" "shl edx,8" "add edi,esi" "mov ebx,ecx" "mov ecx,edi" modify exact [eax ebx ecx edx esi edi];
extern void prepare_ega_color(short color);
#pragma aux prepare_ega_color = "mov ebx,eax" "xor edx,edx" "shl ebx,8" "mov eax,1000h" "add ebx,ecx" "xor ecx,ecx" parm [ax] modify exact [eax ebx ecx edx];
extern void write_bios_palette(void);
#pragma aux write_bios_palette = "push bp" "int 10h" "pop bp" modify exact [eax ebx ecx edx];

/* The EGA lookup leaves the green contribution in AX while BX accumulates it. */
extern short prior_ega_level(void);
#pragma aux prior_ega_level = value [ax] modify exact [];
extern int green_nibble(void);
#pragma aux green_nibble = "shr si,4" "movzx eax,si" value [eax] modify exact [eax esi];
extern void shift_blue_nibble(void);
#pragma aux shift_blue_nibble = "shr di,4" modify exact [edi];
extern int blue_nibble(void);
#pragma aux blue_nibble = "movzx eax,di" value [eax] modify exact [eax];
extern void shift_red_nibble(void);
#pragma aux shift_red_nibble = "shr dx,4" modify exact [edx];
extern int red_nibble(void);
#pragma aux red_nibble = "movzx eax,dx" value [eax] modify exact [eax];
extern short green_component_accumulator(short green);
#pragma aux green_component_accumulator = "mov ebx,eax" parm [ax] value [bx] modify exact [ebx];
void write_palette_entry(int index, long rgb)
{
    unsigned short adapter, mode;
    short color;

    adapter = unpack_palette_components(index, rgb);

    if (adapter >= 5) {
        if (adapter <= 5)
            goto ega;
        if (adapter <= 7)
            goto dac;
        return;
    }
    if (adapter != 4)
        goto done;
dac:
    prepare_dac_color();
    goto bios_write;
ega:
    mode = palette_video_mode();
    if (mode == 0xd || mode == 0xe) {
        color = find_legacy_palette_index(packed_palette_rgb());
        if (color > 7)
            color |= 0x10;
    } else {
        unsigned short green, blue, red, color_pair;
        green = ega_component_bits[green_nibble()];
        color_pair = green_component_accumulator(green);
        shift_blue_nibble();
        color_pair += prior_ega_level();
        blue = ega_component_bits[blue_nibble()];
        shift_red_nibble();
        color_pair += blue;
        red = ega_component_bits[red_nibble()];
        color = (red << 2) + color_pair;
    }
    prepare_ega_color(color);
bios_write:
    write_bios_palette();
done:
    return;
}
