/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern long wall[], xb1[], xb2[], yb1[], yb2[], xdimen;
extern long camera_x, camera_y, camera_z, wall_clip_top, wall_clip_bottom;
extern long view_ray_x, view_ray_y;
extern unsigned char sector[];

#define AT_BYTE_OFFSET(values, offset) (*(long *)((char *)(values) + (offset)))

/* This continuation uses the saved frame from the wallmost geometry entry. */
extern void wallmost_right_ray(void);
extern void wallmost_right_height(void);
extern void wallmost_clip_flags(void);

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

extern long scale20(long value, long factor);
#pragma aux scale20 = "imul ebx" "shrd eax, edx, 20" \
    parm nomemory [eax] [ebx] value [eax] modify exact [eax edx];

extern long sum_products24(long first, long second, long third, long fourth);
#pragma aux sum_products24 = "imul ebx" "xchg esi, eax" "mov ebx, edx" "imul edi" \
    "add eax, esi" "adc edx, ebx" "shrd eax, edx, 24" \
    parm nomemory [eax] [ebx] [esi] [edi] value [eax] modify exact [eax ebx edx esi];

extern long magnitude(long value);
#pragma aux magnitude = "test eax, eax" "jns positive" "neg eax" "positive:" \
    parm nomemory [eax] value [eax] modify exact [eax];

extern void save_left_sector_plane(void);
#pragma aux save_left_sector_plane = "mov dword ptr [esp + 0x6c], eax" "mov eax, dword ptr [esp + 0x6c]" modify exact [eax];

extern void read_slope_origin(void);
#pragma aux read_slope_origin = "mov esi, dword ptr [esp + 0x2c]" modify exact [esi];

extern void save_left_height_from_camera(void);
#pragma aux save_left_height_from_camera = "mov dword ptr [esp + 0x10], eax" "mov eax, dword ptr [esp + 0x5c]" modify exact [eax];

extern void save_left_wall_x(void);
#pragma aux save_left_wall_x = "mov dword ptr [esp + 0xc], eax" "mov eax, dword ptr [esp + 0x48]" modify exact [eax];

extern void read_left_wall_x(void);
#pragma aux read_left_wall_x = "mov edx, dword ptr [esp + 0xc]" modify exact [edx];

extern void read_left_slope_coefficients(void);
#pragma aux read_left_slope_coefficients = "mov eax, dword ptr [esp + 0x3c]" "mov dword ptr [esp + 0xc], edx" \
    "mov edx, dword ptr [esp + 0x64]" modify exact [eax edx];

extern void save_left_slope_y(void);
#pragma aux save_left_slope_y = "mov eax, dword ptr [esp + 0x60]" "mov dword ptr [esp + 0x14], edx" modify exact [eax];

extern void read_left_wall_delta_y(void);
#pragma aux read_left_wall_delta_y = "mov eax, dword ptr [esp + 0x44]" modify exact [eax];

extern void read_left_slope_products(void);
#pragma aux read_left_slope_products = "mov eax, dword ptr [esp + 0x34]" "imul eax, dword ptr [esp + 0x64]" \
    "mov edi, dword ptr [esp + 0xc]" "mov esi, dword ptr [esp + 0x14]" modify exact [eax esi edi];

extern void read_left_base_height(void);
#pragma aux read_left_base_height = "mov edx, dword ptr [esp + 0x10]" modify exact [edx];

extern void save_left_clip_height(void);
#pragma aux save_left_clip_height = "mov dword ptr [esp + 0x6c], edx" modify exact [];

extern void check_right_window_edge(void);
#pragma aux check_right_window_edge = "cmp edx, edi" "db 75h, 18h" /* marker-rel8 +2 */ modify exact [eax ebx edx esi edi];

extern void skip_right_wall_ray(void);
#pragma aux skip_right_wall_ray = "db 0ebh, 24h" /* marker-rel8 +3,+4 */ modify exact [];

extern void read_right_wall_delta_x(void);
#pragma aux read_right_wall_delta_x = "mov eax, dword ptr [esp + 0x48]" "mov edx, dword ptr [esp + 0x5c]" modify exact [eax edx];

extern void read_origin_y(void);
#pragma aux read_origin_y = "mov esi, dword ptr [esp + 0x60]" modify exact [esi];

extern void read_right_wall_delta_y(void);
#pragma aux read_right_wall_delta_y = "mov ebx, dword ptr [esp + 0x44]" modify exact [ebx];

void wallmost_left_height(void);
#pragma aux wallmost_left_height aborts;

void wallmost_left_height(void)
{
    /* Project the left endpoint and choose the right endpoint ray. */
    save_left_sector_plane();
    in_dx(camera_z);
    read_slope_origin();
    in_ax(from_ax() - from_dx());
    in_si(from_si() << 5);
    in_ax((unsigned long)from_ax() << 7);
    in_bx(AT_BYTE_OFFSET(wall, from_si()));
    save_left_height_from_camera();
    in_ax(from_ax() - from_bx());
    in_ax((unsigned long)from_ax() << 8);
    in_bx(from_di());
    save_left_wall_x();
    in_ax(scale20(from_ax(), from_bx()));
    read_left_wall_x();
    in_dx(from_dx() + from_ax());
    read_left_slope_coefficients();
    in_ax(-from_ax());
    in_dx(from_dx() * from_ax());
    save_left_slope_y();
    in_dx(AT_BYTE_OFFSET(wall, from_si() + 4));
    in_si(from_ax());
    in_si(from_si() - from_dx());
    read_left_wall_delta_y();
    in_si((unsigned long)from_si() << 8);
    in_ax(scale20(from_ax(), from_bx()));
    in_bx(from_ax() + from_si());
    read_left_slope_products();
    in_ax(sum_products24(from_ax(), from_bx(), from_si(), from_di()));
    read_left_base_height();
    in_dx(from_dx() + from_ax());
    save_left_clip_height();
    in_dx(xdimen);
    in_di(xb2[from_bp()]);
    in_dx(from_dx() - 1);
    check_right_window_edge();
    in_ax(view_ray_x);
    in_dx(view_ray_y);
    in_si(view_ray_x);
    in_ax(from_ax() - from_dx());
    in_bx(from_dx() + from_si());
    skip_right_wall_ray();
    read_right_wall_delta_x();
    in_bx(camera_x);
    in_ax(from_ax() + from_dx());
    read_origin_y();
    in_ax(from_ax() - from_bx());
    read_right_wall_delta_y();
    in_di(camera_y);
    in_bx(from_bx() + from_si());
    in_bx(from_bx() - from_di());
}

extern void read_ray_origin_y(void);
#pragma aux read_ray_origin_y = "mov edx, dword ptr [esp + 0x60]" modify exact [edx];

extern void read_ray_origin_x(void);
#pragma aux read_ray_origin_x = "mov edi, dword ptr [esp + 0x5c]" modify exact [edi];

extern void scale_ray_x(void);
#pragma aux scale_ray_x = "imul eax, dword ptr [esp + 0x44]" modify exact [eax];

extern void scale_ray_y(void);
#pragma aux scale_ray_y = "imul ebx, dword ptr [esp + 0x48]" modify exact [ebx];

extern void determine_ray_intersection(void);
#pragma aux determine_ray_intersection = "cmp edx, eax" "jle branch_3c7" "mov eax, edi" "mov edx, eax" "sar edx, 4" "shl eax, 0x1c" \
    "idiv ebx" "mov edi, eax" "branch_3c7:" "mov eax, dword ptr [esp + 0x40]" modify exact [eax edx edi];

extern void read_plane_selector(void);
#pragma aux read_plane_selector = "mov bl, byte ptr [esp + 0x70]" modify exact [ebx];

extern void read_right_plane_height(void);
#pragma aux read_right_plane_height = "test bl, bl" "jne branch_3fd" "mov ax, word ptr [esi + sector+0x12]" "mov ebx, ecx" "cwde" \
    "mov edx, eax" "sar edx, 0x11" "shl eax, 0xf" "idiv ebx" "mov dword ptr [esp + 0x64], eax" \
    "mov esi, dword ptr [esi + sector+4]" "db 0ebh, 1eh" /* marker-rel8 +1,+2 */ "branch_3fd:" modify exact [eax ebx edx esi];

extern void read_alternate_right_height(void);
#pragma aux read_alternate_right_height = "mov ax, word ptr [esi + sector+0x1a]" "mov ebx, ecx" "cwde" "mov edx, eax" "sar edx, 0x11" \
    "shl eax, 0xf" "idiv ebx" "mov dword ptr [esp + 0x64], eax" \
    "mov esi, dword ptr [esi + sector+8]" modify exact [eax ebx edx esi];

void wallmost_right_ray(void);
#pragma aux wallmost_right_ray aborts;

void wallmost_right_ray(void)
{
    /* Intersect the right ray with the wall and select the sector plane height. */
    read_ray_origin_y();
    in_dx(from_dx() - camera_y);
    in_dx(from_dx() * from_ax());
    in_si(camera_x);
    read_ray_origin_x();
    in_di(from_di() - from_si());
    in_di(from_di() * from_bx());
    scale_ray_x();
    in_dx(from_dx() - from_di());
    in_di(from_dx());
    scale_ray_y();
    in_bx(from_bx() - from_ax());
    in_ax(from_bx());
    in_ax(magnitude(from_ax()));
    in_dx(from_ax());
    in_ax(from_di());
    in_ax(from_ax() >> 3);
    in_ax(magnitude(from_ax()));
    determine_ray_intersection();
    in_si(from_ax());
    in_si(from_si() << 2);
    in_si(from_si() + from_ax());
    read_plane_selector();
    in_si(from_si() << 3);
    read_right_plane_height();
    read_alternate_right_height();
}

extern void read_right_slope_origin(void);
#pragma aux read_right_slope_origin = "mov ecx, dword ptr [esp + 0x2c]" modify exact [ecx];

extern void read_right_slope_x(void);
#pragma aux read_right_slope_x = "mov dword ptr [esp + 0x14], esi" "mov esi, dword ptr [esp + 0x5c]" modify exact [esi ebx];

extern void read_right_wall_x(void);
#pragma aux read_right_wall_x = "mov eax, dword ptr [esp + 0x48]" modify exact [eax];

extern void read_right_slope_coefficients(void);
#pragma aux read_right_slope_coefficients = "mov eax, dword ptr [esp + 0x3c]" "mov edx, dword ptr [esp + 0x64]" modify exact [eax edx];

extern void save_slope_product(void);
#pragma aux save_slope_product = "mov eax, dword ptr [esp + 0x60]" "mov dword ptr [esp + 0x10], edx" modify exact [eax];

extern void read_right_y_delta(void);
#pragma aux read_right_y_delta = "mov eax, dword ptr [esp + 0x44]" modify exact [eax];

extern void read_right_slope_products(void);
#pragma aux read_right_slope_products = "mov eax, dword ptr [esp + 0x34]" "imul eax, dword ptr [esp + 0x64]" "mov edi, esi" \
    "mov esi, dword ptr [esp + 0x10]" modify exact [eax esi edi];

extern void read_right_base_height(void);
#pragma aux read_right_base_height = "mov esi, dword ptr [esp + 0x14]" modify exact [esi];

void wallmost_right_height(void);
#pragma aux wallmost_right_height aborts;

void wallmost_right_height(void)
{
    /* Project the second height using the right endpoint ray. */
    in_ax(camera_z);
    read_right_slope_origin();
    in_si(from_si() - from_ax());
    in_cx(from_cx() << 5);
    in_si((unsigned long)from_si() << 7);
    in_dx(AT_BYTE_OFFSET(wall, from_cx()));
    read_right_slope_x();
    in_bx(from_di());
    in_si(from_si() - from_dx());
    read_right_wall_x();
    in_si((unsigned long)from_si() << 8);
    in_ax(scale20(from_ax(), from_bx()));
    in_si(from_si() + from_ax());
    read_right_slope_coefficients();
    in_ax(-from_ax());
    in_dx(from_dx() * from_ax());
    in_bx(AT_BYTE_OFFSET(wall, from_cx() + 4));
    save_slope_product();
    in_cx(from_ax());
    read_right_y_delta();
    in_cx(from_cx() - from_bx());
    in_bx(from_di());
    in_cx((unsigned long)from_cx() << 8);
    in_ax(scale20(from_ax(), from_bx()));
    in_bx(from_ax() + from_cx());
    read_right_slope_products();
    in_ax(sum_products24(from_ax(), from_bx(), from_si(), from_di()));
    read_right_base_height();
}

extern void save_first_top_clip_limit(void);
#pragma aux save_first_top_clip_limit = "mov dword ptr [esp + 8], eax" modify exact [eax edx ebx];

extern void save_second_top_clip_limit(void);
#pragma aux save_second_top_clip_limit = "mov dword ptr [esp + 0x18], eax" modify exact [eax edx ebx];

extern void save_first_bottom_clip_limit(void);
#pragma aux save_first_bottom_clip_limit = "mov dword ptr [esp + 0x28], eax" modify exact [eax edx ebx];

extern void set_first_top_clip_bit(void);
#pragma aux set_first_top_clip_bit = "mov dword ptr [esp + 0x20], eax" "cmp esi, edi" "setl al" "mov edx, eax" \
    "mov edi, dword ptr [esp + 8]" modify exact [eax edx edi];

extern void read_left_projected_height(void);
#pragma aux read_left_projected_height = "mov eax, dword ptr [esp + 0x6c]" modify exact [eax];

extern void set_second_top_clip_bit(void);
#pragma aux set_second_top_clip_bit = "cmp eax, edi" "setl al" modify exact [eax];

extern void read_first_bottom_clip_limit(void);
#pragma aux read_first_bottom_clip_limit = "mov ebx, dword ptr [esp + 0x28]" modify exact [ebx];

extern void set_first_bottom_clip_bit(void);
#pragma aux set_first_bottom_clip_bit = "mov edx, dword ptr [esp + 0x6c]" "cmp edx, ebx" "setg dl" modify exact [edx];

extern void read_second_bottom_clip_limit(void);
#pragma aux read_second_bottom_clip_limit = "mov ecx, dword ptr [esp + 0x20]" modify exact [ecx];

extern void set_second_bottom_clip_bit(void);
#pragma aux set_second_bottom_clip_bit = "cmp esi, ecx" "setg dl" modify exact [edx];

extern void save_projected_wall_endpoints(void);
#pragma aux save_projected_wall_endpoints = "mov dword ptr [esp + 0x68], eax" "mov eax, dword ptr [edi + xb1]" \
    "mov dword ptr [esp + 0x54], eax" "mov eax, dword ptr [edi + xb2]" \
    "mov dword ptr [esp + 0x50], eax" "mov eax, dword ptr [edi + yb2]" \
    "mov dword ptr [esp + 0x24], eax" "mov eax, dword ptr [edi + yb1]" \
    "mov dword ptr [esp + 0x30], eax" "mov eax, dword ptr [esp + 0x6c]" \
    "mov dword ptr [esp + 0x38], eax" "mov eax, dword ptr [esp + 0x68]" \
    "mov dword ptr [esp + 4], esi" modify exact [eax];

extern void read_span_clip_frame(void);
#pragma aux read_span_clip_frame = "mov ecx, dword ptr [esp + 0x50]" "mov dword ptr [esp + 0x1c], eax" \
    "mov eax, dword ptr [esp + 0x54]" "mov edx, dword ptr [esp]" modify exact [eax ecx edx];

extern void read_top_clip_bits(void);
#pragma aux read_top_clip_bits = "mov eax, dword ptr [esp + 0x1c]" modify exact [eax];

extern void choose_wallmost_clipper(void);
#pragma aux choose_wallmost_clipper = "cmp eax, 3" "db 75h, 46h" modify exact [eax ebx ecx edx esi edi];

void wallmost_clip_flags(void);
#pragma aux wallmost_clip_flags aborts;

void wallmost_clip_flags(void)
{
    /* Set the clipping flags and prepare the visible column positions. */
    in_bx(yb2[from_bp()]);
    in_si(from_si() + from_ax());
    in_ax(wall_clip_top);
    in_ax(scale20(from_ax(), from_bx()));
    save_first_top_clip_limit();
    in_bx(yb1[from_bp()]);
    in_ax(wall_clip_top);
    in_ax(scale20(from_ax(), from_bx()));
    in_di(from_ax());
    save_second_top_clip_limit();
    in_bx(yb2[from_bp()]);
    in_ax(wall_clip_bottom);
    in_ax(scale20(from_ax(), from_bx()));
    save_first_bottom_clip_limit();
    in_bx(yb1[from_bp()]);
    in_ax(wall_clip_bottom);
    in_ax(scale20(from_ax(), from_bx()));
    set_first_top_clip_bit();
    in_dx(from_dx() & 0xff);
    read_left_projected_height();
    in_dx(from_dx() * 2);
    set_second_top_clip_bit();
    in_ax(from_ax() & 0xff);
    read_first_bottom_clip_limit();
    in_ax(from_ax() + from_dx());
    set_first_bottom_clip_bit();
    in_dx(from_dx() & 0xff);
    in_dx(from_dx() << 2);
    read_second_bottom_clip_limit();
    in_ax(from_ax() + from_dx());
    set_second_bottom_clip_bit();
    in_dx(from_dx() & 0xff);
    in_dx(from_dx() << 3);
    in_di(from_bp());
    in_ax(from_ax() + from_dx());
    in_di(from_di() << 2);
    save_projected_wall_endpoints();
    in_ax(from_ax() & 3);
    read_span_clip_frame();
    in_cx(from_cx() - from_ax());
    in_bx(from_ax() * 2);
    in_cx(from_cx() * 2);
    read_top_clip_bits();
    in_cx(from_cx() + 2);
    in_bx(from_bx() + from_dx());
    choose_wallmost_clipper();
    in_di(from_bx());
    in_ax(0);
}
