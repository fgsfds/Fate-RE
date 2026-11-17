/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern unsigned char sector[], chainstat, pow2char[], mirror_scanline[];
extern long mirror_z, mirror_row, transarea;
extern short mirror_sector;
extern long window_top, window_bottom, window_left, window_right;
extern long chainplace, frameplace, ylookup[];

extern void faketimerhandler(void);
#pragma aux faketimerhandler modify exact [eax];
extern void write_vga_byte(unsigned port, unsigned value);
#pragma aux write_vga_byte = "out dx, al" parm [edx] [eax] modify exact [];
extern void completemirror_restore(void);
#pragma aux completemirror_restore aborts modify exact [];

extern void check_planar_bounds(void);
#pragma aux check_planar_bounds modify exact [];

extern void check_linear_bounds(void);
#pragma aux check_linear_bounds modify exact [];

extern void check_linear_row(void);
#pragma aux check_linear_row modify exact [];

extern void reverse_linear_row(void);
#pragma aux reverse_linear_row modify exact [];

/* Register bindings emit no instructions and preserve values shared with the
 * original stack-resident bounds and planar pixel-copy kernels. */
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

extern void begin_mirror_reversal(void);
#pragma aux begin_mirror_reversal = "push ebx" "push ecx" "push edx" "push esi" "push edi" "push ebp" "sub esp, 0x10" \
    modify exact [eax edx];

extern void save_initial_left(void);
#pragma aux save_initial_left = "mov [esp + 8], eax" modify exact [eax];
extern void check_planar_aperture(void);
#pragma aux check_planar_aperture = "cmp edx, dword ptr [eax + sector + 4]" "jle check_planar_bounds" \
    "cmp edx, dword ptr [eax + sector + 8]" "jge check_planar_bounds" modify exact [eax edx];

/* The original mirror cursor slots survive the VGA port and byte reads. */
extern void read_planar_left_bounds(void);
#pragma aux read_planar_left_bounds = "mov eax, [esp + 0xc]" "mov ebp, [esp + 8]" modify exact [eax];
extern void advance_planar_left_bound(void);
#pragma aux advance_planar_left_bound = "lea ecx, [ebp + 1]" "mov [esp + 8], ecx" modify exact [ecx];
extern void start_planar_right_scan(void);
#pragma aux start_planar_right_scan = "mov esi, [esp + 8]" modify exact [esi];
extern void load_right_plane_column(void);
#pragma aux load_right_plane_column = "mov edx, [esp + 0xc]" modify exact [edx];
extern void read_planar_marker_byte(void);
#pragma aux read_planar_marker_byte = "mov al, [edx]" modify exact [eax];
extern void retreat_planar_right_bound(void);
#pragma aux retreat_planar_right_bound = "dec dword ptr [esp + 0xc]" modify exact [];

extern void store_planar_left_clamp(void);
#pragma aux store_planar_left_clamp = "mov [esp + 8], ebx" modify exact [];
extern void store_planar_right_clamp(void);
#pragma aux store_planar_right_clamp = "mov [esp + 0xc], esi" modify exact [];

extern void check_planar_edge_order(void);
#pragma aux check_planar_edge_order = "mov eax, dword ptr [esp + 0xc]" "mov edi, dword ptr [esp + 8]" "cmp eax, edi" \
    "jl near completemirror_restore" modify exact [eax edi];

extern void save_planar_row_cursor(void);
#pragma aux save_planar_row_cursor = "mov dword ptr [esp + 4], ebx" modify exact [];

extern void begin_plane_iteration(void);
#pragma aux begin_plane_iteration = "mov ebx, [esp + 0xc]" "sub ebx, [esp + 8]" "xor ebp, ebp" modify exact [ebx eax ecx];

extern void load_planar_read_bounds(void);
#pragma aux load_planar_read_bounds = "mov eax, dword ptr [esp + 0xc]" "mov ecx, dword ptr [esp + 8]" modify exact [eax ecx];

extern void calculate_read_span(void);
#pragma aux calculate_read_span = "sub eax, ecx" modify exact [eax];

extern void stage_planar_read_port(void);
#pragma aux stage_planar_read_port = "mov [esp], eax" "mov eax, ecx" "mov edx, 0x3cf" modify exact [eax edx];

extern void load_planar_read_addresses(void);
#pragma aux load_planar_read_addresses = "mov eax, dword ptr [esp + 4]" "mov edi, offset mirror_scanline" \
    "mov edx, dword ptr [chainplace]" "mov esi, dword ptr [eax*4 + ylookup]" modify exact [eax edi edx esi ecx];

extern void read_planar_bytes(void);
#pragma aux read_planar_bytes = "mov ecx, dword ptr [esp]" "test cl, 1" "je local_branch_1b6" "movsb" "local_branch_1b6:" \
    "shr ecx, 2" "jae local_branch_1bd" "movsw" "local_branch_1bd:" "rep movsd" \
    "mov edi, dword ptr [esp]" modify exact [edi esi ecx ebx];

extern void advance_plane_buffer(void);
#pragma aux advance_plane_buffer = "add ebp, edi" modify exact [eax ebx ecx];

extern void load_planar_write_bounds(void);
#pragma aux load_planar_write_bounds = "mov ecx, dword ptr [esp + 0xc]" "mov eax, dword ptr [esp + 8]" modify exact [ecx eax];

extern void read_planar_write_bit(void);
#pragma aux read_planar_write_bit = "mov al, [edx + pow2char]" modify exact [eax edx];
extern void load_planar_write_row(void);
#pragma aux load_planar_write_row = "mov edi, [esp + 4]" modify exact [edi eax edx];

extern void advance_planar_write_scratch(void);
#pragma aux advance_planar_write_scratch = "add ebp, ecx" modify exact [eax edi edx esi];
extern void load_planar_write_scratch(void);
#pragma aux load_planar_write_scratch = "lea esi, [ebp - 1]" modify exact [esi ebx];

/* Keep EDX out of the loop count allocation so Watcom uses ECX. */
extern long reverse_scanline_dword(long value);
#pragma aux reverse_scanline_dword = "bswap eax" parm [eax] value [eax] modify exact [eax edx];
extern void reverse_bytes_on_plane(void);
#pragma aux reverse_bytes_on_plane = "shr ecx, 1" "jae local_branch_259" "mov al, byte ptr [esi]" "dec esi" \
    "mov byte ptr [edi], al" "inc edi" "local_branch_259:" "shr ecx, 1" "jae local_branch_26e" \
    "mov ax, word ptr [esi - 1]" "sub esi, 2" "ror ax, 8" "mov word ptr [edi], ax" "add edi, 2" \
    "local_branch_26e:" modify exact [eax ecx edi esi];

extern void read_next_planar_row(void);
#pragma aux read_next_planar_row = "mov ebp, [esp + 4]" "inc ebp" modify exact [eax];
extern void save_next_planar_row(void);
#pragma aux save_next_planar_row = "mov [esp + 4], ebp" modify exact [];

extern void read_planar_row_cursor(void);
#pragma aux read_planar_row_cursor = "mov eax, [esp + 4]" modify exact [eax];
extern void finish_planar_mirror(void);
#pragma aux finish_planar_mirror = "jmp near completemirror_restore" aborts modify exact [];

extern void check_linear_aperture(void);
#pragma aux check_linear_aperture = "cmp edx, dword ptr [eax + sector + 4]" "jle check_linear_bounds" \
    "cmp edx, dword ptr [eax + sector + 8]" "jge check_linear_bounds" modify exact [];
extern void reset_left_bound(void);
#pragma aux reset_left_bound = "mov [esp + 8], edx" modify exact [];
extern void save_initial_right(void);
#pragma aux save_initial_right = "mov [esp + 0xc], eax" modify exact [eax];

/* Cursor slots are shared with the later reversal loops. */
extern void load_left_cursor(void);
#pragma aux load_left_cursor = "mov eax, [esp + 8]" modify exact [eax];
extern void load_right_cursor(void);
#pragma aux load_right_cursor = "mov eax, [esp + 0xc]" modify exact [eax];
extern void load_left_limit(void);
#pragma aux load_left_limit = "mov ecx, [esp + 8]" modify exact [ecx];
extern void load_right_scan_limit(void);
#pragma aux load_right_scan_limit = "mov edi, [esp + 8]" modify exact [edi eax];
extern void save_left_cursor(void);
#pragma aux save_left_cursor = "mov [esp + 8], esi" modify exact [esi];
extern void advance_right_cursor(void);
#pragma aux advance_right_cursor = "lea ebp, [eax - 1]" "mov [esp + 0xc], ebp" modify exact [eax];
extern void read_marker_byte(void);
#pragma aux read_marker_byte = "mov al, byte ptr [edx + eax]" modify exact [eax];

extern void load_left_clamp(void);
#pragma aux load_left_clamp = "mov ebp, [esp + 8]" modify exact [];
extern void save_clamped_left(void);
#pragma aux save_clamped_left = "mov [esp + 8], eax" modify exact [];

extern void load_right_clamp(void);
#pragma aux load_right_clamp = "mov ebx, [esp + 0xc]" modify exact [ebx];
extern void save_clamped_right(void);
#pragma aux save_clamped_right = "mov [esp + 0xc], ecx" modify exact [];

extern void load_right_alignment_byte(void);
#pragma aux load_right_alignment_byte = "mov dl, [esp + 0xc]" modify exact [edx];
extern unsigned char read_right_alignment_byte(void);
#pragma aux read_right_alignment_byte = value [dl] modify exact [];
extern void keep_right_alignment_byte(unsigned char value);
#pragma aux keep_right_alignment_byte = "" parm [dl] modify exact [];
extern void save_right_alignment_byte(void);
#pragma aux save_right_alignment_byte = "mov [esp + 0xc], dl" modify exact [];
extern void cap_right_alignment(void);
#pragma aux cap_right_alignment = "cmp eax, [esp + 0xc]" "jge aligned_bounds" "mov [esp + 0xc], eax" "aligned_bounds:" modify exact [];

extern void check_linear_edge_order(void);
#pragma aux check_linear_edge_order = "mov eax, dword ptr [esp + 0xc]" "mov edx, dword ptr [esp + 8]" "cmp eax, edx" \
    "jl near completemirror_restore" modify exact [eax edx];

extern void load_linear_window_top(void);
#pragma aux load_linear_window_top = "mov esi, [window_top]" modify exact [ebx ecx esi];

extern void load_linear_y_offset(void);
#pragma aux load_linear_y_offset = "mov ebp, [esi*4 + ylookup]" modify exact [edx esi];
extern void save_linear_row_count(void);
#pragma aux save_linear_row_count = "mov [esp + 4], ecx" modify exact [edi];

extern void load_linear_viewport_end(void);
#pragma aux load_linear_viewport_end = "mov edi, dword ptr [esp + 0xc]" modify exact [edi];

extern void save_linear_span(void);
#pragma aux save_linear_span = "mov ebp, dword ptr [window_right]" "mov dword ptr [esp + 0xc], ebx" modify exact [];

extern void reflect_linear_destination_start(void);
#pragma aux reflect_linear_destination_start = "sub ebp, esi" modify exact [ebx];

extern void begin_linear_row_loop(void);
#pragma aux begin_linear_row_loop = "sub ebp, edi" "jmp check_linear_row" modify exact [eax];

extern void load_linear_source_and_scratch(void);
#pragma aux load_linear_source_and_scratch = "mov esi, dword ptr [esp + 8]" "mov edi, offset mirror_scanline" modify exact [esi edi ebx];

extern void copy_linear_row_to_scratch(void);
#pragma aux copy_linear_row_to_scratch = "test cl, 1" "je local_branch_426" "movsb" "local_branch_426:" "shr ecx, 2" \
    "jae local_branch_42d" "movsw" "local_branch_42d:" "rep movsd" modify exact [ecx edi esi];

extern void load_replicated_pixel_slots(void);
#pragma aux load_replicated_pixel_slots = "mov eax, [esp + 0xc]" "mov ecx, [esp + 0xc]" modify exact [eax ecx esi];

extern void load_linear_last_visible_pixel(void);
#pragma aux load_linear_last_visible_pixel = "mov al, byte ptr [eax + mirror_scanline - 1]" modify exact [eax];

extern void replicate_linear_last_visible_pixel(void);
#pragma aux replicate_linear_last_visible_pixel = "mov byte ptr [ecx + mirror_scanline], al" modify exact [];

extern void reverse_linear_bytes(void);
#pragma aux reverse_linear_bytes = "shr ecx, 1" "jae local_branch_459" "mov al, byte ptr [esi]" "dec esi" \
    "mov byte ptr [edi], al" "inc edi" "local_branch_459:" "shr ecx, 1" "jae local_branch_46e" \
    "mov ax, word ptr [esi - 1]" "sub esi, 2" "ror ax, 8" "mov word ptr [edi], ax" "add edi, 2" \
    "local_branch_46e:" modify exact [eax ecx edi esi];

extern void read_linear_row_cursor(void);
#pragma aux read_linear_row_cursor = "mov edi, dword ptr [esp + 4]" "mov esi, dword ptr [ylookup + 4]" "call faketimerhandler" modify exact [edi esi eax];

extern void finish_linear_row_loop(void);
#pragma aux finish_linear_row_loop = "mov dword ptr [esp + 4], edi" "cmp dword ptr [esp + 4], 0" "jge reverse_linear_row" \
    "jmp near completemirror_restore" aborts modify exact [eax];

void completemirror(void);
#pragma aux completemirror aborts;

void completemirror(void)
{
    long remaining;
    begin_mirror_reversal();
    if (!chainstat)
        goto linear_backend;
    write_vga_byte(0x3ce, 4);
    write_vga_byte(0x3c4, 2);
    /* Find the marked bounds in the four VGA planes. */
    in_ax(window_left);
    save_initial_left();
    in_ax(window_right);
    in_dx(mirror_sector);
    save_initial_right();
    in_ax(40 * from_dx());
    in_dx(mirror_z);
    check_planar_aperture();
    /* Locate the first visible pixel using the planar read selector. */
    for (;;) {
        read_planar_left_bounds();
        if (from_ax() < from_bp())
            break;
        in_ax(from_bp());
        in_dx(0x3cf);
        in_ax(from_ax() & 3);
        write_vga_byte(from_dx(), from_ax());
        in_dx(mirror_row);
        in_ax(chainplace);
        in_bx(ylookup[from_dx()]);
        in_dx(from_bp());
        in_ax(from_ax() + from_bx());
        in_dx(from_dx() >> 2);
        in_dx(from_dx() + from_ax());
        in_ax(0);
        read_planar_marker_byte();
        if (from_ax() != 255)
            break;
        advance_planar_left_bound();
    }

    /* Scan the opposite edge without changing the left limit. */
    start_planar_right_scan();
    for (;;) {
        load_right_cursor();
        if (from_ax() < from_si())
            break;
        in_dx(0x3cf);
        in_ax(from_ax() & 3);
        write_vga_byte(from_dx(), from_ax());
        in_dx(mirror_row);
        in_ax(chainplace);
        in_di(ylookup[from_dx()]);
        load_right_plane_column();
        in_ax(from_ax() + from_di());
        in_dx(from_dx() >> 2);
        in_dx(from_dx() + from_ax());
        in_ax(0);
        read_planar_marker_byte();
        if (from_ax() != 255)
            break;
        retreat_planar_right_bound();
    }

    /* Restore one border pixel where the marker narrowed the span. */
    load_left_cursor();
    if (from_ax() > window_left) {
        in_bx(from_ax() - 1);
        store_planar_left_clamp();
    }
    load_right_cursor();
    if (from_ax() < window_right) {
        in_si(from_ax() + 1);
        store_planar_right_clamp();
    }
    /* Account for the visible mirror rectangle. */
    check_planar_edge_order();
    in_bx(window_top);
    in_dx(from_ax());
    in_ax(window_bottom);
    in_dx(from_dx() - from_di());
    in_ax(from_ax() - from_bx());
    in_ax(from_ax() * from_dx());
    in_cx(transarea);
    in_cx(from_cx() + from_ax());
    save_planar_row_cursor();
    transarea = from_cx();
    goto test_planar_row;
planar_row:
    /* Read the row into scratch one plane at a time. */
    begin_plane_iteration();
    if (from_bx() >= 3)
        in_bx(3);
    goto test_plane_read;
copy_plane_in:
    load_planar_read_bounds();
    in_ax(from_ax() + 1);
    in_cx(from_cx() + from_bx());
    calculate_read_span();
    in_ax(from_ax() + 3);
    in_ax(from_ax() >> 2);
    /* Retain the original read count across the port selection. */
    stage_planar_read_port();
    in_ax(from_ax() & 3);
    write_vga_byte(from_dx(), from_ax());
    load_planar_read_addresses();
    in_cx(from_cx() >> 2);
    in_si(from_si() + from_dx());
    in_di(from_di() + from_bp());
    in_si(from_si() + from_cx());
    read_planar_bytes();
    in_bx(from_bx() - 1);
    advance_plane_buffer();
test_plane_read:
    if (from_bx() >= 0)
        goto copy_plane_in;
    /* Recalculate the destination plane and write pixels in reverse order. */
    begin_plane_iteration();
    if (from_bx() >= 3)
        in_bx(3);
    goto test_plane_write;
copy_plane_out:
    load_planar_write_bounds();
    in_cx(from_cx() + 1);
    in_ax(from_ax() + from_bx());
    in_dx(window_left);
    in_cx(from_cx() - from_ax());
    in_si(window_right);
    in_cx(from_cx() + 3);
    in_si(from_si() + from_dx());
    in_cx(from_cx() >> 2);
    in_si(from_si() - from_ax());
    in_ax(from_cx());
    in_ax(from_ax() << 2);
    in_ax(from_ax() - 4);
    in_si(from_si() - from_ax());
    in_dx(from_si() & 3);
    read_planar_write_bit();
    in_dx(0x3c5);
    in_ax(from_ax() & 255);
    load_planar_write_row();
    write_vga_byte(from_dx(), from_ax());
    /* Address the destination plane and end of the buffered source. */
    advance_planar_write_scratch();
    in_dx(chainplace);
    in_ax(ylookup[from_di()]);
    in_di(from_si());
    in_ax(from_ax() + from_dx());
    load_planar_write_scratch();
    in_di(from_di() >> 2);
    in_si(from_si() + (long)mirror_scanline);
    in_di(from_di() + from_ax());
    in_bx(from_bx() - 1);
    reverse_bytes_on_plane();
    remaining = from_cx();
    if (remaining != 0) {
        do {
            in_ax(*(const long *)(from_si() - 3));
            in_si(from_si() - 4);
            in_ax(reverse_scanline_dword(from_ax()));
            *(long *)from_di() = from_ax();
            in_di(from_di() + 4);
        } while (--remaining != 0);
    }
test_plane_write:
    if (from_bx() >= 0)
        goto copy_plane_out;
    read_next_planar_row();
    faketimerhandler();
    save_next_planar_row();
test_planar_row:
    read_planar_row_cursor();
    if (from_ax() <= window_bottom)
        goto planar_row;
    finish_planar_mirror();

linear_backend:
    /* The linear framebuffer uses byte offsets and the row stride. */
    in_ax(window_right);
    in_dx(0);
    in_bx(window_left);
    reset_left_bound();
    in_ax(from_ax() - from_bx());
    in_dx(mirror_sector);
    save_initial_right();
    in_ax(40 * from_dx());
    in_dx(mirror_z);
    check_linear_aperture();
    in_dx(mirror_row);
    in_ax(frameplace);
    in_ax(from_ax() + ylookup[from_dx()]);
    in_dx(from_bx() + from_ax());
    /* Trim the linear rectangle to the marker edges. */
    for (;;) {
        load_left_cursor();
        read_marker_byte();
        if ((from_ax() & 255) != 255)
            break;
        load_right_cursor();
        load_left_limit();
        if (from_ax() < from_cx())
            break;
        in_si(from_cx() + 1);
        save_left_cursor();
    }

    load_right_scan_limit();
    for (;;) {
        load_right_cursor();
        read_marker_byte();
        if ((from_ax() & 255) != 255)
            break;
        load_right_cursor();
        if (from_ax() < from_di())
            break;
        advance_right_cursor();
    }

    load_left_clamp();
    if (from_bp() > 0) {
        in_ax(from_bp() - 1);
        save_clamped_left();
    }
    in_ax(window_right);
    in_dx(window_left);
    load_right_clamp();
    in_ax(from_ax() - from_dx());
    if (from_ax() > from_bx()) {
        in_cx(from_bx() + 1);
        save_clamped_right();
    }
    load_right_alignment_byte();
    in_ax(window_right);
    keep_right_alignment_byte(read_right_alignment_byte() | 3);
    in_si(window_left);
    save_right_alignment_byte();
    in_ax(from_ax() - from_si());
    cap_right_alignment();
    check_linear_edge_order();
    in_cx(window_bottom);
    in_bx(from_ax());
    load_linear_window_top();
    in_bx(from_bx() - from_dx());
    in_cx(from_cx() - from_si());
    in_ax(from_bx() * from_cx());
    in_di(transarea);
    load_linear_y_offset();
    in_dx(window_left);
    in_si(window_left);
    save_linear_row_count();
    in_di(from_di() + from_ax());
    in_ax(frameplace);
    transarea = from_di();
    load_linear_viewport_end();
    in_ax(from_ax() + from_bp());
    save_linear_span();
    in_dx(from_dx() + from_ax());
    reflect_linear_destination_start();
    in_bx(from_bx() + 1);
    begin_linear_row_loop();
    /* Copy into scratch before reversing the overlapping destination. */
    load_linear_source_and_scratch();
    in_si(from_si() + 1);
    in_cx(from_bx());
    in_si(from_si() + from_dx());
    copy_linear_row_to_scratch();
    load_replicated_pixel_slots();
    in_si((long)mirror_scanline);
    in_di(from_dx() + from_bp());
    load_linear_last_visible_pixel();
    in_si(from_si() + from_cx());
    replicate_linear_last_visible_pixel();
    in_cx(from_bx());
    reverse_linear_bytes();
    remaining = from_cx();
    if (remaining != 0) {
        do {
            in_ax(*(const long *)(from_si() - 3));
            in_si(from_si() - 4);
            in_ax(reverse_scanline_dword(from_ax()));
            *(long *)from_di() = from_ax();
            in_di(from_di() + 4);
        } while (--remaining != 0);
    }
    read_linear_row_cursor();
    in_di(from_di() - 1);
    in_dx(from_dx() + from_si());
    finish_linear_row_loop();
}
