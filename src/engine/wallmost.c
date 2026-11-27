/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern long wall[], xb1[];
extern long camera_x, camera_y, camera_z, view_ray_x, view_ray_y;
extern unsigned char sector[];
extern short scan_wall_index[];
extern unsigned short sqrtable[];
/* Keep the integer store and x87 conversion in the original scratch word. */
extern volatile union {
    long integer;
    float real;
    unsigned char bytes[4];
} wallmost_sqrt_scratch;

#define AT_BYTE_OFFSET(values, offset) (*(long *)((char *)(values) + (offset)))

/* These entry points share the saved frame with wallmost_setup.c and wallmost_clip.c. */
extern void wallmost_restore(void);
extern void owallmost(void);
extern void wallmost_flat_height(void);
extern void wallmost_floor_height(void);
extern void wallmost_slope_geometry(void);
extern void wallmost_slope_length(void);
extern void wallmost_left_ray(void);
extern void wallmost_slope_coefficient(void);

extern long from_ax(void);
#pragma aux from_ax = value [eax] modify exact [];

extern void in_ax(long value);
#pragma aux in_ax = "" parm [eax] modify exact [];

extern long from_bx(void);
#pragma aux from_bx = value [ebx] modify exact [];

extern void in_bx(long value);
#pragma aux in_bx = "" parm [ebx] modify exact [];

extern long from_cx(void);
#pragma aux from_cx = value [ecx] modify exact [];

extern void in_cx(long value);
#pragma aux in_cx = "" parm [ecx] modify exact [];

extern long from_dx(void);
#pragma aux from_dx = value [edx] modify exact [];

extern void in_dx(long value);
#pragma aux in_dx = "" parm [edx] modify exact [];

extern long from_di(void);
#pragma aux from_di = value [edi] modify exact [];

extern void in_di(long value);
#pragma aux in_di = "" parm [edi] modify exact [];

extern long from_si(void);
#pragma aux from_si = value [esi] modify exact [];

extern void in_si(long value);
#pragma aux in_si = "" parm [esi] modify exact [];

extern long from_bp(void);
#pragma aux from_bp = value [ebp] modify exact [];

/* The square-root table indexes the unchanged squared length in EAX. */
extern long squared_length_from_ax(void);
#pragma aux squared_length_from_ax = "" value [eax] modify exact [eax];

extern long magnitude(long value);
#pragma aux magnitude = "test eax, eax" "jns positive" "neg eax" "positive:" \
    parm nomemory [eax] value [eax] modify exact [eax];

extern void save_wallmost_frame(void);
#pragma aux save_wallmost_frame = "push esi" "push edi" "push ebp" "sub esp, 0x70" "push eax" "mov ebp, edx" \
    "mov dword ptr [esp + 0x40], ebx" "mov byte ptr [esp + 0x70], cl" modify exact [eax ebx ecx edx edi esi];

extern void choose_sector_plane(void);
#pragma aux choose_sector_plane = "test cl, cl" "db 75h, 2bh" /* marker-rel8 +3,+4 */ modify exact [eax ebx ecx edx];

extern void read_ceiling_plane(void);
#pragma aux read_ceiling_plane = "mov ebx, dword ptr [eax + sector+4]" "mov ax, word ptr [eax + sector+0xc]" "xor ah, ah" \
    "and al, 2" "mov ecx, dword ptr [camera_z]" "cwde" modify exact [eax ebx ecx];

extern void check_ceiling_slope(void);
#pragma aux check_ceiling_slope = "test eax, eax" "db 75h, 32h" /* marker-rel8 +4,+5 */ "mov eax, dword ptr [esp]" modify exact [eax];

void wallmost(void);
#pragma aux wallmost aborts;

void wallmost(void)
{
    /* Save the original arguments and check whether the ceiling requires slope projection. */
    save_wallmost_frame();
    in_ax(from_bx());
    in_ax(from_ax() << 2);
    in_ax(from_ax() + from_bx());
    in_ax(from_ax() << 3);
    choose_sector_plane();
    read_ceiling_plane();
    in_bx(from_bx() - from_cx());
    check_ceiling_slope();
}

extern void project_flat_plane(void);
#pragma aux project_flat_plane = "call owallmost" "jmp wallmost_restore" aborts modify exact [eax ebx ecx edx esi edi];

void wallmost_flat_height(void);
#pragma aux wallmost_flat_height aborts;

void wallmost_flat_height(void)
{
    /* Delegate flat walls and return through the shared frame restore. */
    project_flat_plane();
}

extern void read_floor_plane(void);
#pragma aux read_floor_plane = "mov ebx, dword ptr [eax + sector+8]" "mov ax, word ptr [eax + sector+0xe]" "xor ah, ah" \
    "and al, 2" "mov edx, dword ptr [camera_z]" "cwde" modify exact [eax ebx edx];

extern void check_floor_slope(void);
#pragma aux check_floor_slope = "test eax, eax" "db 75h, 07h" /* marker-rel8 +1,+2 */ "mov eax, dword ptr [esp]" modify exact [eax];

extern void project_flat_floor(void);
#pragma aux project_flat_floor = "db 0ebh, 0d1h" /* marker-rel8 -4,-3 */ aborts modify exact [];

void wallmost_floor_height(void);
#pragma aux wallmost_floor_height aborts;

void wallmost_floor_height(void)
{
    /* Check whether the floor requires slope projection. */
    read_floor_plane();
    in_bx(from_bx() - from_dx());
    check_floor_slope();
    in_dx(from_bp());
    project_flat_floor();
}

extern void read_scanned_wall(void);
#pragma aux read_scanned_wall = "movsx edi, word ptr [ebp*2 + scan_wall_index]" modify exact [edi];

extern void save_scanned_wall_x(void);
#pragma aux save_scanned_wall_x = "mov dword ptr [esp + 0x5c], eax" "movsx eax, word ptr [edi + wall+8]" modify exact [eax];

extern void read_scanned_wall_x(void);
#pragma aux read_scanned_wall_x = "mov esi, dword ptr [esp + 0x5c]" modify exact [esi];

extern void save_wall_delta_x(void);
#pragma aux save_wall_delta_x = "mov dword ptr [esp + 0x48], edx" modify exact [edx];

extern void save_scanned_wall_y(void);
#pragma aux save_scanned_wall_y = "mov dword ptr [esp + 0x60], edx" modify exact [eax];

extern void save_wall_delta_y(void);
#pragma aux save_wall_delta_y = "mov edx, dword ptr [esp + 0x40]" "mov dword ptr [esp + 0x44], eax" modify exact [edx eax];

extern void read_sector_first_wall(void);
#pragma aux read_sector_first_wall = "movsx eax, word ptr [eax*8 + sector]" "mov dword ptr [esp + 0x2c], eax" modify exact [eax];

extern void read_sector_wall_point2(void);
#pragma aux read_sector_wall_point2 = "movsx edi, word ptr [eax + wall+8]" modify exact [edi];

extern void save_sector_wall_delta_x(void);
#pragma aux save_sector_wall_delta_x = "mov dword ptr [esp + 0x34], edx" modify exact [edx];

extern void save_sector_wall_delta_y(void);
#pragma aux save_sector_wall_delta_y = "mov dword ptr [esp + 0x3c], edx" "mov edx, dword ptr [esp + 0x34]" modify exact [edx];

extern void read_sector_wall_delta_y(void);
#pragma aux read_sector_wall_delta_y = "mov eax, dword ptr [esp + 0x3c]" modify exact [eax];

extern unsigned char from_bl(void);
#pragma aux from_bl = value [bl] modify exact [];
extern void in_cl(unsigned char value);
#pragma aux in_cl = parm [cl] modify exact [];
extern void in_bl(unsigned char value);
#pragma aux in_bl = parm [bl] modify exact [];
extern void in_bx_word(unsigned short value);
#pragma aux in_bx_word = parm [bx] modify exact [];
extern void check_wall_length_exponent(void);
#pragma aux check_wall_length_exponent = "sub bl, 0x44" "db 7dh, 0ch" /* marker-rel8 +2,+2 */ modify exact [ebx];
extern void skip_scaled_wall_length(void);
#pragma aux skip_scaled_wall_length = "db 0ebh, 17h" /* marker-rel8 +2,+3 */ modify exact [];
/* The no-base LEA and the hardware shift keep their original encodings. */
extern void use_scaled_sqrt_index(void);
#pragma aux use_scaled_sqrt_index = "db 08dh, 0ch, 05dh, 00h, 00h, 00h, 00h" \
    "shr eax, cl" modify exact [eax ecx];
extern void shift_scaled_wall_root(void);
#pragma aux shift_scaled_wall_root = "shl ebx, cl" modify exact [ebx];

void wallmost_slope_geometry(void);
#pragma aux wallmost_slope_geometry aborts;

void wallmost_slope_geometry(void)
{
    /* Read the scanned and sector base walls and measure the base length. */
    read_scanned_wall();
    in_di(from_di() << 5);
    in_ax(AT_BYTE_OFFSET(wall, from_di()));
    save_scanned_wall_x();
    in_ax(from_ax() << 5);
    read_scanned_wall_x();
    in_dx(AT_BYTE_OFFSET(wall, from_ax()));
    in_dx(from_dx() - from_si());
    save_wall_delta_x();
    in_dx(AT_BYTE_OFFSET(wall, from_di() + 4));
    in_ax(AT_BYTE_OFFSET(wall, from_ax() + 4));
    save_scanned_wall_y();
    in_ax(from_ax() - from_dx());
    save_wall_delta_y();
    in_ax(from_dx());
    in_ax(from_ax() << 2);
    in_ax(from_ax() + from_dx());
    read_sector_first_wall();
    in_ax(from_ax() << 5);
    read_sector_wall_point2();
    in_di(from_di() << 5);
    in_bx(AT_BYTE_OFFSET(wall, from_ax()));
    in_dx(AT_BYTE_OFFSET(wall, from_di()));
    in_dx(from_dx() - from_bx());
    in_cx(AT_BYTE_OFFSET(wall, from_ax() + 4));
    save_sector_wall_delta_x();
    in_dx(AT_BYTE_OFFSET(wall, from_di() + 4));
    in_dx(from_dx() - from_cx());
    save_sector_wall_delta_y();
    in_dx(from_dx() * from_dx());
    read_sector_wall_delta_y();
    in_ax(from_ax() * from_ax());
    in_dx(from_dx() + from_ax());
    in_ax(from_dx());
    wallmost_sqrt_scratch.integer = squared_length_from_ax();
    wallmost_sqrt_scratch.real = (float)wallmost_sqrt_scratch.integer;
    in_bl(wallmost_sqrt_scratch.bytes[3]);
    check_wall_length_exponent();
    in_bx(0);
    in_bx_word(sqrtable[from_ax()]);
    skip_scaled_wall_length();
    use_scaled_sqrt_index();
    /* Reuse the undoubled exponent to scale the table result. */
    in_cl(from_bl());
    in_bx(0);
    in_bx_word(sqrtable[from_ax()]);
    shift_scaled_wall_root();
}

void wallmost_slope_length(void);
#pragma aux wallmost_slope_length aborts;

void wallmost_slope_length(void)
{
    /* Normalize the base-wall length with the original square-root table. */
    in_bx((unsigned long)from_bx() >> 10);
    if (from_bx() > 16) {
        in_ax(from_dx());
        wallmost_sqrt_scratch.integer = squared_length_from_ax();
        wallmost_sqrt_scratch.real = (float)wallmost_sqrt_scratch.integer;
        in_bl(wallmost_sqrt_scratch.bytes[3]);
        check_wall_length_exponent();
        in_bx(0);
        in_bx_word(sqrtable[from_ax()]);
        skip_scaled_wall_length();
        use_scaled_sqrt_index();
        /* Reuse the undoubled exponent to scale the table result. */
        in_cl(from_bl());
        in_bx(0);
        in_bx_word(sqrtable[from_ax()]);
        shift_scaled_wall_root();
        in_bx((unsigned long)from_bx() >> 10);
        in_cx(from_bx());
    } else {
        in_cx(16);
    }
}

extern void check_left_window_edge(void);
#pragma aux check_left_window_edge = "cmp dword ptr [ebp*4 + xb1], 0" "db 75h, 19h" /* marker-rel8 +2 */ modify exact [eax ebx edx edi esi];

extern void skip_unclipped_left_ray(void);
#pragma aux skip_unclipped_left_ray = "db 0ebh, 18h" /* marker-rel8 +3 */ modify exact [];

extern void read_scanned_wall_x_left(void);
#pragma aux read_scanned_wall_x_left = "mov eax, dword ptr [esp + 0x5c]" modify exact [eax];

extern void read_scanned_wall_y_left(void);
#pragma aux read_scanned_wall_y_left = "mov ebx, dword ptr [esp + 0x60]" modify exact [ebx];

extern void read_left_ray_origin_y(void);
#pragma aux read_left_ray_origin_y = "mov edx, dword ptr [esp + 0x60]" modify exact [edx];

extern void read_left_ray_origin_x(void);
#pragma aux read_left_ray_origin_x = "mov edx, dword ptr [esp + 0x5c]" modify exact [edx];

extern void scale_left_ray_x(void);
#pragma aux scale_left_ray_x = "imul eax, dword ptr [esp + 0x44]" modify exact [eax];

extern void scale_left_ray_y(void);
#pragma aux scale_left_ray_y = "imul ebx, dword ptr [esp + 0x48]" modify exact [ebx];

extern void left_ray_intersection(void);
#pragma aux left_ray_intersection = "cmp edx, eax" "db 7eh, 0eh" /* marker-rel8 0,+1 */ "mov eax, edi" "mov edx, eax" "sar edx, 4" "shl eax, 0x1c" \
    "idiv ebx" "mov edi, eax" modify exact [eax edi edx];

void wallmost_left_ray(void);
#pragma aux wallmost_left_ray aborts;

void wallmost_left_ray(void)
{
    /* Intersect the base wall with the left viewport ray. */
    check_left_window_edge();
    in_ax(view_ray_x);
    in_di(view_ray_y);
    in_dx(view_ray_x);
    in_bx(from_di());
    in_ax(from_ax() + from_di());
    in_bx(from_bx() - from_dx());
    skip_unclipped_left_ray();
    read_scanned_wall_x_left();
    in_bx(camera_x);
    in_si(camera_y);
    in_ax(from_ax() - from_bx());
    read_scanned_wall_y_left();
    in_bx(from_bx() - from_si());
    read_left_ray_origin_y();
    in_si(camera_y);
    in_di(from_ax());
    in_dx(from_dx() - from_si());
    in_di(from_di() * from_dx());
    in_si(camera_x);
    read_left_ray_origin_x();
    in_dx(from_dx() - from_si());
    in_dx(from_dx() * from_bx());
    scale_left_ray_x();
    in_di(from_di() - from_dx());
    scale_left_ray_y();
    in_bx(from_bx() - from_ax());
    in_ax(from_bx());
    in_ax(magnitude(from_ax()));
    in_dx(from_ax());
    in_ax(from_di());
    in_ax(from_ax() >> 3);
    in_ax(magnitude(from_ax()));
    left_ray_intersection();
}

extern void read_slope_sector(void);
#pragma aux read_slope_sector = "mov eax, dword ptr [esp + 0x40]" modify exact [eax];

extern void read_floor_selector(void);
#pragma aux read_floor_selector = "mov dh, byte ptr [esp + 0x70]" modify exact [edx];

extern void read_ceiling_slope(void);
#pragma aux read_ceiling_slope = "test dh, dh" "jne branch_268" "mov ax, word ptr [esi + sector+0x12]" "mov ebx, ecx" "cwde" \
    "mov edx, eax" "sar edx, 0x11" "shl eax, 0xf" "idiv ebx" "mov dword ptr [esp + 0x64], eax" \
    "mov eax, dword ptr [esi + sector+4]" "db 0ebh, 1eh" "branch_268:" modify exact [eax ebx edx];

extern void read_floor_slope(void);
#pragma aux read_floor_slope = "mov ax, word ptr [esi + sector+0x1a]" "mov ebx, ecx" "cwde" "mov edx, eax" "sar edx, 0x11" \
    "shl eax, 0xf" "idiv ebx" "mov dword ptr [esp + 0x64], eax" \
    "mov eax, dword ptr [esi + sector+8]" modify exact [eax ebx edx];

void wallmost_slope_coefficient(void);
#pragma aux wallmost_slope_coefficient aborts;

void wallmost_slope_coefficient(void)
{
    /* Select the slope coefficient and sector elevation for the endpoint setup. */
    read_slope_sector();
    in_si(from_ax());
    in_si(from_si() << 2);
    in_si(from_si() + from_ax());
    read_floor_selector();
    in_si(from_si() << 3);
    read_ceiling_slope();
    read_floor_slope();
}
