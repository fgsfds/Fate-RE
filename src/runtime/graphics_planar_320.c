extern unsigned short pixel_bit_offset, pixel_color, pixel_selector, current_buffer_selector, pixel_mask;
extern unsigned long pixel_address, current_buffer_offset;

extern short planar_x_in_si(short x);
#pragma aux planar_x_in_si = "" parm [si] value [si] modify exact [];
extern int planar_offset_in_eax(int offset);
#pragma aux planar_offset_in_eax = "" parm [eax] value [eax] modify exact [];
extern int planar_column_in_ecx(int x);
#pragma aux planar_column_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern short load_selector_in_dx(short selector);
#pragma aux load_selector_in_dx = "" parm [dx] value [dx] modify exact [];
/* Reserve DX for the selector load following the mask initialization. */
extern int mask_in_eax(int mask);
#pragma aux mask_in_eax = "" parm [eax] value [eax] modify exact [edx];
extern unsigned long address_ready(unsigned long address);
#pragma aux address_ready = "" parm [eax] value [eax] modify exact [];

/* This mode wraps the pixel offset at 16 bits. */
extern int truncated_offset_in_eax(unsigned short offset);
#pragma aux truncated_offset_in_eax = "" parm [eax] value [eax] modify exact [];

/* Watcom shares the common tail between these two entry points. */
#define DEFINE_PLANAR_PIXEL_ADDRESS(name, scanline_bytes)                \
void name(short x, short y, short color)                                 \
{                                                                        \
    int offset, column;                                                  \
    short bit;                                                           \
    unsigned long address;                                               \
    unsigned short selector;                                             \
    int mask;                                                            \
                                                                         \
    x = planar_x_in_si(x);                                               \
    offset = planar_offset_in_eax(planar_column_in_ecx(y) * (scanline_bytes)); \
    column = x >> 3;                                                     \
    offset = planar_offset_in_eax(offset + column);                      \
    *(volatile unsigned short *)&pixel_color = color;                    \
    offset = truncated_offset_in_eax(offset);                            \
    bit = x & 7;                                                         \
    address = offset + current_buffer_offset;                            \
    column = bit;                                                        \
    *(volatile unsigned long *)&pixel_address = address_ready(address);  \
    mask = mask_in_eax(0x80);                                            \
    selector = load_selector_in_dx(*(volatile unsigned short *)&current_buffer_selector); \
    mask >>= column;                                                     \
    pixel_selector = selector;                                           \
    mask <<= 8;                                                          \
    pixel_bit_offset = bit;                                              \
    pixel_mask = mask;                                                   \
}

DEFINE_PLANAR_PIXEL_ADDRESS(address_planar_pixel_320, 40)
DEFINE_PLANAR_PIXEL_ADDRESS(address_planar_pixel_640, 80)

#undef DEFINE_PLANAR_PIXEL_ADDRESS

extern const unsigned char two_plane_color_map[];
extern unsigned short mapped_in_ax(unsigned short color);
#pragma aux mapped_in_ax = "" parm [ax] value [ax] modify exact [];

void address_two_plane_pixel(short x, short y, short color)
{
    int offset, row, count, color_index;
    short column;
    short bit;
    unsigned long address;
    unsigned short selector, mapped;
    int mask;

    column = planar_x_in_si(x);
    row = planar_column_in_ecx(planar_column_in_ecx(y) * 80);
    offset = planar_offset_in_eax(x) >> 3;
    offset = truncated_offset_in_eax(offset + row);
    bit = column & 7;
    address = offset + current_buffer_offset;
    count = bit;
    pixel_address = address_ready(address);
    mask = (0x80 >> count) << 8;
    selector = load_selector_in_dx(*(volatile unsigned short *)&current_buffer_selector);
    pixel_mask = mask;
    color_index = planar_offset_in_eax(color);
    /* Publish the bit offset before reading the plane color map. */
    *(volatile unsigned short *)&pixel_bit_offset = bit;
    mapped = mapped_in_ax(two_plane_color_map[color_index]);
    pixel_selector = selector;
    pixel_color = mapped;
}
