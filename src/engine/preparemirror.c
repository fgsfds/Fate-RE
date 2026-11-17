/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern unsigned char wall[], sector[], chainstat, pow2char[];
extern long mirror_z, mirror_row, window_top, window_bottom, window_left, window_right;
extern short mirror_sector;
extern long chainplace, frameplace, ylookup[];
extern long getangle(long dx, long dy);
#pragma aux getangle parm [eax] [edx] modify exact [eax ebx ecx edx] value [eax];
extern void preparemirror_finish(void);
extern void preparemirror_restore(void);
#pragma aux preparemirror_finish aborts modify exact [];
#pragma aux preparemirror_restore aborts modify exact [];

/* The following register bindings emit no instructions. They keep the
 * arithmetic in C modulo 2^32 while preserving values shared across the original frame. */
extern unsigned long from_ax(void);
#pragma aux from_ax = value [eax] modify exact [];

extern void in_ax(long value);
#pragma aux in_ax = "" parm [eax] modify exact [];

extern unsigned long from_bx(void);
#pragma aux from_bx = value [ebx] modify exact [];

extern void in_bx(long value);
#pragma aux in_bx = "" parm [ebx] modify exact [];

extern unsigned long from_cx(void);
#pragma aux from_cx = value [ecx] modify exact [];

extern void in_cx(long value);
#pragma aux in_cx = "" parm [ecx] modify exact [];

extern unsigned long from_dx(void);
#pragma aux from_dx = value [edx] modify exact [];

extern void in_dx(long value);
#pragma aux in_dx = "" parm [edx] modify exact [];

extern unsigned long from_di(void);
#pragma aux from_di = value [edi] modify exact [];

extern void in_di(long value);
#pragma aux in_di = "" parm [edi] modify exact [];

extern unsigned long from_si(void);
#pragma aux from_si = value [esi] modify exact [];

extern void in_si(long value);
#pragma aux in_si = "" parm [esi] modify exact [];

extern unsigned long from_bp(void);
#pragma aux from_bp = value [ebp] modify exact [];

extern void begin_mirror(void);
#pragma aux begin_mirror = "push esi" "push edi" "push ebp" "sub esp, 0xc" "push eax" "push edx" "push ebx" "push ecx" \
    "movsx eax, word ptr [esp + 0x30]" "shl eax, 5" modify exact [eax];

extern void save_wall_origin_y(void);
#pragma aux save_wall_origin_y = "mov [esp + 0x14], eax" modify exact [edi];

extern void save_wall_length(void);
#pragma aux save_wall_length = "mov ebp, edi" "imul ebp, edi" "mov dword ptr [esp + 0x18], esi" "add ebp, eax" \
    "je preparemirror_finish" modify exact [];

extern void read_projection_x(void);
#pragma aux read_projection_x = "mov esi, dword ptr [esp + 0xc]" "mov eax, dword ptr [esp + 0x18]" modify exact [esi eax];

extern void read_projection_y(void);
#pragma aux read_projection_y = "mov eax, edx" "sub eax, dword ptr [esp + 0x14]" modify exact [eax];

extern void save_wall_origin_x(void);
#pragma aux save_wall_origin_x = "mov dword ptr [esp + 0x10], ecx" modify exact [];

extern void scale_projection_x(void);
#pragma aux scale_projection_x = "mov eax, dword ptr [esp + 0x18]" "mov ebx, esi" "imul ebx" "idiv ecx" modify exact [eax ebx edx];

extern void read_reflected_x_offsets(void);
#pragma aux read_reflected_x_offsets = "mov ebx, dword ptr [esp + 0x10]" "mov ecx, dword ptr [esp + 0xc]" modify exact [ebx ecx];

extern void read_reflected_x_output(void);
#pragma aux read_reflected_x_output = "mov ecx, dword ptr [esp + 0x38]" "mov ebx, esi" modify exact [ecx ebx];

extern void read_wall_origin_y(void);
#pragma aux read_wall_origin_y = "mov eax, dword ptr [esp + 0x14]" modify exact [eax];

extern void scale_projection_y(void);
#pragma aux scale_projection_y = "mov ebp, dword ptr [esp + 8]" "mov dword ptr [esp + 0x10], eax" "mov eax, edi" \
    "mov esi, dword ptr [esp + 0x10]" "imul ebx" "idiv ecx" modify exact [eax ebx esi edx];

extern void read_reflected_y_output(void);
#pragma aux read_reflected_y_output = "mov ecx, dword ptr [esp + 0x3c]" modify exact [ecx];

extern void load_wall_delta_x(void);
#pragma aux load_wall_delta_x = "mov eax, [esp + 0x18]" modify exact [eax];

extern void read_camera_angle(void);
#pragma aux read_camera_angle = "mov edx, dword ptr [esp]" modify exact [edx];

extern void read_reflected_angle_output(void);
#pragma aux read_reflected_angle_output = "mov ecx, dword ptr [esp + 0x40]" modify exact [ecx];

extern void read_camera_height(void);
#pragma aux read_camera_height = "mov eax, dword ptr [esp + 4]" modify exact [eax];

extern void read_mirror_sector(void);
#pragma aux read_mirror_sector = "mov eax, dword ptr [esp + 0x34]" modify exact [eax];

extern void check_mirror_aperture(void);
#pragma aux check_mirror_aperture = "cmp eax, dword ptr [esi + sector + 4]" "jle preparemirror_finish" \
    "cmp eax, dword ptr [esi + sector + 8]" "jge preparemirror_finish" modify exact [eax esi];

extern void read_viewport_height_inputs(void);
#pragma aux read_viewport_height_inputs = "mov eax, [esp + 0x2c]" "mov ebp, [window_top]" modify exact [eax ebx ecx edi];

extern void load_viewport_left(void);
#pragma aux load_viewport_left = "mov edi, [window_left]" modify exact [eax edi];

extern void add_viewport_middle(void);
#pragma aux add_viewport_middle = "add ebp, ecx" modify exact [ecx];

extern void scale_marker_horizon(void);
#pragma aux scale_marker_horizon = "sar ebp, 1" "imul ebx" "idiv ecx" "add eax, ebp" modify exact [eax edx];

extern void load_marker_ceiling(void);
#pragma aux load_marker_ceiling = "mov ecx, dword ptr [esi + sector + 4]" modify exact [ecx];

extern void load_aperture_heights(void);
#pragma aux load_aperture_heights = "mov ebp, dword ptr [esi + sector + 8]" "mov eax, dword ptr [esp + 4]" modify exact [eax];

extern void read_chain_mode(void);
#pragma aux read_chain_mode = "mov ah, [chainstat]" modify exact [eax];

extern unsigned char marker_chain_mode(void);
#pragma aux marker_chain_mode = value [ah] modify exact [];

/* Keep the following pixel address update after the port write. */
extern void write_marker_port(unsigned port, unsigned value);
#pragma aux write_marker_port = "out dx, al" parm [edx] [eax] modify exact [edi];
extern void read_planar_row(void);
#pragma aux read_planar_row = "mov ebp, [mirror_row]" modify exact [eax];
extern void read_planar_row_offset(void);
#pragma aux read_planar_row_offset = "mov ebp, [ebp*4 + ylookup]" modify exact [ecx];
extern void advance_planar_row_address(void);
#pragma aux advance_planar_row_address = "add ebp, eax" modify exact [eax];

extern void read_marker_plane_bit(void);
#pragma aux read_marker_plane_bit = "mov al, byte ptr [eax + pow2char]" modify exact [eax edx];

/* Preserve the original EDI alignment tests and leading stores. */
extern void align_marker_destination(void);
#pragma aux align_marker_destination = "test edi, 1" "jz word_align" "stosb" "dec ecx" \
    "word_align:" "test edi, 2" "jz aligned" "stosw" "sub ecx, 2" "aligned:" modify exact [edi ecx];

extern void keep_linear_fill_count(void);
#pragma aux keep_linear_fill_count = "mov ecx, esi" modify exact [ecx];
extern unsigned char marker_remainder_low_byte(void);
#pragma aux marker_remainder_low_byte = value [bl] modify exact [];
extern void store_marker_byte(void);
#pragma aux store_marker_byte = "stosb" modify exact [edi];
extern void store_marker_word(void);
#pragma aux store_marker_word = "stosw" modify exact [edi];
extern void store_marker_dwords(void);
#pragma aux store_marker_dwords = "rep stosd" modify exact [ecx edi];

extern void load_linear_fill_bounds(void);
#pragma aux load_linear_fill_bounds = "mov eax, dword ptr [window_right]" "mov edi, dword ptr [window_left]" modify exact [eax edi];

extern void subtract_linear_fill_bounds(void);
#pragma aux subtract_linear_fill_bounds = "sub eax, edi" modify exact [eax];

extern void load_linear_fill_base(void);
#pragma aux load_linear_fill_base = "mov ebp, dword ptr [ecx*4 + ylookup]" "mov eax, dword ptr [frameplace]" modify exact [eax];

extern void finish_mirror(void);
#pragma aux finish_mirror = "add esp, 0x1c" "jmp near preparemirror_restore" aborts modify exact [];

extern void fill_short_marker(void);
#pragma aux fill_short_marker = "test cl, 1" "je short_words" "stosb" "short_words:" \
    "shr ecx, 1" "db 0f3h" "stosw" modify exact [ecx edi];

/* Expand in both video paths to retain their original copy layout. */
#define FILL_MARKER_PIXELS() do { \
    if (from_cx() < 4) { \
        fill_short_marker(); \
    } else { \
        align_marker_destination(); \
        in_bx(from_cx()); \
        in_cx(from_cx() >> 2); \
        store_marker_dwords(); \
        if (marker_remainder_low_byte() & 2) \
            store_marker_word(); \
        if (marker_remainder_low_byte() & 1) \
            store_marker_byte(); \
    } \
} while (0)

void preparemirror(void);
#pragma aux preparemirror aborts;

void preparemirror(void)
{
    begin_mirror();
    /* Read both endpoints through the 32-byte wall records. */
    in_cx(*(const long *)(wall + from_ax()));
    in_di(*(const short *)(wall + from_ax() + 8));
    in_ax(*(const long *)(wall + from_ax() + 4));
    in_di(from_di() << 5);
    save_wall_origin_y();
    in_si(*(const long *)(wall + from_di()));
    in_di(*(const long *)(wall + from_di() + 4));
    in_si(from_si() - from_cx());
    in_di(from_di() - from_ax());
    in_ax(from_si() * from_si());
    save_wall_length();
    /* Project twice onto the wall direction, then subtract the camera coordinates. */
    read_projection_x();
    in_si((from_si() - from_cx()) * from_ax());
    read_projection_y();
    in_ax(from_ax() * from_di());
    in_cx(from_cx() * 2);
    save_wall_origin_x();
    in_si(from_si() + from_ax());
    in_cx(from_bp());
    in_si(from_si() * 2);
    scale_projection_x();
    read_reflected_x_offsets();
    in_ax(from_ax() + from_bx() - from_cx());
    read_reflected_x_output();
    *(long *)from_cx() = from_ax();
    read_wall_origin_y();
    in_cx(from_bp());
    in_ax(from_ax() * 2);
    scale_projection_y();
    in_ax(from_ax() + from_si());
    read_reflected_y_output();
    in_ax(from_ax() - from_bp());
    in_dx(from_di());
    *(long *)from_cx() = from_ax();
    /* Reflect the angle in the 2048-step engine circle. */
    load_wall_delta_x();
    in_ax(getangle(from_ax(), from_dx()));
    read_camera_angle();
    in_ax(from_ax() * 2 - from_dx());
    read_reflected_angle_output();
    *(short *)from_cx() = from_ax() & 2047;
    read_camera_height();
    mirror_z = from_ax();
    read_mirror_sector();
    mirror_sector = (short)from_ax();
    in_ax((long)(short)from_ax());
    in_si(from_ax() * 40);
    read_camera_height();
    check_mirror_aperture();
    read_viewport_height_inputs();
    in_cx(window_bottom);
    in_bx(window_right);
    load_viewport_left();
    in_ax(from_ax() - 100);
    add_viewport_middle();
    in_bx(from_bx() - from_di());
    in_cx(320);
    scale_marker_horizon();
    load_marker_ceiling();
    mirror_row = from_ax();
    load_aperture_heights();
    in_cx(from_cx() + from_bp());
    in_ax(from_ax() * 2);
    /* Mark adjacent to the center so the reverse pass can determine the span. */
    if ((long)from_ax() > (long)from_cx())
        --mirror_row;
    else
        ++mirror_row;
    in_ax(mirror_row);
    in_bx(window_top);
    if ((long)from_ax() <= (long)from_bx())
        in_ax(from_bx());
    in_cx(window_bottom);
    if ((long)from_ax() < (long)from_cx()) {
        in_ax(mirror_row);
        in_si(window_top);
        if ((long)from_ax() > (long)from_si())
            in_cx(from_ax());
        else
            in_cx(from_si());
    }
    read_chain_mode();
    mirror_row = from_cx();
    if (!marker_chain_mode())
        goto linear_marker;
    write_marker_port(0x3c4, 2);
    read_planar_row();
    in_ax(chainplace);
    read_planar_row_offset();
    in_cx(window_left);
    advance_planar_row_address();
    in_ax(window_right);
    in_cx(from_cx() + 4);
    in_ax(from_ax() + 1);
    if ((long)from_cx() < (long)from_ax())
        in_ax(from_cx());
    in_si(from_ax() - 1);
    /* Each VGA plane receives the visible subset of the marker row. */
    goto test_marker_plane;
fill_planar_marker:
    in_ax(from_si() & 3);
    read_marker_plane_bit();
    in_dx(0x3c5);
    in_ax(from_ax() & 255);
    write_marker_port(from_dx(), from_ax());
    in_di(from_si());
    in_cx(window_right);
    in_ax(-1);
    in_cx(from_cx() + 4);
    in_di((long)from_di() >> 2);
    in_cx(from_cx() - from_si());
    in_di(from_di() + from_bp());
    in_cx((long)from_cx() >> 2);
    FILL_MARKER_PIXELS();
    in_si(from_si() - 1);
test_marker_plane:
    if ((long)from_si() >= window_left)
        goto fill_planar_marker;
    goto marker_done;
linear_marker:
    /* Linear video memory stores the marker row contiguously. */
    load_linear_fill_bounds();
    subtract_linear_fill_bounds();
    in_si(from_ax() + 1);
    load_linear_fill_base();
    in_ax(from_ax() + from_bp());
    keep_linear_fill_count();
    in_di(from_di() + from_ax());
    in_ax(-1);
    FILL_MARKER_PIXELS();
marker_done:
    finish_mirror();
}
