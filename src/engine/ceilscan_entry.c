/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern long wall[], waloff[], palookup[], current_palookup;
extern short globalpicnum, tilesizx[], tilesizy[];
extern unsigned short sqrtable[];
extern unsigned char picanm[], walock[], gotpic[], pow2char[], sector[];
extern long globalzd, globalorientation, globalbufplc, globalshade, base_plane_visibility, globvis;
extern long globalx1, globalx2, globaly1, globaly2, globalxpanning, globalypanning;
extern long camera_x, camera_y, camera_z, view_ray_x, view_ray_y;
/* The x87 conversion reads and writes the shared renderer scratch word. */
extern volatile union {
    long integer;
    float real;
    unsigned char bytes[4];
} ceiling_sqrt_scratch;

#define AT_BYTE_OFFSET(values, offset) (*(long *)((char *)(values) + (offset)))

extern void setpalookupaddress(void);
extern void animateoffs(void);
extern void loadtile(void);
extern void ceilscan_texture(void);
extern void ceilscan_restore_stack(void);
extern void ceilscan_check_height(void);
extern void ceilscan_animate_tile(void);
extern void ceilscan_require_tile(void);
extern void ceilscan_touch_tile(void);
extern void ceilscan_flat_axes(void);
extern void ceilscan_wall_axes(void);
extern void ceilscan_wall_length(void);
extern void ceilscan_project_axes(void);

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

extern long scale4(long value, long factor);
#pragma aux scale4 = "imul ebx" "shrd eax, edx, 4" \
    parm nomemory [eax] [ebx] value [eax] modify exact [eax edx];

extern long scale10(long value, long factor);
#pragma aux scale10 = "imul ebx" "shrd eax, edx, 10" \
    parm nomemory [eax] [ebx] value [eax] modify exact [eax edx];

extern long sum_products10(long a, long b, long c, long d);
#pragma aux sum_products10 = "imul ebx" "xchg esi, eax" "mov ebx, edx" "imul edi" \
    "add eax, esi" "adc edx, ebx" "shrd eax, edx, 10" \
    parm nomemory [eax] [ebx] [esi] [edi] value [eax] modify exact [eax ebx edx esi];

extern long sum_products14(long a, long b, long c, long d);
#pragma aux sum_products14 = "imul ebx" "xchg esi, eax" "mov ebx, edx" "imul edi" \
    "add eax, esi" "adc edx, ebx" "shrd eax, edx, 14" \
    parm nomemory [eax] [ebx] [esi] [edi] value [eax] modify exact [eax ebx edx esi];

extern void save_ceiling_frame(void);
#pragma aux save_ceiling_frame = "push ecx" "push esi" "push edi" "push ebp" "sub esp, 0xc" "push eax" "push edx" \
    "movsx ecx, bx" modify exact [eax ebx ecx edx esi edi];

extern void read_sector_table(void);
#pragma aux read_sector_table = "mov ebp, offset sector" modify exact [];

extern void read_ceiling_palette_index(void);
#pragma aux read_ceiling_palette_index = "add ebp, eax" "xor eax, eax" "mov al, byte ptr [ebp + 0x15]" modify exact [eax];

extern void check_palette_change(void);
#pragma aux check_palette_change = "cmp edx, ecx" "db 74h, 0dh" /* marker-rel8 +1,+2 */ modify exact [eax ecx edx];

extern void apply_ceiling_palette(void);
#pragma aux apply_ceiling_palette = "call setpalookupaddress" modify exact [eax ebx ecx edx esi edi];

void ceilscan(void);
#pragma aux ceilscan aborts;

void ceilscan(void)
{
    /* Select the ceiling palette and save the original scan frame. */
    save_ceiling_frame();
    in_ax(from_cx());
    in_ax(from_ax() << 2);
    in_ax(from_ax() + from_cx());
    read_sector_table();
    in_ax(from_ax() << 3);
    read_ceiling_palette_index();
    in_ax(from_ax() << 2);
    in_cx(current_palookup);
    in_dx(AT_BYTE_OFFSET(palookup, from_ax()));
    check_palette_change();
    in_ax(from_dx());
    current_palookup = from_dx();
    apply_ceiling_palette();
}

extern void check_ceiling_plane_height(void);
#pragma aux check_ceiling_plane_height = "test eax, eax" "jg ceilscan_restore_stack" modify exact [eax ecx edx esi edi];

extern void read_ceiling_tile(void);
#pragma aux read_ceiling_tile = "mov ax, word ptr [ebp + 0x10]" "mov word ptr [globalpicnum], ax" "cwde" \
    "test eax, 0xfffff000" "db 74h, 09h" /* marker-rel8 0,+1 */ modify exact [eax edx];

void ceilscan_check_height(void);
#pragma aux ceilscan_check_height aborts;

void ceilscan_check_height(void)
{
    /* Reject an out-of-view plane and normalize the base tile index. */
    in_si(camera_z);
    in_ax(*(long *)(from_bp() + 4));
    in_ax(from_ax() - from_si());
    globalzd = from_ax();
    check_ceiling_plane_height();
    read_ceiling_tile();
    in_dx(0);
    globalpicnum = (short)from_dx();
}

extern void check_ceiling_tile_animation(void);
#pragma aux check_ceiling_tile_animation = "test byte ptr [eax*4 + picanm], 0xc0" "db 74h, 0fh" /* marker-rel8 0,+1 */ "movsx edx, bx" "call animateoffs" modify exact [eax ebx ecx edx];

void ceilscan_animate_tile(void);
#pragma aux ceilscan_animate_tile aborts;

void ceilscan_animate_tile(void)
{
    /* Select the animated ceiling tile frame when needed. */
    in_ax(globalpicnum);
    check_ceiling_tile_animation();
    globalpicnum += (short)from_ax();
}

extern void require_nonempty_ceiling_tile(void);
#pragma aux require_nonempty_ceiling_tile = "cmp word ptr [ebx + tilesizx], 0" "jle ceilscan_restore_stack" \
    "cmp word ptr [ebx + tilesizy], 0" "jle ceilscan_restore_stack" \
    "cmp dword ptr [eax*4 + waloff], 0" "db 75h, 05h" /* marker-rel8 +1,+2 */ modify exact [eax ebx ecx edx esi edi];

extern void load_ceiling_tile(void);
#pragma aux load_ceiling_tile = "call loadtile" modify exact [eax ebx ecx edx esi edi];

void ceilscan_require_tile(void);
#pragma aux ceilscan_require_tile aborts;

void ceilscan_require_tile(void)
{
    /* Require positive dimensions and load the ceiling image if necessary. */
    in_ax(globalpicnum);
    in_bx(from_ax() * 2);
    require_nonempty_ceiling_tile();
    load_ceiling_tile();
}

extern void read_ceiling_tile_lock(void);
#pragma aux read_ceiling_tile_lock = "mov ax, word ptr [globalpicnum]" "cwde" "mov ebx, eax" "cmp byte ptr [eax + walock], 0xc8" \
    "jae branch_0f6" "mov byte ptr [eax + walock], 0xc7" "branch_0f6:" modify exact [eax ebx];

extern void mark_ceiling_tile_used(void);
#pragma aux mark_ceiling_tile_used = "mov dl, byte ptr [eax + gotpic]" "mov bl, byte ptr [ebx + pow2char]" "or dl, bl" \
    "mov byte ptr [eax + gotpic], dl" modify exact [ebx edx];

extern void read_sector_visibility(void);
#pragma aux read_sector_visibility = "mov ch, byte ptr [ebp + 0x20]" "test ch, ch" "db 74h, 18h" /* marker-rel8 +1,+2 */ "mov al, ch" "xor ebx, ebx" \
    "add al, 0x10" "mov bl, al" modify exact [eax ebx ecx];

void ceilscan_touch_tile(void);
#pragma aux ceilscan_touch_tile aborts;

void ceilscan_touch_tile(void)
{
    /* Mark the texture used and scale visibility by the sector setting. */
    in_ax(globalpicnum);
    in_ax(waloff[from_ax()]);
    globalbufplc = from_ax();
    read_ceiling_tile_lock();
    in_ax((unsigned long)from_ax() >> 3);
    in_bx(from_bx() & 7);
    mark_ceiling_tile_used();
    in_ax(*(signed char *)(from_bp() + 0x14));
    globalshade = from_ax();
    in_ax(base_plane_visibility);
    globvis = from_ax();
    read_sector_visibility();
    in_ax(globvis);
    in_ax(scale4(from_ax(), from_bx()));
    globvis = from_ax();
}

extern void choose_wall_aligned_ceiling(void);
#pragma aux choose_wall_aligned_ceiling = "test byte ptr [globalorientation], 0x40" "db 75h, 47h" /* marker-rel8 +1,+2 */ modify exact [eax ebx ecx edx esi edi];

extern void begin_flat_ceiling_spans(void);
#pragma aux begin_flat_ceiling_spans = "jmp ceilscan_texture" aborts modify exact [];

void ceilscan_flat_axes(void);
#pragma aux ceilscan_flat_axes aborts;

void ceilscan_flat_axes(void)
{
    /* Build viewer-aligned axes and panning for a flat texture. */
    in_ax(*(short *)(from_bp() + 0xc));
    globalorientation = from_ax();
    choose_wall_aligned_ceiling();
    in_ax(view_ray_y);
    globalx1 = from_ax();
    globalx2 = from_ax();
    in_ax(view_ray_x);
    globaly1 = from_ax();
    globaly2 = from_ax();
    in_ax(camera_x);
    in_ax((unsigned long)from_ax() << 20);
    globalxpanning = from_ax();
    in_ax(camera_y);
    in_ax((unsigned long)from_ax() << 20);
    in_di(from_ax());
    globalypanning = from_ax();
    in_di(-from_di());
    globalypanning = from_di();
    begin_flat_ceiling_spans();
}

extern void read_first_ceiling_wall(void);
#pragma aux read_first_ceiling_wall = "movsx eax, word ptr [ebp]" "mov dword ptr [esp + 0xc], eax" modify exact [eax];

extern void read_first_ceiling_wall_point2(void);
#pragma aux read_first_ceiling_wall_point2 = "movsx ebx, word ptr [eax + wall+8]" modify exact [ebx];

extern void save_wall_axis_x(void);
#pragma aux save_wall_axis_x = "mov dword ptr [esp + 8], ecx" modify exact [];

extern void save_wall_axis_y(void);
#pragma aux save_wall_axis_y = "mov dword ptr [esp + 0x10], ebx" modify exact [];

extern void in_bl(unsigned char value);
#pragma aux in_bl = "" parm [bl] modify exact [];
extern void in_bx_word(unsigned short value);
#pragma aux in_bx_word = "" parm [bx] modify exact [];
extern void check_wall_length_exponent(void);
#pragma aux check_wall_length_exponent = "sub bl, 0x44" "db 7dh, 0ch" /* marker-rel8 +2,+2 */ modify exact [ebx];
extern void skip_scaled_wall_length(void);
#pragma aux skip_scaled_wall_length = "db 0ebh, 17h" /* marker-rel8 +2,+3 */ modify exact [];
extern void use_scaled_sqrt_index(void);
#pragma aux use_scaled_sqrt_index = "db 08dh, 0ch, 05dh, 00h, 00h, 00h, 00h" \
    "shr eax, cl" "mov cl, bl" modify exact [eax ebx ecx];
extern void shift_scaled_wall_root(void);
#pragma aux shift_scaled_wall_root = "shl ebx, cl" modify exact [ebx];

void ceilscan_wall_axes(void);
#pragma aux ceilscan_wall_axes aborts;

void ceilscan_wall_axes(void)
{
    /* Read the first sector wall and measure its length for texture alignment. */
    read_first_ceiling_wall();
    in_ax(from_ax() << 5);
    read_first_ceiling_wall_point2();
    in_bx(from_bx() << 5);
    in_si(AT_BYTE_OFFSET(wall, from_ax()));
    in_cx(AT_BYTE_OFFSET(wall, from_bx()));
    in_cx(from_cx() - from_si());
    in_dx(from_cx());
    in_dx(from_cx() * from_dx());
    in_di(AT_BYTE_OFFSET(wall, from_ax() + 4));
    in_bx(AT_BYTE_OFFSET(wall, from_bx() + 4));
    in_bx(from_bx() - from_di());
    in_ax(from_bx());
    in_ax(from_ax() * from_bx());
    save_wall_axis_x();
    in_ax(from_ax() + from_dx());
    save_wall_axis_y();
    ceiling_sqrt_scratch.integer = from_ax();
    /* Read the floating-point exponent to normalize large square-table inputs. */
    ceiling_sqrt_scratch.real = (float)ceiling_sqrt_scratch.integer;
    in_bl(ceiling_sqrt_scratch.bytes[3]);
    check_wall_length_exponent();
    in_bx(0);
    in_bx_word(sqrtable[from_ax()]);
    skip_scaled_wall_length();
    use_scaled_sqrt_index();
    in_bx(0);
    in_bx_word(sqrtable[from_ax()]);
    shift_scaled_wall_root();
}

extern void normalize_ceiling_wall_length(void);
#pragma aux normalize_ceiling_wall_length = "test ebx, ebx" "jne branch_22d" "mov ecx, 0x400" "db 0ebh, 0eh" /* marker-rel8 0,+1 */ "branch_22d:" \
    "mov eax, 0x100000" "mov edx, eax" "sar edx, 0x1f" "idiv ebx" "mov ecx, eax" modify exact [eax ecx edx];

void ceilscan_wall_length(void);
#pragma aux ceilscan_wall_length aborts;

void ceilscan_wall_length(void)
{
    /* Use the original scaled inverse length and degenerate-wall fallback. */
    in_bx((unsigned long)from_bx() >> 10);
    normalize_ceiling_wall_length();
}

extern void read_wall_aligned_axis(void);
#pragma aux read_wall_aligned_axis = "mov esi, dword ptr [esp + 0x10]" "mov eax, dword ptr [esp + 8]" modify exact [eax esi];

extern void read_unnormalized_y_axis(void);
#pragma aux read_unnormalized_y_axis = "mov esi, dword ptr [esp + 0x10]" modify exact [esi];

extern void read_unnormalized_x_axis(void);
#pragma aux read_unnormalized_x_axis = "mov eax, dword ptr [esp + 8]" modify exact [eax];

extern void read_axis_origin_wall(void);
#pragma aux read_axis_origin_wall = "mov esi, eax" "mov eax, dword ptr [esp + 0xc]" modify exact [eax esi];

extern void save_unflipped_x_axis(void);
#pragma aux save_unflipped_x_axis = "mov ecx, edx" modify exact [ecx];

extern void scale_axis_origin_index(void);
#pragma aux scale_axis_origin_index = "shl eax, 5" modify exact [eax];

extern void subtract_camera_y(void);
#pragma aux subtract_camera_y = "sub eax, edx" modify exact [eax];

extern void save_x_axis_origin(void);
#pragma aux save_x_axis_origin = "mov dword ptr [esp + 8], ebx" modify exact [];

extern void save_y_axis_origin(void);
#pragma aux save_y_axis_origin = "mov dword ptr [esp + 0x10], eax" modify exact [];

extern void read_y_axis_origin(void);
#pragma aux read_y_axis_origin = "mov esi, dword ptr [esp + 0x10]" modify exact [esi];

extern void read_x_axis_origin(void);
#pragma aux read_x_axis_origin = "mov eax, dword ptr [esp + 8]" modify exact [eax];

extern void project_x_axis_panning(void);
#pragma aux project_x_axis_panning = "imul edx, ecx" modify exact [edx];

extern void project_y_axis_panning(void);
#pragma aux project_y_axis_panning = "imul ebx, eax" modify exact [ebx];

void ceilscan_project_axes(void);
#pragma aux ceilscan_project_axes aborts;

void ceilscan_project_axes(void)
{
    /* Project the wall-aligned basis and texture panning before scanning spans. */
    read_wall_aligned_axis();
    in_di(view_ray_x);
    in_bx(view_ray_y);
    in_si(-from_si());
    in_ax(sum_products10(from_ax(), from_bx(), from_si(), from_di()));
    in_bx(from_cx());
    read_unnormalized_y_axis();
    in_ax(scale10(from_ax(), from_bx()));
    in_di(view_ray_y);
    in_bx(view_ray_x);
    globalx1 = from_ax();
    read_unnormalized_x_axis();
    in_ax(sum_products10(from_ax(), from_bx(), from_si(), from_di()));
    in_bx(from_cx());
    in_ax(scale10(from_ax(), from_bx()));
    in_dx(globalx1);
    in_di(camera_x);
    globaly1 = from_ax();
    globaly2 = from_ax();
    read_axis_origin_wall();
    globalx2 = from_dx();
    save_unflipped_x_axis();
    in_si(-from_si());
    in_dx(camera_y);
    in_cx(-from_cx());
    globaly2 = from_si();
    scale_axis_origin_index();
    globalx2 = from_cx();
    in_bx(AT_BYTE_OFFSET(wall, from_ax()));
    in_ax(AT_BYTE_OFFSET(wall, from_ax() + 4));
    in_bx(from_bx() - from_di());
    in_di(view_ray_y);
    in_bx((unsigned long)from_bx() << 6);
    subtract_camera_y();
    save_x_axis_origin();
    in_ax((unsigned long)from_ax() << 6);
    in_si(from_bx());
    in_bx(view_ray_x);
    in_si(-from_si());
    save_y_axis_origin();
    in_ax(sum_products14(from_ax(), from_bx(), from_si(), from_di()));
    read_y_axis_origin();
    in_di(view_ray_y);
    in_bx(view_ray_x);
    in_cx(from_ax());
    read_x_axis_origin();
    in_ax(sum_products14(from_ax(), from_bx(), from_si(), from_di()));
    in_dx(globalx1);
    project_x_axis_panning();
    in_bx(globaly1);
    project_y_axis_panning();
    in_ax(from_ax() * globalx2);
    in_dx(from_dx() - from_bx());
    in_cx(from_cx() * globaly2);
    in_cx(from_cx() + from_ax());
    globalxpanning = from_dx();
    globalypanning = from_cx();
}
