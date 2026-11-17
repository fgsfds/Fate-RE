/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern short globalpicnum, translucent_tile_shift;
extern short tilesizx[], tilesizy[], startumost[], startdmost[];
extern unsigned char walock[], gotpic[], pow2char[], chainstat;
extern unsigned char *waloff[];
extern long windowx1, viewoffset;

extern void loadtile(long tile);
#pragma aux loadtile parm [eax] modify exact [eax];
extern void set_translucent_column_shift(long shift);
#pragma aux set_translucent_column_shift parm [eax] modify exact [eax];
extern void transmaskvline(long column);
#pragma aux transmaskvline parm [eax] modify exact [eax];
extern void transmaskvline_pair(long column);
#pragma aux transmaskvline_pair parm [eax] modify exact [eax];
extern void faketimerhandler(void);
#pragma aux faketimerhandler modify exact [eax];
extern void ceiling_sprite_restore_registers(void);
#pragma aux ceiling_sprite_restore_registers aborts modify exact [];

extern void warm_translucent_tile(void);
#pragma aux warm_translucent_tile = "mov byte ptr [eax + walock], 199" modify exact [];
extern void translucent_wall_cleanup(void);
#pragma aux translucent_wall_cleanup aborts modify exact [];
extern void check_translucent_tile_size(void);
#pragma aux check_translucent_tile_size = "cmp word ptr [eax + tilesizx], 0" "jle translucent_wall_cleanup" \
    "cmp word ptr [eax + tilesizy], 0" "jle translucent_wall_cleanup" modify exact [];

extern void begin_translucent_wall(void);
#pragma aux begin_translucent_wall = "push ebx" "push ecx" "push esi" "push edi" "push ebp" "push eax" "push edx" \
    "mov ax, word ptr [globalpicnum]" modify exact [eax];
extern void finish_translucent_wall(void);
#pragma aux finish_translucent_wall = "add esp, 8" "jmp ceiling_sprite_restore_registers" aborts modify exact [];

extern void load_planar_first_byte(void);
#pragma aux load_planar_first_byte = "mov cl, [esp + 4]" modify exact [ecx edx eax];

extern void reload_planar_left_column(void);
#pragma aux reload_planar_left_column = "mov esi, [esp + 4]" modify exact [eax ecx esi];
extern void set_last_plane(unsigned char plane);
#pragma aux set_last_plane = "" parm [ch] modify exact [];

extern void load_short_planar_end(void);
#pragma aux load_short_planar_end = "mov ch, [esp]" modify exact [ecx];

extern void set_planar_wall_bounds(void);
#pragma aux set_planar_wall_bounds = "mov esi, [esp + 4]" "mov ebp, [esp]" modify exact [esi eax edx];

extern void keep_port_low_byte(unsigned char value);
#pragma aux keep_port_low_byte = "" parm [al] modify exact [];

extern unsigned char port_low_byte(void);
#pragma aux port_low_byte = value [al] modify exact [];
extern void zero_port_high_byte(void);
#pragma aux zero_port_high_byte = "xor ah, ah" modify exact [eax];
/* The original register widening also keeps Watcom from moving the port setup. */
extern void extend_port_read_plane(void);
#pragma aux extend_port_read_plane = "cwde" modify exact [eax edx];
extern void write_wall_vga_byte(unsigned port, unsigned value);
#pragma aux write_wall_vga_byte = "out dx, al" parm [edx] [eax] modify exact [eax edx];
extern void write_wall_vga_word(unsigned port, unsigned value);
#pragma aux write_wall_vga_word = "out dx, ax" parm [edx] [eax] modify exact [];

extern void skip_planar_clipped_columns(void);
#pragma aux skip_planar_clipped_columns = "scan_clipped:" "mov eax, [windowx1]" "add eax, edx" \
    "mov bx, word ptr [eax*2 + startumost]" "cmp bx, word ptr [eax*2 + startdmost]" "jle scan_clear" \
    "cmp edx, [esp]" "jg scan_clear" "add edx, 4" "jmp scan_clipped" "scan_clear:" modify exact [eax ebx edx];
extern void read_end_column(void);
#pragma aux read_end_column = "mov eax, [esp]" modify exact [eax];
extern void draw_remaining_planar_columns(void);
#pragma aux draw_remaining_planar_columns = "check_remaining:" "cmp edx, [esp]" "jg remaining_done" \
    "mov eax, edx" "call transmaskvline" "add edx, 4" "jmp check_remaining" "remaining_done:" modify exact [eax edx];

extern void set_linear_wall_bounds(void);
#pragma aux set_linear_wall_bounds = "mov edx, [esp + 4]" "mov edi, [esp]" modify exact [edx edi];
extern void skip_linear_clipped_columns(void);
#pragma aux skip_linear_clipped_columns = "scan_clipped:" "mov eax, [windowx1]" "add eax, edx" \
    "mov bx, word ptr [eax*2 + startumost]" "cmp bx, word ptr [eax*2 + startdmost]" "jle scan_clear" \
    "cmp edx, edi" "jg scan_clear" "inc edx" "jmp scan_clipped" "scan_clear:" modify exact [eax ebx edx];
extern void draw_linear_leading_and_pairs(void);
#pragma aux draw_linear_leading_and_pairs = "cmp edx, [esp]" "jg linear_pairs" "test dl, 1" "jz linear_pairs" \
    "mov eax, edx" "call transmaskvline" "inc edx" "linear_pairs:" "cmp edx, [esp]" "jge linear_pairs_done" \
    "mov eax, edx" "call transmaskvline_pair" "add edx, 2" "jmp linear_pairs" "linear_pairs_done:" \
    "mov ebx, [esp]" modify exact [eax ebx edx];

extern unsigned char bits_low_byte(void);
#pragma aux bits_low_byte = value [dl] modify exact [];
extern void in_bits_low_byte(unsigned char value);
#pragma aux in_bits_low_byte = "" parm [dl] modify exact [];
extern unsigned char tile_mask_low_byte(void);
#pragma aux tile_mask_low_byte = value [bl] modify exact [];
extern void in_tile_mask_low_byte(unsigned char value);
#pragma aux in_tile_mask_low_byte = "" parm [bl] modify exact [];
extern unsigned char current_plane(void);
#pragma aux current_plane = value [cl] modify exact [];
extern unsigned char last_plane(void);
#pragma aux last_plane = value [ch] modify exact [];
extern void set_current_plane(unsigned char plane);
#pragma aux set_current_plane = "" parm [cl] modify exact [];

extern long from_ax(void);
#pragma aux from_ax = value [eax] modify exact [];
extern void in_ax(long value);
#pragma aux in_ax = "" parm [eax] modify exact [];

extern long from_bx(void);
#pragma aux from_bx = value [ebx] modify exact [];
extern void in_bx(long value);
#pragma aux in_bx = "" parm [ebx] modify exact [];

extern long from_dx(void);
#pragma aux from_dx = value [edx] modify exact [];
extern void in_dx(long value);
#pragma aux in_dx = "" parm [edx] modify exact [];

extern long from_si(void);
#pragma aux from_si = value [esi] modify exact [];
extern void in_si(long value);
#pragma aux in_si = "" parm [esi] modify exact [];

extern long from_bp(void);
#pragma aux from_bp = value [ebp] modify exact [];

void transmaskwallscan(void);
#pragma aux transmaskwallscan aborts;

void transmaskwallscan(void)
{
    /* Touch the cached tile before checking its dimensions. */
    begin_translucent_wall();
    in_ax((short)from_ax());
    in_bx(from_ax());
    if (walock[from_ax()] < 200)
        warm_translucent_tile();
    in_ax((unsigned long)from_ax() >> 3);
    in_bx(from_bx() & 7);
    in_bits_low_byte(gotpic[from_ax()]);
    in_tile_mask_low_byte(pow2char[from_bx()]);
    in_bits_low_byte(bits_low_byte() | tile_mask_low_byte());
    gotpic[from_ax()] = bits_low_byte();

    in_dx(globalpicnum);
    in_ax(from_dx() * 2);
    check_translucent_tile_size();
    if (!waloff[from_dx()])
        loadtile(from_dx());
    set_translucent_column_shift(translucent_tile_shift);

    if (!chainstat)
        goto linear;
    /* A short span wraps the stopping plane to the column just past its end. */
    load_planar_first_byte();
    in_bits_low_byte((unsigned char)viewoffset);
    read_end_column();
    set_current_plane(current_plane() + bits_low_byte());
    reload_planar_left_column();
    set_current_plane(current_plane() & 3);
    in_ax(from_ax() - from_si());
    set_last_plane(current_plane());
    if (from_ax() < 4) {
        load_short_planar_end();
        set_last_plane(last_plane() + 1);
        set_last_plane(last_plane() + bits_low_byte());
        set_last_plane(last_plane() & 3);
    }
    set_planar_wall_bounds();

    /* Planar mode draws every fourth column on the active VGA plane. */
    do {
        /* The sequencer selects writes. The graphics controller selects reads. */
        in_ax(0);
        keep_port_low_byte(current_plane());
        keep_port_low_byte(pow2char[from_ax()]);
        in_dx(0x3c5);
        in_ax(from_ax() & 255);
        write_wall_vga_byte(from_dx(), from_ax());
        keep_port_low_byte(current_plane());
        zero_port_high_byte();
        keep_port_low_byte(port_low_byte() & 3);
        extend_port_read_plane();
        in_ax(from_ax() << 8);
        in_dx(0x3ce);
        in_ax(from_ax() + 4);
        write_wall_vga_word(from_dx(), from_ax());
        in_dx(from_si());
        skip_planar_clipped_columns();
        if (from_dx() <= from_bp() && (bits_low_byte() & 1)) {
            transmaskvline(from_dx());
            in_dx(from_dx() + 4);
        }
        /* Pair two columns whenever both fit inside the span. */
        for (;;) {
            read_end_column();
            in_ax(from_ax() - 4);
            if (from_dx() > from_ax())
                break;
            transmaskvline_pair(from_dx());
            in_dx(from_dx() + 8);
        }
        draw_remaining_planar_columns();
        set_current_plane(current_plane() + 1);
        set_current_plane(current_plane() & 3);
        in_si(from_si() + 1);
    } while (current_plane() != last_plane());

wall_timer:
    faketimerhandler();
    finish_translucent_wall();

linear:
    /* Linear mode uses adjacent columns and the same clipped start. */
    set_linear_wall_bounds();
    skip_linear_clipped_columns();
    draw_linear_leading_and_pairs();
last_columns:
    if (from_dx() > from_bx())
        goto wall_timer;
    transmaskvline(from_dx());
    in_dx(from_dx() + 1);
    goto last_columns;
}
