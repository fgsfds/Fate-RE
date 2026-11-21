/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern long globalhoriz, view_height, viewingrange_scaled;
extern long xb1[], xb2[], yb1[], yb2[];

#define AT_BYTE_OFFSET(values, offset) (*(long *)((char *)(values) + (offset)))

/* The paths below share the register save and clipping coordinates. */
extern void wallmost_fill_clipped(void);
extern void wallmost_check_bottom(void);
extern void wallmost_clip_top(void);
extern void wallmost_fill_top(void);
extern void wallmost_clip_bottom(void);
extern void wallmost_fill_bottom(void);
extern void wallmost_interpolate(void);
extern void wallmost_read_flags(void);
extern void wallmost_restore(void);

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

extern void finish_fully_clipped_wall(void);
#pragma aux finish_fully_clipped_wall = "jmp wallmost_read_flags" aborts modify exact [];

void wallmost_fill_clipped(void);
#pragma aux wallmost_fill_clipped aborts;

void wallmost_fill_clipped(void)
{
    /* Fill every column of a wholly clipped sloped wall. */
    FILL_CLIPPED_COLUMNS();
    finish_fully_clipped_wall();
}

extern void read_bottom_clip_flags(void);
#pragma aux read_bottom_clip_flags = "mov eax, dword ptr [esp + 0x68]" modify exact [eax];

extern void select_full_height_destination(void);
#pragma aux select_full_height_destination = "mov edi, ebx" modify exact [eax edi];

extern void fill_bottom_clipped_wall(void);
#pragma aux fill_bottom_clipped_wall = "db 0ebh, 9eh" /* marker-rel8 -10,-9 */ aborts modify exact [];

void wallmost_check_bottom(void);
#pragma aux wallmost_check_bottom aborts;

void wallmost_check_bottom(void)
{
    /* Use the full pixel height when both ends are below the viewport. */
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
#pragma aux read_top_boundary = "test byte ptr [esp + 0x68], 3" "je wallmost_clip_bottom" "mov ebx, dword ptr [esp + 0x18]" \
    "mov edx, dword ptr [esp + 8]" "mov ecx, dword ptr [esp + 0x6c]" modify exact [ebx ecx edx eax];

extern void divide_top_clip_fraction(void);
#pragma aux divide_top_clip_fraction = "mov edx, eax" "sar edx, 2" "shl eax, 0x1e" "idiv ebx" modify exact [eax edx];

extern void read_top_height_difference(void);
#pragma aux read_top_height_difference = "mov dword ptr [esp + 0x58], edx" "mov eax, esi" "sub eax, dword ptr [esp + 0x6c]" modify exact [edx eax];

extern void read_second_top_height(void);
#pragma aux read_second_top_height = "mov edx, dword ptr [esp + 0x6c]" modify exact [eax edx];

extern void save_top_intersection(void);
#pragma aux save_top_intersection = "mov dword ptr [esp + 0x4c], edx" "mov dword ptr [esp + 0x14], eax" modify exact [eax edx];

extern void read_top_intersection_depth(void);
#pragma aux read_top_intersection_depth = "mov ecx, dword ptr [esp + 0x58]" modify exact [ecx];

extern void project_top_intersection(void);
#pragma aux project_top_intersection = "mov ebx, dword ptr [esp + 0x14]" "imul ebx" "idiv ecx" modify exact [eax ebx edx];

extern void read_top_clip_edge(void);
#pragma aux read_top_clip_edge = "mov edx, dword ptr [esp + 0x1c]" modify exact [edx];

extern void adjust_top_right_boundary(void);
#pragma aux adjust_top_right_boundary = "cmp edx, 2" "db 75h, 2bh" /* marker-rel8 +4 */ "cmp eax, ecx" "jl branch_6cf" "mov esi, dword ptr [esp + 0x4c]" \
    "mov edx, dword ptr [esp + 0x58]" "mov dword ptr [esp + 0x50], eax" \
    "mov dword ptr [esp + 0x30], edx" "branch_6cf:" modify exact [eax edx esi];

extern void trim_top_right_columns(void);
#pragma aux trim_top_right_columns = "sub ecx, eax" modify exact [ecx];

extern void read_wall_output_for_top(void);
#pragma aux read_wall_output_for_top = "mov ebx, dword ptr [esp]" modify exact [ebx];

extern void fill_top_right_edge(void);
#pragma aux fill_top_right_edge = "db 0ebh, 34h" /* marker-rel8 +2,+3 */ modify exact [];

extern void adjust_top_left_boundary(void);
#pragma aux adjust_top_left_boundary = "cmp eax, dword ptr [edi + xb2]" "jg branch_702" "mov edx, dword ptr [esp + 0x4c]" \
    "mov dword ptr [esp + 0x6c], edx" "mov edx, dword ptr [esp + 0x58]" \
    "mov dword ptr [esp + 0x54], eax" "mov dword ptr [esp + 0x24], edx" "branch_702:" modify exact [eax ecx edx];

extern void locate_top_left_clip(void);
#pragma aux locate_top_left_clip = "add edi, dword ptr [esp]" modify exact [edi];

void wallmost_clip_top(void);
#pragma aux wallmost_clip_top aborts;

void wallmost_clip_top(void)
{
    /* Intersect the sloped edge with the top clip plane and trim the output range. */
    read_top_boundary();
    in_bx(from_bx() - from_dx());
    in_ax(from_cx());
    in_bx(from_bx() + from_cx());
    in_ax(from_ax() - from_dx());
    in_bx(from_bx() - from_si());
    divide_top_clip_fraction();
    in_cx(from_ax());
    in_bx(AT_BYTE_OFFSET(yb2, from_di()));
    in_ax(AT_BYTE_OFFSET(yb1, from_di()));
    in_ax(from_ax() - from_bx());
    in_bx(from_cx());
    in_ax(scale30(from_ax(), from_bx()));
    in_dx(AT_BYTE_OFFSET(yb2, from_di()));
    in_dx(from_dx() + from_ax());
    read_top_height_difference();
    in_ax(scale30(from_ax(), from_bx()));
    read_second_top_height();
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
    in_cx(xb2[from_bp()]);
    trim_top_right_columns();
    in_ax(from_ax() * 2);
    read_wall_output_for_top();
    in_di(from_ax() + 2);
    in_cx(from_cx() * 2);
    in_di(from_di() + from_bx());
    fill_top_right_edge();
    adjust_top_left_boundary();
    in_ax(from_ax() - xb1[from_bp()]);
    in_ax(from_ax() * 2);
    in_di(xb1[from_bp()]);
    in_cx(from_ax() + 2);
    in_di(from_di() * 2);
    locate_top_left_clip();
}

void wallmost_fill_top(void);
#pragma aux wallmost_fill_top aborts;

void wallmost_fill_top(void)
{
    /* Clear sloped wall columns above the visible edge. */
    in_ax(0);
    FILL_CLIPPED_COLUMNS();
}

extern void read_bottom_boundary(void);
#pragma aux read_bottom_boundary = "test byte ptr [esp + 0x68], 0xc" "je wallmost_interpolate" "mov ebx, dword ptr [esp + 0x20]" \
    "mov ecx, dword ptr [esp + 0x28]" "mov edi, dword ptr [esp + 0x38]" \
    "mov edx, dword ptr [esp + 4]" modify exact [eax ebx ecx edx edi];

extern void divide_bottom_clip_fraction(void);
#pragma aux divide_bottom_clip_fraction = "mov edx, eax" "sar edx, 2" "shl eax, 0x1e" "idiv ebx" modify exact [eax edx];

extern void read_first_bottom_height(void);
#pragma aux read_first_bottom_height = "mov ebx, dword ptr [esp + 0x38]" modify exact [ebx];

extern void read_second_bottom_height(void);
#pragma aux read_second_bottom_height = "mov eax, dword ptr [esp + 4]" modify exact [eax];

extern void save_bottom_intersection_depth(void);
#pragma aux save_bottom_intersection_depth = "mov dword ptr [esp + 0x58], edx" modify exact [eax edx];

extern void read_first_height_for_projection(void);
#pragma aux read_first_height_for_projection = "mov edx, dword ptr [esp + 0x38]" modify exact [edx];

extern void save_bottom_intersection_height(void);
#pragma aux save_bottom_intersection_height = "mov dword ptr [esp + 0x4c], edx" modify exact [eax edx];

extern void save_bottom_span_width(void);
#pragma aux save_bottom_span_width = "mov dword ptr [esp + 0x14], eax" modify exact [eax];

extern void read_bottom_intersection_depth(void);
#pragma aux read_bottom_intersection_depth = "mov ecx, dword ptr [esp + 0x58]" modify exact [ecx];

extern void project_bottom_intersection(void);
#pragma aux project_bottom_intersection = "mov ebx, dword ptr [esp + 0x14]" "imul ebx" "idiv ecx" "mov edx, dword ptr [esp + 0x68]" modify exact [eax ebx edx];

extern void adjust_bottom_right_boundary(void);
#pragma aux adjust_bottom_right_boundary = "cmp edx, 8" "db 75h, 36h" /* marker-rel8 +3 */ "cmp eax, ebx" "jl branch_81b" "mov esi, dword ptr [esp + 0x4c]" \
    "mov dword ptr [esp + 0x30], ecx" "mov dword ptr [esp + 0x50], eax" "branch_81b:" modify exact [eax edx esi];

extern void load_bottom_right_output(void);
#pragma aux load_bottom_right_output = "mov ebp, dword ptr [esp]" modify exact [edx];

extern void fill_bottom_right_edge(void);
#pragma aux fill_bottom_right_edge = "db 0ebh, 41h" /* marker-rel8 +2,+3 */ modify exact [];

extern void adjust_bottom_left_boundary(void);
#pragma aux adjust_bottom_left_boundary = "cmp eax, dword ptr [edi + xb2]" "jg branch_85d" "mov edx, dword ptr [esp + 0x4c]" \
    "mov dword ptr [esp + 0x6c], edx" "mov edx, dword ptr [esp + 0x58]" \
    "mov dword ptr [esp + 0x54], eax" "mov dword ptr [esp + 0x24], edx" "branch_85d:" modify exact [eax edx];

extern void load_bottom_left_output(void);
#pragma aux load_bottom_left_output = "mov ebp, dword ptr [esp]" "sub eax, ebx" modify exact [eax];

void wallmost_clip_bottom(void);
#pragma aux wallmost_clip_bottom aborts;

void wallmost_clip_bottom(void)
{
    /* Intersect the sloped edge with the bottom clip plane and trim the output range. */
    read_bottom_boundary();
    in_bx(from_bx() - from_cx());
    in_ax(from_di());
    in_bx(from_bx() + from_di());
    in_ax(from_ax() - from_cx());
    in_bx(from_bx() - from_dx());
    in_di(from_bp());
    divide_bottom_clip_fraction();
    in_di(from_di() << 2);
    in_cx(from_ax());
    in_ax(AT_BYTE_OFFSET(yb1, from_di()));
    in_dx(AT_BYTE_OFFSET(yb2, from_di()));
    in_bx(from_cx());
    in_ax(from_ax() - from_dx());
    in_ax(scale30(from_ax(), from_bx()));
    in_dx(AT_BYTE_OFFSET(yb2, from_di()));
    read_first_bottom_height();
    in_dx(from_dx() + from_ax());
    read_second_bottom_height();
    in_ax(from_ax() - from_bx());
    in_bx(from_cx());
    save_bottom_intersection_depth();
    in_ax(scale30(from_ax(), from_bx()));
    read_first_height_for_projection();
    in_dx(from_dx() + from_ax());
    save_bottom_intersection_height();
    in_ax(AT_BYTE_OFFSET(xb2, from_di()));
    in_dx(AT_BYTE_OFFSET(xb1, from_di()));
    in_ax(from_ax() - from_dx());
    save_bottom_span_width();
    in_ax(AT_BYTE_OFFSET(yb1, from_di()));
    read_bottom_intersection_depth();
    in_ax(scale30(from_ax(), from_bx()));
    project_bottom_intersection();
    in_bx(AT_BYTE_OFFSET(xb1, from_di()));
    in_dx(from_dx() & 0xc);
    in_ax(from_ax() + from_bx());
    adjust_bottom_right_boundary();
    in_dx(view_height);
    in_bx(view_height);
    in_cx(xb2[from_bp()]);
    load_bottom_right_output();
    in_dx((unsigned long)from_dx() << 16);
    in_cx(from_cx() - from_ax());
    in_ax(from_ax() * 2);
    in_dx(from_dx() + from_bx());
    in_di(from_ax() + 2);
    in_cx(from_cx() * 2);
    fill_bottom_right_edge();
    adjust_bottom_left_boundary();
    in_dx(view_height);
    in_di(view_height);
    in_bx(xb1[from_bp()]);
    load_bottom_left_output();
    in_dx((unsigned long)from_dx() << 16);
    in_ax(from_ax() * 2);
    in_dx(from_dx() + from_di());
    in_cx(from_ax() + 2);
    in_di(from_bx() * 2);
}

void wallmost_fill_bottom(void);
#pragma aux wallmost_fill_bottom aborts;

void wallmost_fill_bottom(void)
{
    /* Fill sloped wall columns below the visible edge. */
    in_ax(from_dx());
    in_di(from_di() + from_bp());
    FILL_CLIPPED_COLUMNS();
}

extern void read_projection_start(void);
#pragma aux read_projection_start = "mov ecx, dword ptr [esp + 0x24]" "mov eax, dword ptr [esp + 0x6c]" modify exact [eax ecx];

extern void project_right_endpoint(void);
#pragma aux project_right_endpoint = "imul ebx" "idiv ecx" "mov ecx, dword ptr [esp + 0x30]" modify exact [eax ecx edx];

extern void project_left_endpoint(void);
#pragma aux project_left_endpoint = "imul ebx" "idiv ecx" "mov ecx, dword ptr [esp + 0x50]" modify exact [eax ecx edx];

extern void read_left_column(void);
#pragma aux read_left_column = "mov eax, dword ptr [esp + 0x54]" modify exact [eax];

extern void compute_column_step(void);
#pragma aux compute_column_step = "mov eax, edx" "sar edx, 0x1f" "idiv ecx" "mov ebp, dword ptr [esp + 0x54]" "add ebp, ebp" \
    "add ebp, dword ptr [esp]" modify exact [eax edx];

extern void check_output_word_alignment(void);
#pragma aux check_output_word_alignment = "test ecx, ecx" "db 74h, 43h" /* marker-rel8 +5,+6 */ "test al, 2" "db 74h, 10h" /* marker-rel8 +2 */ modify exact [eax ecx edx];

extern void step_left_output_pixel(void);
#pragma aux step_left_output_pixel = "add edx, esi" modify exact [edx];

extern void advance_aligned_start(void);
#pragma aux advance_aligned_start = "dec ecx" "db 74h, 2fh" /* marker-rel8 +3,+4 */ "sub ecx, 2" "db 72h, 22h" /* marker-rel8 +3,+4 */ modify exact [eax ecx edx];

extern void step_first_output_pixel(void);
#pragma aux step_first_output_pixel = "add edx, esi" modify exact [edx];

extern void keep_next_column_high_word(void);
#pragma aux keep_next_column_high_word = "and edi, 0xffff0000" modify exact [edi];

extern void advance_output_pair(void);
#pragma aux advance_output_pair = "sub ecx, 2" "db 73h, 0e3h" /* marker-rel8 -3,-2 */ "test cl, 1" "db 74h, 08h" /* marker-rel8 0,+1 */ modify exact [eax ecx edx];

extern void read_left_endpoint(void);
#pragma aux read_left_endpoint = "mov eax, dword ptr [esp + 0x54]" "mov ecx, dword ptr [esp]" modify exact [eax ecx];

extern void clamp_left_endpoint(void);
#pragma aux clamp_left_endpoint = "movsx edx, word ptr [eax]" "cmp edx, esi" "jle branch_991" "mov dx, word ptr [view_height]" \
    "mov word ptr [eax], dx" "branch_991:" modify exact [eax edx esi];

extern void read_right_endpoint(void);
#pragma aux read_right_endpoint = "mov eax, dword ptr [esp + 0x50]" "mov edi, dword ptr [esp]" modify exact [eax edi];

extern void read_right_endpoint_limit(void);
#pragma aux read_right_endpoint_limit = "mov eax, dword ptr [esp + 0x50]" "mov ebp, dword ptr [esp]" modify exact [eax];

extern void clamp_right_endpoint(void);
#pragma aux clamp_right_endpoint = "movsx edx, word ptr [eax]" "cmp edx, ebx" "db 7eh, 0ah" /* marker-rel8 0,+1 */ "mov dx, word ptr [view_height]" \
    "mov word ptr [eax], dx" modify exact [eax edx];

void wallmost_interpolate(void);
#pragma aux wallmost_interpolate aborts;

void wallmost_interpolate(void)
{
    /* Interpolate sloped projected screen heights and clamp the endpoint columns. */
    read_projection_start();
    in_bx(viewingrange_scaled);
    project_right_endpoint();
    in_bx(viewingrange_scaled);
    in_di(from_ax());
    in_ax(from_si());
    in_di((unsigned long)from_di() << 4);
    project_left_endpoint();
    in_dx(from_ax());
    read_left_column();
    in_dx((unsigned long)from_dx() << 4);
    in_cx(from_cx() - from_ax());
    in_dx(from_dx() - from_di());
    in_cx(from_cx() + 1);
    compute_column_step();
    in_dx(globalhoriz);
    in_si(from_ax());
    in_dx((unsigned long)from_dx() << 16);
    in_ax(from_bp());
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
    if (*(short *)from_bp() < 0)
        *(short *)from_bp() = 0;
    read_left_endpoint();
    in_ax(from_ax() * 2);
    in_ax(from_ax() + from_cx());
    in_si(view_height);
    clamp_left_endpoint();
    read_right_endpoint();
    in_ax(from_ax() * 2);
    in_ax(from_ax() + from_di());
    if (*(short *)from_ax() < 0)
        *(short *)from_ax() = 0;
    read_right_endpoint_limit();
    in_ax(from_ax() * 2);
    in_ax(from_ax() + from_bp());
    in_bx(view_height);
    clamp_right_endpoint();
}

extern void read_clip_flags(void);
#pragma aux read_clip_flags = "mov eax, dword ptr [esp + 0x68]" modify exact [eax];

void wallmost_read_flags(void);
#pragma aux wallmost_read_flags aborts;

void wallmost_read_flags(void)
{
    /* Return the viewport clipping flags. */
    read_clip_flags();
}

extern void restore_wall_projection_frame(void);
#pragma aux restore_wall_projection_frame = "add esp, 0x74" "pop ebp" "pop edi" "pop esi" "ret" aborts modify exact [eax];

void wallmost_restore(void);
#pragma aux wallmost_restore aborts;

void wallmost_restore(void)
{
    /* Restore the caller registers after flat or sloped projection. */
    restore_wall_projection_frame();
}
