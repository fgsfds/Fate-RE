/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern long globalhoriz, view_height, viewingrange_scaled;
extern long wall_clip_top, wall_clip_bottom;
extern long xb1[], xb2[], yb1[], yb2[];

#define AT_BYTE_OFFSET(values, offset) (*(long *)((char *)(values) + (offset)))

/* The paths below share the register save and clipping coordinates. */
extern void owallmost_fill_clipped(void);
extern void owallmost_check_bottom(void);
extern void owallmost_clip_top(void);
extern void owallmost_fill_top(void);
extern void owallmost_clip_bottom(void);
extern void owallmost_fill_bottom(void);
extern void owallmost_interpolate(void);
extern void owallmost_return(void);

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

/* The byte and word stores align EDI before a doubleword fill. */
extern void align_clear_dwords(void);
#pragma aux align_clear_dwords = "test edi, 1" "je check_word_alignment" "stosb" "dec ecx" \
    "check_word_alignment:" "test edi, 2" "je aligned" "stosw" "sub ecx, 2" "aligned:" \
   modify exact [ecx edi];

extern void store_clear_byte(void);
#pragma aux store_clear_byte = "stosb" modify exact [edi];

extern void store_clear_word(void);
#pragma aux store_clear_word = "stosw" modify exact [edi];

extern void store_clear_words(void);
#pragma aux store_clear_words = "db 0f3h" "stosw" modify exact [ecx edi];

extern void store_clear_dwords(void);
#pragma aux store_clear_dwords = "rep stosd" modify exact [ecx edi];

extern long scale20(long value, long factor);
#pragma aux scale20 = "imul ebx" "shrd eax, edx, 20" \
    parm nomemory [eax] [ebx] value [eax] modify exact [eax edx];

extern long scale30(long value, long factor);
#pragma aux scale30 = "imul ebx" "shrd eax, edx, 30" \
    parm nomemory [eax] [ebx] value [eax] modify exact [eax edx];

#define FILL_CLIPPED_COLUMNS() do { \
    if ((unsigned long)from_cx() < 4) { \
        if (from_cx() & 1) \
            store_clear_byte(); \
        in_cx((unsigned long)from_cx() >> 1); \
        store_clear_words(); \
    } else { \
        align_clear_dwords(); \
        in_bx(from_cx()); \
        in_cx((unsigned long)from_cx() >> 2); \
        store_clear_dwords(); \
        if (from_bx() & 2) \
            store_clear_word(); \
        if (from_bx() & 1) \
            store_clear_byte(); \
    } \
} while (0)

extern void setup_projection_frame(void);
#pragma aux setup_projection_frame = "push ecx" "push esi" "push edi" "push ebp" "sub esp, 0x38" "mov ebp, eax" \
    "mov dword ptr [esp + 0x28], edx" modify exact [eax ebx ecx edx esi edi];

extern void save_top_right_limit(void);
#pragma aux save_top_right_limit = "mov dword ptr [esp + 0x10], eax" "mov ebx, dword ptr [edi*4 + yb1]" modify exact [eax ebx edx];

extern void save_top_left_limit(void);
#pragma aux save_top_left_limit = "mov dword ptr [esp + 4], eax" modify exact [eax ebx];

extern void save_bottom_right_limit(void);
#pragma aux save_bottom_right_limit = "mov dword ptr [esp + 0x18], eax" "mov ebx, dword ptr [edi*4 + yb1]" modify exact [eax ebx edx];

extern void save_bottom_left_limit(void);
#pragma aux save_bottom_left_limit = "mov dword ptr [esp + 8], eax" "cmp esi, ecx" "setl al" "mov edx, eax" "and edx, 0xff" modify exact [eax edx];

extern void read_top_right_limit(void);
#pragma aux read_top_right_limit = "mov ebx, dword ptr [esp + 0x10]" modify exact [ebx];

extern void read_bottom_right_limit(void);
#pragma aux read_bottom_right_limit = "mov ecx, dword ptr [esp + 0x18]" modify exact [ecx];

extern void read_bottom_left_limit(void);
#pragma aux read_bottom_left_limit = "mov edi, dword ptr [esp + 8]" modify exact [edi];

extern void read_original_scan(void);
#pragma aux read_original_scan = "mov edi, dword ptr [esp + 0x28]" modify exact [edi];

extern void save_wall_clipping_state(void);
#pragma aux save_wall_clipping_state = "mov eax, dword ptr [edi + xb1]" "mov dword ptr [esp + 0x2c], eax" \
    "mov eax, dword ptr [edi + yb2]" "mov dword ptr [esp + 0x1c], eax" \
    "mov eax, dword ptr [edi + xb2]" "mov dword ptr [esp + 0x24], eax" \
    "mov eax, dword ptr [edi + yb1]" "mov dword ptr [esp + 0x20], eax" "mov eax, edx" \
    "mov dword ptr [esp + 0x34], edx" modify exact [eax edx];

extern void read_clipping_columns(void);
#pragma aux read_clipping_columns = "mov edx, dword ptr [esp + 0x2c]" "mov dword ptr [esp + 0xc], eax" \
    "mov eax, dword ptr [esp + 0x24]" "sub eax, edx" "add eax, eax" modify exact [eax edx];

extern void read_top_clip_flags(void);
#pragma aux read_top_clip_flags = "mov eax, dword ptr [esp + 0xc]" modify exact [eax];

extern void select_top_fill(void);
#pragma aux select_top_fill = "cmp eax, 3" "db 75h, 46h" /* marker-rel8 +7,+8 */ modify exact [eax ebx ecx edx esi edi];

extern void in_al(unsigned char);
#pragma aux in_al = parm [al] modify exact [];

void owallmost(void);
#pragma aux owallmost aborts;

void owallmost(void)
{
    /* Compare the projected endpoints with the top and bottom clip limits. */
    setup_projection_frame();
    in_si(from_bx());
    in_ax(wall_clip_top);
    in_bx(yb2[from_dx()]);
    in_di(from_dx());
    in_ax(scale20(from_ax(), from_bx()));
    save_top_right_limit();
    in_ax(wall_clip_top);
    in_ax(scale20(from_ax(), from_bx()));
    in_cx(from_ax());
    save_top_left_limit();
    in_bx(yb2[from_di()]);
    in_ax(wall_clip_bottom);
    in_ax(scale20(from_ax(), from_bx()));
    save_bottom_right_limit();
    in_ax(wall_clip_bottom);
    in_si((unsigned long)from_si() << 7);
    in_ax(scale20(from_ax(), from_bx()));
    save_bottom_left_limit();
    read_top_right_limit();
    in_dx(from_dx() * 2);
    in_al(from_si() < from_bx());
    in_ax(from_ax() & 0xff);
    read_bottom_right_limit();
    in_dx(from_dx() + from_ax());
    in_al(from_si() > from_cx());
    in_ax(from_ax() & 0xff);
    in_ax(from_ax() << 2);
    read_bottom_left_limit();
    in_dx(from_dx() + from_ax());
    in_al(from_si() > from_di());
    in_ax(from_ax() & 0xff);
    read_original_scan();
    in_ax(from_ax() << 3);
    in_di(from_di() << 2);
    in_dx(from_dx() + from_ax());
    save_wall_clipping_state();
    in_ax(from_ax() & 3);
    read_clipping_columns();
    in_cx(from_ax() + 2);
    in_bx(from_dx() * 2);
    read_top_clip_flags();
    in_bx(from_bx() + from_bp());
    select_top_fill();
    in_di(from_bx());
    in_ax(0);
}

extern void finish_fully_clipped_wall(void);
#pragma aux finish_fully_clipped_wall = "jmp owallmost_return" aborts modify exact [];

void owallmost_fill_clipped(void);
#pragma aux owallmost_fill_clipped aborts;

void owallmost_fill_clipped(void)
{
    /* Fill all columns of a wall outside the visible height. */
    FILL_CLIPPED_COLUMNS();
    finish_fully_clipped_wall();
}

extern void read_bottom_clip_flags(void);
#pragma aux read_bottom_clip_flags = "mov eax, dword ptr [esp + 0x34]" modify exact [eax];

extern void select_full_height_destination(void);
#pragma aux select_full_height_destination = "mov edi, ebx" modify exact [eax edi];

extern void fill_bottom_clipped_wall(void);
#pragma aux fill_bottom_clipped_wall = "db 0ebh, 9eh" /* marker-rel8 -10,-9 */ aborts modify exact [];

void owallmost_check_bottom(void);
#pragma aux owallmost_check_bottom aborts;

void owallmost_check_bottom(void)
{
    /* Fill a wholly bottom-clipped wall with the pixel height. */
    read_bottom_clip_flags();
    in_ax(from_ax() & 0xc);
    if (from_ax() == 0xc) {
        in_ax(view_height);
        in_si(view_height);
        in_ax((unsigned long)from_ax() << 16);
        select_full_height_destination();
        in_ax(from_ax() + from_si());
        fill_bottom_clipped_wall();
    }
}

extern void read_top_boundary(void);
#pragma aux read_top_boundary = "test byte ptr [esp + 0x34], 3" "je owallmost_clip_bottom" "mov ebx, dword ptr [esp + 4]" \
    "mov edx, dword ptr [esp + 0x10]" modify exact [ebx edx eax];

extern void divide_top_clip_fraction(void);
#pragma aux divide_top_clip_fraction = "mov edx, eax" "sar edx, 2" "shl eax, 0x1e" "idiv ebx" modify exact [eax edx];

extern void save_top_intersection(void);
#pragma aux save_top_intersection = "mov dword ptr [esp + 0x30], edx" "mov dword ptr [esp], eax" modify exact [eax edx];

extern void read_top_intersection_depth(void);
#pragma aux read_top_intersection_depth = "mov ecx, dword ptr [esp + 0x30]" modify exact [ecx];

extern void project_top_intersection(void);
#pragma aux project_top_intersection = "mov ebx, dword ptr [esp]" "imul ebx" "idiv ecx" modify exact [eax ebx edx];

extern void read_top_clip_edge(void);
#pragma aux read_top_clip_edge = "mov edx, dword ptr [esp + 0xc]" modify exact [edx];

extern void adjust_top_right_boundary(void);
#pragma aux adjust_top_right_boundary = "cmp edx, 2" "db 75h, 29h" /* marker-rel8 +2 */ "cmp eax, ecx" "jl branch_204" "mov edx, dword ptr [esp + 0x30]" \
    "mov dword ptr [esp + 0x24], eax" "mov dword ptr [esp + 0x20], edx" "branch_204:" \
    "mov edx, dword ptr [esp + 0x28]" modify exact [eax edx];

extern void fill_top_right_edge(void);
#pragma aux fill_top_right_edge = "db 0ebh, 2ah" /* marker-rel8 +1,+2 */ modify exact [];

extern void adjust_top_left_boundary(void);
#pragma aux adjust_top_left_boundary = "cmp eax, dword ptr [edi + xb2]" "jg branch_231" "mov edx, dword ptr [esp + 0x30]" \
    "mov dword ptr [esp + 0x2c], eax" "mov dword ptr [esp + 0x1c], edx" "branch_231:" \
    "mov ecx, dword ptr [esp + 0x28]" modify exact [eax ecx edx];

void owallmost_clip_top(void);
#pragma aux owallmost_clip_top aborts;

void owallmost_clip_top(void)
{
    /* Project the top clipping intersection and trim the visible column range. */
    read_top_boundary();
    in_ax(from_si());
    in_bx(from_bx() - from_dx());
    in_ax(from_ax() - from_dx());
    divide_top_clip_fraction();
    in_cx(from_ax());
    in_dx(AT_BYTE_OFFSET(yb2, from_di()));
    in_ax(AT_BYTE_OFFSET(yb1, from_di()));
    in_bx(from_cx());
    in_ax(from_ax() - from_dx());
    in_ax(scale30(from_ax(), from_bx()));
    in_dx(AT_BYTE_OFFSET(yb2, from_di()));
    in_bx(AT_BYTE_OFFSET(xb1, from_di()));
    in_dx(from_dx() + from_ax());
    in_ax(AT_BYTE_OFFSET(xb2, from_di()));
    in_ax(from_ax() - from_bx());
    save_top_intersection();
    in_bx(from_cx());
    in_ax(AT_BYTE_OFFSET(yb1, from_di()));
    read_top_intersection_depth();
    in_ax(scale30(from_ax(), from_bx()));
    project_top_intersection();
    in_cx(AT_BYTE_OFFSET(xb1, from_di()));
    read_top_clip_edge();
    in_ax(from_ax() + from_cx());
    adjust_top_right_boundary();
    in_cx(xb2[from_dx()]);
    in_cx(from_cx() - from_ax());
    in_ax(from_ax() * 2);
    in_ax(from_ax() + 2);
    in_cx(from_cx() * 2);
    in_di(from_ax() + from_bp());
    fill_top_right_edge();
    adjust_top_left_boundary();
    in_di(xb1[from_cx()]);
    in_ax(from_ax() - from_di());
    in_ax(from_ax() * 2);
    in_di(from_di() * 2);
    in_cx(from_ax() + 2);
    in_di(from_di() + from_bp());
}

void owallmost_fill_top(void);
#pragma aux owallmost_fill_top aborts;

void owallmost_fill_top(void)
{
    /* Clear columns above the visible top edge. */
    in_ax(0);
    FILL_CLIPPED_COLUMNS();
}

extern void read_bottom_boundary(void);
#pragma aux read_bottom_boundary = "test byte ptr [esp + 0x34], 0xc" "je owallmost_interpolate" "mov ebx, dword ptr [esp + 8]" \
    "mov ecx, dword ptr [esp + 0x18]" modify exact [eax ebx ecx];

extern void divide_bottom_clip_fraction(void);
#pragma aux divide_bottom_clip_fraction = "mov edi, dword ptr [esp + 0x28]" "mov edx, eax" "sar edx, 2" "shl eax, 0x1e" "idiv ebx" modify exact [edi eax edx];

extern void save_bottom_intersection(void);
#pragma aux save_bottom_intersection = "mov dword ptr [esp + 0x30], edx" "mov dword ptr [esp], eax" modify exact [eax edx];

extern void read_bottom_intersection_depth(void);
#pragma aux read_bottom_intersection_depth = "mov ecx, dword ptr [esp + 0x30]" modify exact [ecx];

extern void project_bottom_intersection(void);
#pragma aux project_bottom_intersection = "mov ebx, dword ptr [esp]" "imul ebx" "idiv ecx" "mov edx, dword ptr [esp + 0x34]" modify exact [eax ebx edx];

extern void adjust_bottom_right_boundary(void);
#pragma aux adjust_bottom_right_boundary = "cmp edx, 8" "db 75h, 3bh" /* marker-rel8 +3 */ "cmp eax, ecx" "jl branch_322" "mov edx, dword ptr [esp + 0x30]" \
    "mov dword ptr [esp + 0x24], eax" "mov dword ptr [esp + 0x20], edx" "branch_322:" modify exact [eax edx];

extern void read_bottom_right_scan(void);
#pragma aux read_bottom_right_scan = "mov ebx, dword ptr [esp + 0x28]" modify exact [ebx];

extern void fill_bottom_right_edge(void);
#pragma aux fill_bottom_right_edge = "db 0ebh, 3dh" /* marker-rel8 +1,+2 */ modify exact [];

extern void adjust_bottom_left_boundary(void);
#pragma aux adjust_bottom_left_boundary = "cmp eax, dword ptr [edi + xb2]" "jg branch_361" "mov edx, dword ptr [esp + 0x30]" \
    "mov dword ptr [esp + 0x2c], eax" "mov dword ptr [esp + 0x1c], edx" "branch_361:" \
    "mov edx, dword ptr [esp + 0x28]" modify exact [eax edx];

void owallmost_clip_bottom(void);
#pragma aux owallmost_clip_bottom aborts;

void owallmost_clip_bottom(void)
{
    /* Project the bottom clipping intersection and trim the visible column range. */
    read_bottom_boundary();
    in_ax(from_si());
    in_bx(from_bx() - from_cx());
    in_ax(from_ax() - from_cx());
    divide_bottom_clip_fraction();
    in_di(from_di() << 2);
    in_cx(from_ax());
    in_dx(AT_BYTE_OFFSET(yb2, from_di()));
    in_ax(AT_BYTE_OFFSET(yb1, from_di()));
    in_bx(from_cx());
    in_ax(from_ax() - from_dx());
    in_ax(scale30(from_ax(), from_bx()));
    in_dx(AT_BYTE_OFFSET(yb2, from_di()));
    in_bx(AT_BYTE_OFFSET(xb1, from_di()));
    in_dx(from_dx() + from_ax());
    in_ax(AT_BYTE_OFFSET(xb2, from_di()));
    in_ax(from_ax() - from_bx());
    save_bottom_intersection();
    in_bx(from_cx());
    in_ax(AT_BYTE_OFFSET(yb1, from_di()));
    read_bottom_intersection_depth();
    in_ax(scale30(from_ax(), from_bx()));
    project_bottom_intersection();
    in_cx(AT_BYTE_OFFSET(xb1, from_di()));
    in_dx(from_dx() & 0xc);
    in_ax(from_ax() + from_cx());
    adjust_bottom_right_boundary();
    in_dx(view_height);
    in_bx(view_height);
    in_dx((unsigned long)from_dx() << 16);
    in_dx(from_dx() + from_bx());
    read_bottom_right_scan();
    in_cx(xb2[from_bx()]);
    in_cx(from_cx() - from_ax());
    in_ax(from_ax() * 2);
    in_di(from_ax() + 2);
    in_cx(from_cx() * 2);
    in_ax(from_dx());
    in_di(from_di() + from_bp());
    fill_bottom_right_edge();
    adjust_bottom_left_boundary();
    in_bx(view_height);
    in_cx(view_height);
    in_di(xb1[from_dx()]);
    in_bx((unsigned long)from_bx() << 16);
    in_ax(from_ax() - from_di());
    in_bx(from_bx() + from_cx());
    in_ax(from_ax() * 2);
    in_di(from_di() * 2);
    in_cx(from_ax() + 2);
    in_di(from_di() + from_bp());
    in_ax(from_bx());
}

void owallmost_fill_bottom(void);
#pragma aux owallmost_fill_bottom aborts;

void owallmost_fill_bottom(void)
{
    /* Fill columns below the visible bottom edge with the pixel height. */
    FILL_CLIPPED_COLUMNS();
}

extern void read_right_depth(void);
#pragma aux read_right_depth = "mov ecx, dword ptr [esp + 0x1c]" modify exact [ecx];

extern void project_right_endpoint(void);
#pragma aux project_right_endpoint = "imul ebx" "idiv ecx" "mov ecx, dword ptr [esp + 0x20]" modify exact [eax ecx edx];

extern void project_left_endpoint(void);
#pragma aux project_left_endpoint = "imul ebx" "idiv ecx" "mov ecx, dword ptr [esp + 0x24]" modify exact [eax ecx edx];

extern void read_left_column(void);
#pragma aux read_left_column = "mov esi, dword ptr [esp + 0x2c]" modify exact [esi];

extern void compute_column_step(void);
#pragma aux compute_column_step = "mov eax, edx" "sar edx, 0x1f" "idiv ecx" modify exact [eax edx];

extern void save_output_start(void);
#pragma aux save_output_start = "mov dword ptr [esp + 0x14], esi" modify exact [eax esi];

extern void read_output_start(void);
#pragma aux read_output_start = "mov eax, dword ptr [esp + 0x14]" modify exact [eax];

extern void check_output_word_alignment(void);
#pragma aux check_output_word_alignment = "test ecx, ecx" "db 74h, 43h" /* marker-rel8 +6 */ "test al, 2" "db 74h, 10h" /* marker-rel8 +2 */ modify exact [eax ecx edx];

extern void step_left_output_pixel(void);
#pragma aux step_left_output_pixel = "add edx, esi" modify exact [edx];

extern void advance_aligned_start(void);
#pragma aux advance_aligned_start = "dec ecx" "db 74h, 2fh" /* marker-rel8 +4 */ "sub ecx, 2" "db 72h, 22h" /* marker-rel8 +3,+4 */ modify exact [eax ecx edx];

extern void step_first_output_pixel(void);
#pragma aux step_first_output_pixel = "add edx, esi" modify exact [edx];

extern void keep_next_column_high_word(void);
#pragma aux keep_next_column_high_word = "and edi, 0xffff0000" modify exact [edi];

extern void advance_output_pair(void);
#pragma aux advance_output_pair = "sub ecx, 2" "db 73h, 0e3h" /* marker-rel8 -3,-2 */ "test cl, 1" "db 74h, 08h" /* marker-rel8 +1 */ modify exact [eax ecx edx];

extern void read_output_left_edge(void);
#pragma aux read_output_left_edge = "mov eax, dword ptr [esp + 0x14]" modify exact [eax];

extern void read_left_endpoint(void);
#pragma aux read_left_endpoint = "mov eax, dword ptr [esp + 0x2c]" modify exact [eax];

extern void clamp_left_endpoint(void);
#pragma aux clamp_left_endpoint = "movsx edx, word ptr [eax]" "cmp edx, edi" "jle branch_495" "mov dx, word ptr [view_height]" \
    "mov word ptr [eax], dx" "branch_495:" modify exact [eax edx edi];

extern void read_right_endpoint(void);
#pragma aux read_right_endpoint = "mov eax, dword ptr [esp + 0x24]" modify exact [eax];

extern void read_right_endpoint_limit(void);
#pragma aux read_right_endpoint_limit = "mov eax, dword ptr [esp + 0x24]" modify exact [eax];

extern void clamp_right_endpoint(void);
#pragma aux clamp_right_endpoint = "add ebp, eax" "mov edx, dword ptr [view_height]" "movsx eax, word ptr [ebp]" "cmp eax, edx" \
    "db 7eh, 0ah" /* marker-rel8 0,+1 */ "mov ax, word ptr [view_height]" "mov word ptr [ebp], ax" modify exact [eax edx];

void owallmost_interpolate(void);
#pragma aux owallmost_interpolate aborts;

void owallmost_interpolate(void)
{
    /* Interpolate projected rows in column order and clamp both visible endpoints. */
    read_right_depth();
    in_bx(viewingrange_scaled);
    in_ax(from_si());
    project_right_endpoint();
    in_bx(viewingrange_scaled);
    in_di(from_ax());
    in_ax(from_si());
    in_di((unsigned long)from_di() << 4);
    project_left_endpoint();
    in_dx(from_ax());
    read_left_column();
    in_dx((unsigned long)from_dx() << 4);
    in_cx(from_cx() - from_si());
    in_dx(from_dx() - from_di());
    in_cx(from_cx() + 1);
    compute_column_step();
    in_bx(from_si() * 2);
    in_si(from_bx() + from_bp());
    save_output_start();
    in_dx(globalhoriz);
    in_si(from_ax());
    in_dx((unsigned long)from_dx() << 16);
    read_output_start();
    in_dx(from_dx() + from_di());
    check_output_word_alignment();
    in_bx(from_dx());
    in_bx(from_bx() >> 16);
    *(short *)from_ax() = (short)from_bx();
    step_left_output_pixel();
    in_ax(from_ax() + 2);
    advance_aligned_start();
    in_bx(from_dx());
    step_first_output_pixel();
    in_bx(from_bx() >> 16);
    in_di(from_dx());
    keep_next_column_high_word();
    in_dx(from_dx() + from_si());
    in_bx(from_bx() + from_di());
    *(long *)from_ax() = from_bx();
    in_ax(from_ax() + 4);
    advance_output_pair();
    in_bx(from_dx());
    in_bx(from_bx() >> 16);
    *(short *)from_ax() = (short)from_bx();
    read_output_left_edge();
    if (*(short *)from_ax() < 0)
        *(short *)from_ax() = 0;
    read_left_endpoint();
    in_ax(from_ax() * 2);
    in_ax(from_ax() + from_bp());
    in_di(view_height);
    clamp_left_endpoint();
    read_right_endpoint();
    in_ax(from_ax() * 2);
    in_ax(from_ax() + from_bp());
    if (*(short *)from_ax() < 0)
        *(short *)from_ax() = 0;
    read_right_endpoint_limit();
    in_ax(from_ax() * 2);
    clamp_right_endpoint();
}

extern void restore_wall_projection_frame(void);
#pragma aux restore_wall_projection_frame = "mov eax, dword ptr [esp + 0x34]" "add esp, 0x38" "pop ebp" "pop edi" "pop esi" "pop ecx" \
    "ret" aborts modify exact [eax];

void owallmost_return(void);
#pragma aux owallmost_return aborts;

void owallmost_return(void)
{
    /* Return the clip flags and restore the caller registers. */
    restore_wall_projection_frame();
}
