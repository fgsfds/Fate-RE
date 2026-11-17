extern unsigned short pixel_bit_offset, pixel_color, pixel_selector, current_buffer_selector;
extern unsigned long pixel_address, current_buffer_offset;

/* Keep the scanline product in EDX while adding the X coordinate. */
extern int coordinate_in_eax(int y);
#pragma aux coordinate_in_eax = "" parm [eax] value [eax] modify exact [];
extern int byte_offset_in_edx(int offset);
#pragma aux byte_offset_in_edx = "" parm [edx] value [edx] modify exact [];

void address_vga_byte_pixel(short x, short y, short color)
{
    int row_offset, column;
    unsigned long address;
    unsigned short selector;

    row_offset = byte_offset_in_edx(coordinate_in_eax(y) * 320);
    pixel_bit_offset = 0;
    column = x;
    pixel_color = color;
    address = column + row_offset;
    selector = current_buffer_selector;
    address += current_buffer_offset;
    pixel_selector = selector;
    pixel_address = address;
}

typedef void (*BankSelector)(short);
#pragma aux BankSelector modify exact [eax];
extern BankSelector bank_selector_callback;

extern void end_planar_drawing(void);
#pragma aux end_planar_drawing modify exact [eax];
void select_graphics_bank(short bank);

/* Keep this entry adjacent to the shared bank-selection body. */
void finish_banked_planar_drawing(void)
{
    end_planar_drawing();
    select_graphics_bank(0);
}

void select_graphics_bank(short bank)
{
    BankSelector selector;

    selector = bank_selector_callback;
    selector(bank);
}

extern void set_bank_for_pixel(short bank);
#pragma aux set_bank_for_pixel "select_graphics_bank_" modify exact [eax];
extern unsigned long address_in_edx(unsigned long address);
#pragma aux address_in_edx = "" parm [edx] value [edx] modify exact [];

/* Watcom shares the address and bank selection tail across these entry points. */
#define DEFINE_BANKED_BYTE_PIXEL_ADDRESS(name, scanline_bytes)                 \
void name(short x, short y, short color)                                       \
{                                                                              \
    int row_offset;                                                            \
    unsigned long address, offset;                                             \
    unsigned short selector;                                                   \
    short bank;                                                                \
                                                                               \
    row_offset = (long)y * (scanline_bytes);                                   \
    address = address_in_edx(row_offset + x);                                  \
    bank = address >> 16;                                                      \
    offset = address & 0xffff;                                                 \
    set_bank_for_pixel(bank);                                                  \
    pixel_bit_offset = 0;                                                      \
    selector = current_buffer_selector;                                        \
    pixel_color = color;                                                       \
    offset += current_buffer_offset;                                           \
    pixel_selector = selector;                                                 \
    pixel_address = offset;                                                    \
}

DEFINE_BANKED_BYTE_PIXEL_ADDRESS(address_banked_byte_pixel_640, 640)
DEFINE_BANKED_BYTE_PIXEL_ADDRESS(address_banked_byte_pixel_800, 800)
DEFINE_BANKED_BYTE_PIXEL_ADDRESS(address_banked_byte_pixel_1024, 1024)

#undef DEFINE_BANKED_BYTE_PIXEL_ADDRESS

extern unsigned short pixel_mask;

extern short planar_x_in_si(short x);
#pragma aux planar_x_in_si = "" parm [si] value [si] modify exact [];
extern int planar_offset_in_eax(int offset);
#pragma aux planar_offset_in_eax = "" parm [eax] value [eax] modify exact [];
extern int planar_column_in_ecx(int x);
#pragma aux planar_column_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern short load_selector_in_dx(short selector);
#pragma aux load_selector_in_dx = "" parm [dx] value [dx] modify exact [];
/* Reserve EDX until the buffer selector is read. */
extern int mask_in_eax(int mask);
#pragma aux mask_in_eax = "" parm [eax] value [eax] modify exact [edx];
extern unsigned long address_ready(unsigned long address);
#pragma aux address_ready = "" parm [eax] value [eax] modify exact [];

void address_planar_pixel_800(short x, short y, short color)
{
    int offset, column;
    short bit;
    unsigned long address;
    unsigned short selector;
    int mask;

    x = planar_x_in_si(x);
    offset = planar_offset_in_eax(planar_column_in_ecx(y) * 100);
    column = x >> 3;
    pixel_color = color;
    offset = planar_offset_in_eax(offset + column);
    bit = x & 7;
    address = offset + current_buffer_offset;
    column = bit;
    *(volatile unsigned long *)&pixel_address = address_ready(address);
    mask = mask_in_eax(0x80);
    selector = load_selector_in_dx(*(volatile unsigned short *)&current_buffer_selector);
    mask >>= column;
    pixel_selector = selector;
    mask <<= 8;
    pixel_bit_offset = bit;
    pixel_mask = mask;
}

extern short x_in_ecx(short);
#pragma aux x_in_ecx = parm [cx] value [cx] modify exact [];
extern unsigned short low_three_bits(short);
#pragma aux low_three_bits = "and cl,7" parm [cx] value [cx] modify exact [];
extern unsigned short bit_in_cx(unsigned short);
#pragma aux bit_in_cx = "xor ch,ch" parm [cx] value [cx] modify exact [];
extern unsigned long bank_address_in_eax(unsigned long);
#pragma aux bank_address_in_eax = parm [eax] value [eax] modify exact [];
extern unsigned long bank_offset(unsigned long);
#pragma aux bank_offset = "and edx,0ffffh" parm [edx] value [edx] modify exact [];
extern int extend_bank(short);
#pragma aux extend_bank = "cwde" parm [ax] value [eax] modify exact [];
extern unsigned short selector_in_ax(unsigned short);
#pragma aux selector_in_ax = parm [ax] value [ax] modify exact [];
extern int count_in_ecx(int);
#pragma aux count_in_ecx = parm [ecx] value [ecx] modify exact [];

extern void set_planar_bank(int);
#pragma aux set_planar_bank "select_graphics_bank_" modify exact [eax];

/* BX retains the pixel color across the bank callback. */
extern short incoming_color(void);
#pragma aux incoming_color = value [bx] modify exact [];
extern unsigned long bank_with_bit(unsigned long, unsigned short);
#pragma aux bank_with_bit = parm [eax] [cx] value [eax] modify exact [];
void address_banked_planar_pixel_1024(short x, short y, short color)
{
    short column = x_in_ecx(x);
    int row = byte_offset_in_edx(y);
    unsigned long address = address_in_edx(((unsigned long)row << 7) + (x >> 3));
    unsigned long bank = bank_address_in_eax(address);
    unsigned short bit = low_three_bits(column);
    unsigned short selector;
    unsigned long mask;
    int count;

    bank = bank_address_in_eax(bank_with_bit(bank, bit) >> 16);
    bit = bit_in_cx(bit);
    bank = extend_bank((short)bank);
    address = bank_offset(address);
    set_planar_bank(bank);
    selector = selector_in_ax(current_buffer_selector);
    pixel_bit_offset = bit;
    pixel_selector = selector;
    count = count_in_ecx((short)bit);
    mask = bank_address_in_eax(0x80);
    pixel_color = incoming_color();
    mask = bank_address_in_eax((long)mask >> count);
    address = address_in_edx(address + current_buffer_offset);
    mask = bank_address_in_eax(mask << 8);
    pixel_address = address;
    pixel_mask = mask;
}

/* Retain the operand-size prefix used by the original byte rotations. */
extern unsigned short rotate_vga_byte(unsigned char value, unsigned char count);
#pragma aux rotate_vga_byte = 0x66 "ror al,cl" "movzx ax,al" parm [al] [cl] value [ax] modify exact [];
extern unsigned char count_in_dl(unsigned char count);
#pragma aux count_in_dl = "" parm [dl] value [dl] modify exact [];
extern unsigned char prepare_color_count(unsigned char count);
#pragma aux prepare_color_count = "mov cl,dl" parm [dl] value [cl] modify exact [ecx];
/* The mask calculation retains only the low word after shifting. */
extern unsigned rotate_vga_mask_byte(unsigned char value, unsigned char count);
#pragma aux rotate_vga_mask_byte = 0x66 "ror al,cl" "movzx ax,al" parm [al] [cl] value [eax] modify exact [];
extern int shift_vga_column(int column);
#pragma aux shift_vga_column = "sar eax,3" parm [eax] value [eax] modify exact [];

void address_vga_mono_pixel(short x, short y, short color)
{
    int row, column;
    short saved_x;
    unsigned short bit, selector;
    unsigned long address;
    unsigned char count;
    unsigned mask;
    unsigned char color_count;

    saved_x = x_in_ecx(x);
    row = byte_offset_in_edx(coordinate_in_eax(y) * 80);
    column = coordinate_in_eax(saved_x);
    bit = bit_in_cx(low_three_bits(saved_x));
    column = shift_vga_column(column);
    pixel_bit_offset = bit;
    address = bank_address_in_eax(column + row);
    selector = load_selector_in_dx(*(volatile unsigned short *)&current_buffer_selector);
    address = bank_address_in_eax(address + current_buffer_offset);
    pixel_selector = selector;
    count = count_in_dl(*(volatile unsigned char *)&pixel_bit_offset);
    pixel_address = address;
    count = count_in_dl(count + 1);
    mask = rotate_vga_mask_byte(0xfe, count);
    mask = bank_address_in_eax((mask << 8) + 1);
    color_count = prepare_color_count(count);
    pixel_mask = mask;
    pixel_color = rotate_vga_byte(color, color_count);
}

extern unsigned short cga_odd_row(unsigned short offset);
#pragma aux cga_odd_row = "add dh,20h" parm [dx] value [dx] modify exact [];
extern unsigned long offset_to_eax(unsigned short offset);
#pragma aux offset_to_eax = "" parm [eax] value [eax] modify exact [];
/* The scanline calculation retains X in CX until the pixel bit is selected. */
extern short saved_x_from_cx(void);
#pragma aux saved_x_from_cx = value [cx] modify exact [];

void address_cga_mono_pixel(short x, short y, short color)
{
    int row, column;
    short saved_x;
    short scanline;
    unsigned short bit, selector, offset;
    unsigned long address;
    unsigned char count, color_count;
    unsigned mask;

    saved_x = x_in_ecx(x);
    scanline = y;
    row = byte_offset_in_edx((coordinate_in_eax(y) >> 1) * 80);
    column = shift_vga_column(coordinate_in_eax(saved_x));
    offset = row + column;
    /* Odd CGA rows start in the second 8 KiB bank. */
    if (scanline & 1)
        offset = cga_odd_row(offset);
    address = offset_to_eax(offset);
    bit = bit_in_cx(low_three_bits(saved_x_from_cx()));
    selector = load_selector_in_dx(current_buffer_selector);
    pixel_bit_offset = bit;
    address = bank_address_in_eax(address + current_buffer_offset);
    pixel_selector = selector;
    count = count_in_dl(*(volatile unsigned char *)&pixel_bit_offset);
    pixel_address = address;
    count = count_in_dl(count + 1);
    mask = rotate_vga_mask_byte(0xfe, count);
    mask = bank_address_in_eax((mask << 8) | 1);
    color_count = prepare_color_count(count);
    pixel_mask = mask;
    pixel_color = rotate_vga_byte(color, color_count);
}

extern int save_hercules_row(int row);
#pragma aux save_hercules_row = "" parm [ecx] value [ecx] modify exact [];
/* The low two row bits choose one of four interleaved 8 KiB banks. */
extern int hercules_row_bank(int row);
#pragma aux hercules_row_bank = "mov eax,ecx" "mov ecx,3" "and al,3" "xor ah,ah" "ror ax,cl" "cwde" parm [ecx] value [eax] modify exact [eax ecx];

void address_hercules_pixel(short x, int y, short color)
{
    int row, bank, column, saved_y;
    short saved_x;
    unsigned short selector, bit;
    unsigned long address;
    unsigned char count, color_count;
    unsigned mask;

    saved_x = planar_x_in_si(x);
    saved_y = save_hercules_row(y);
    row = byte_offset_in_edx((coordinate_in_eax((short)y) >> 2) * 90);
    bank = hercules_row_bank(saved_y);
    row = byte_offset_in_edx(row + bank);
    column = coordinate_in_eax(saved_x);
    bit = saved_x & 7;
    column >>= 3;
    pixel_bit_offset = bit;
    address = bank_address_in_eax(row + column);
    selector = load_selector_in_dx(current_buffer_selector);
    address = offset_to_eax(address);
    *(volatile unsigned short *)&pixel_selector = selector;
    address = bank_address_in_eax(address + current_buffer_offset);
    count = count_in_dl(*(volatile unsigned char *)&pixel_bit_offset);
    pixel_address = address;
    count = count_in_dl(count + 1);
    mask = rotate_vga_mask_byte(0xfe, count);
    mask = bank_address_in_eax((mask << 8) | 1);
    color_count = prepare_color_count(count);
    pixel_mask = mask;
    pixel_color = rotate_vga_byte(color, color_count);
}
