/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern long globalorientation, globalx1, globalx2, globaly1, globaly2;
extern long globalxpanning, globalypanning, half_view_width, globalbufplc;
extern long lastx[];
extern short globalpicnum, upper_plane_edge[], lower_plane_edge[], lower_clip_edge[];
extern unsigned char picsiz[], tile_x_shift, tile_y_shift;

extern void sethlinesizes(void);
extern void hline(long x, long y);
#pragma aux hline parm [eax] [edx] modify exact [eax edx];
extern void ceilscan_run_timer(void);
#pragma aux ceilscan_run_timer aborts modify exact [];

/* Each stage shares the saved frame from the original floor scan entry. */
extern void florscan_flip_x(void);
#pragma aux florscan_flip_x aborts modify exact [];
extern void florscan_flip_y(void);
#pragma aux florscan_flip_y aborts modify exact [];
extern void florscan_begin_spans(void);
#pragma aux florscan_begin_spans aborts modify exact [];
extern void florscan_scan_column(void);
extern void florscan_empty_column(void);
extern void florscan_test_column(void);
#pragma aux florscan_test_column aborts modify exact [];
extern void florscan_finish_spans(void);

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

extern void read_tile_dimensions(void);
#pragma aux read_tile_dimensions = "movsx eax, word ptr [globalpicnum]" "mov dl, byte ptr [eax + picsiz]" "and dl, 0xf" \
    "mov dh, 8" "sub dh, dl" "mov al, byte ptr [eax + picsiz]" "mov byte ptr [tile_x_shift], dh" modify exact [eax edx];

extern void check_double_texture_scale(void);
#pragma aux check_double_texture_scale = "mov bh, byte ptr [globalorientation]" "mov byte ptr [tile_y_shift], dl" "test bh, 8" \
    "db 74h, 10h" /* marker-rel8 0,+1 */ modify exact [eax ebx edx];

extern unsigned char y_shift_in_dl(void);
#pragma aux y_shift_in_dl = "" value [dl] modify exact [];
extern unsigned char y_shift_in_ch(void);
#pragma aux y_shift_in_ch = "" value [ch] modify exact [];
extern void keep_y_shift_in_ch(unsigned char);
#pragma aux keep_y_shift_in_ch = "" parm [ch] modify exact [];

/* Keep the C store before the next load and register copy. No emitted code. */
extern void finish_transpose_store(void);
#pragma aux finish_transpose_store = "" modify exact [edx];

void florscan_texture(void);
#pragma aux florscan_texture aborts;

void florscan_texture(void)
{
    /* Choose floor texture shifts and transpose the axes when requested. */
    read_tile_dimensions();
    in_ax(from_ax() & 0xff);
    in_dx(8);
    in_ax(from_ax() >> 4);
    in_dx(from_dx() - from_ax());
    check_double_texture_scale();
    ++*(volatile unsigned char *)&tile_x_shift;
    keep_y_shift_in_ch(y_shift_in_dl());
    keep_y_shift_in_ch(y_shift_in_ch() + 1);
    *(volatile unsigned char *)&tile_y_shift = y_shift_in_ch();
    in_ax(*(volatile long *)&globalorientation);
    in_ax(from_ax() & 4);
    if (from_ax() <= 0)
        florscan_flip_x();
    in_ax(globalypanning);
    in_cx(globalxpanning);
    globalxpanning = from_ax();
    globalypanning = from_cx();
    in_ax(globaly1);
    in_cx(globalx2);
    globalx2 = from_ax();
    *(volatile long *)&globaly1 = from_cx();
    finish_transpose_store();
    in_dx(from_cx());
    in_cx(globalx1);
    in_ax(-from_ax());
    in_dx(-from_dx());
    globalx2 = from_ax();
    in_ax(*(volatile long *)&globaly2);
    globaly1 = from_dx();
    globalx1 = from_ax();
    globaly2 = from_cx();
}

void florscan_flip_x(void);
#pragma aux florscan_flip_x aborts;

void florscan_flip_x(void)
{
    /* Flip texture coordinates on the horizontal axis when requested. */
    in_ax(globalorientation);
    in_ax(from_ax() & 0x10);
    if (from_ax() <= 0)
        florscan_flip_y();
    in_bx(globalx1);
    in_cx(globaly1);
    in_si(globalxpanning);
    in_bx(-from_bx());
    in_cx(-from_cx());
    in_si(-from_si());
    globalx1 = from_bx();
    globaly1 = from_cx();
    globalxpanning = from_si();
}

void florscan_flip_y(void);
#pragma aux florscan_flip_y aborts;

void florscan_flip_y(void)
{
    /* Flip texture coordinates on the vertical axis when requested. */
    in_ax(globalorientation);
    in_ax(from_ax() & 0x20);
    if (from_ax() <= 0)
        florscan_begin_spans();
    in_di(globalx2);
    in_ax(globaly2);
    in_dx(globalypanning);
    in_di(-from_di());
    in_ax(-from_ax());
    in_dx(-from_dx());
    globalx2 = from_di();
    globaly2 = from_ax();
    globalypanning = from_dx();
}

extern void read_x_axis_shift(void);
#pragma aux read_x_axis_shift = "mov bl, byte ptr [tile_x_shift]" modify exact [ebx];

extern void read_axis_counts(void);
#pragma aux read_axis_counts = "mov al, byte ptr [tile_y_shift]" "mov cl, bl" modify exact [eax ecx];

extern void scale_x_axes(void);
#pragma aux scale_x_axes = "shl esi, cl" "shl edi, cl" modify exact [esi edi];

extern void select_y_axis_count(void);
#pragma aux select_y_axis_count = "mov cl, al" modify exact [ecx];

extern void scale_y_axes(void);
#pragma aux scale_y_axes = "shl edx, cl" "shl esi, cl" "mov cl, bl" modify exact [ecx edx esi];

extern void scale_x_panning(void);
#pragma aux scale_x_panning = "shl edi, cl" "mov cl, al" modify exact [ecx edi];

extern void scale_y_panning(void);
#pragma aux scale_y_panning = "shl eax, cl" modify exact [eax];

extern void read_sector_x_panning(void);
#pragma aux read_sector_x_panning = "xor eax, eax" "mov al, byte ptr [ebp + 0x1e]" modify exact [eax];

extern void clear_y_panning_byte(void);
#pragma aux clear_y_panning_byte = "xor eax, eax" modify exact [eax];

extern void read_sector_y_panning(void);
#pragma aux read_sector_y_panning = "mov al, byte ptr [ebp + 0x1f]" modify exact [eax];

extern void read_raster_tile_size(void);
#pragma aux read_raster_tile_size = "mov bl, byte ptr [eax + picsiz]" "mov al, byte ptr [eax + picsiz]" "sar ebx, 4" \
    "and al, 0xf" "and eax, 0xff" "call sethlinesizes" modify exact [eax ebx ecx edx esi edi];

extern void read_first_floor_column(void);
#pragma aux read_first_floor_column = "mov eax, dword ptr [esp + 4]" modify exact [eax];

extern void select_first_floor_edge(void);
#pragma aux select_first_floor_edge = "mov dx, word ptr [eax + lower_plane_edge]" "mov bx, word ptr [eax + upper_plane_edge]" \
    "cmp dx, bx" "jle branch_581" "mov eax, edx" "jmp branch_583" "branch_581:" "mov eax, ebx" \
    "branch_583:" "movsx ebx, ax" "mov esi, dword ptr [esp + 4]" modify exact [eax ebx edx esi];

void florscan_begin_spans(void);
#pragma aux florscan_begin_spans aborts;

void florscan_begin_spans(void)
{
    /* Scale floor texture steps and initialize the horizontal span renderer. */
    read_x_axis_shift();
    in_si(globalx1);
    in_di(globaly1);
    read_axis_counts();
    in_dx(globalx2);
    scale_x_axes();
    globalx1 = from_si();
    globaly1 = from_di();
    select_y_axis_count();
    in_si(globaly2);
    in_di(globalxpanning);
    scale_y_axes();
    globalx2 = from_dx();
    scale_x_panning();
    in_ax(globalypanning);
    globaly2 = from_si();
    scale_y_panning();
    globalxpanning = from_di();
    globalypanning = from_ax();
    read_sector_x_panning();
    in_ax((unsigned long)from_ax() << 24);
    in_dx(from_di() + from_ax());
    in_cx(globaly1);
    globalxpanning = from_dx();
    clear_y_panning_byte();
    in_bx(globalypanning);
    read_sector_y_panning();
    in_dx(globalx1);
    in_ax((unsigned long)from_ax() << 24);
    in_dx(-from_dx());
    in_bx(from_bx() + from_ax());
    in_dx(from_dx() - from_cx());
    in_ax(half_view_width);
    in_dx(from_ax() * from_dx());
    globaly1 = from_dx();
    in_dx(globalx2);
    in_dx(from_dx() - from_si());
    in_dx(from_dx() * from_ax());
    in_cx(globalbufplc);
    globalypanning = from_bx();
    in_bx(0);
    in_ax(globalpicnum);
    globalx2 = from_dx();
    read_raster_tile_size();
    read_first_floor_column();
    in_ax(from_ax() * 2);
    select_first_floor_edge();
    in_cx(from_bx());
    florscan_test_column();
}

extern void read_floor_column_edges(void);
#pragma aux read_floor_column_edges = "mov di, word ptr [eax + lower_plane_edge]" "mov dx, word ptr [eax + upper_plane_edge]" \
    "cmp di, dx" "jle branch_5ab" "mov eax, edi" "jmp branch_5ad" "branch_5ab:" "mov eax, edx" \
    "branch_5ad:" "movsx edi, ax" "movsx ebp, word ptr [esi*2 + lower_clip_edge]" "dec edi" modify exact [eax edx edi];

extern void select_column_shape(void);
#pragma aux select_column_shape = "cmp edi, eax" "jge florscan_empty_column" "cmp edi, ecx" "db 7ch, 18h" /* marker-rel8 +1,+2 */ modify exact [eax ebx ecx edx edi esi];

extern void skip_filled_upper_rows(void);
#pragma aux skip_filled_upper_rows = "db 0ebh, 1fh" /* marker-rel8 0,+1 */ modify exact [];

extern void check_new_lower_rows(void);
#pragma aux check_new_lower_rows = "cmp ecx, ebp" "db 7dh, 44h" /* marker-rel8 +3,+4 */ modify exact [eax ecx];

extern void repeat_new_lower_rows(void);
#pragma aux repeat_new_lower_rows = "db 0ebh, 0f2h" /* marker-rel8 -1 */ aborts modify exact [];

void florscan_scan_column(void);
#pragma aux florscan_scan_column aborts;

void florscan_scan_column(void)
{
    /* Close completed horizontal spans and record the start columns of newly visible rows. */
    in_ax(from_si() * 2);
    read_floor_column_edges();
    in_ax(from_bp() - 1);
    select_column_shape();
    for (;;) {
        in_ax(from_cx() - 1);
        if (from_bx() >= from_ax())
            break;
        in_bx(from_bx() + 1);
        in_ax(from_si() - 1);
        hline(from_ax(), from_bx());
    }
    in_bx(from_di());
    skip_filled_upper_rows();
    while (from_bx() < from_di()) {
        in_bx(from_bx() + 1);
        in_ax(from_si() - 1);
        hline(from_ax(), from_bx());
    }
    while (from_bx() > from_di()) {
        in_bx(from_bx() - 1);
        lastx[from_bx() + 1] = from_si();
    }
    while (from_cx() > from_bp()) {
        in_cx(from_cx() - 1);
        in_ax(from_si() - 1);
        hline(from_ax(), from_cx());
    }
    check_new_lower_rows();
    in_cx(from_cx() + 1);
    lastx[from_cx() - 1] = from_si();
    repeat_new_lower_rows();
}

extern void check_last_column(void);
#pragma aux check_last_column = "cmp esi, dword ptr [esp]" "db 74h, 2bh" /* marker-rel8 +2,+3 */ modify exact [eax ebx ecx];

extern void start_after_empty_column(void);
#pragma aux start_after_empty_column = "mov bx, word ptr [eax + lower_plane_edge+2]" "mov cx, word ptr [eax + upper_plane_edge+2]" \
    "cmp bx, cx" "jle branch_651" "mov eax, ebx" "jmp branch_653" "branch_651:" "mov eax, ecx" \
    "branch_653:" "movsx ebx, ax" "mov ecx, ebx" modify exact [eax ebx ecx];

void florscan_empty_column(void);
#pragma aux florscan_empty_column aborts;

void florscan_empty_column(void)
{
    /* Drain spans at an empty floor column before advancing. */
    for (;;) {
        in_ax(from_cx() - 1);
        if (from_bx() >= from_ax())
            break;
        in_bx(from_bx() + 1);
        in_ax(from_si() - 1);
        hline(from_ax(), from_bx());
    }
    check_last_column();
    in_ax(from_si() * 2);
    start_after_empty_column();
    in_si(from_si() + 1);
}

extern void continue_floor_columns(void);
#pragma aux continue_floor_columns = "cmp esi, dword ptr [esp]" "jle florscan_scan_column" modify exact [eax esi];

void florscan_test_column(void);
#pragma aux florscan_test_column aborts;

void florscan_test_column(void)
{
    /* Continue while a screen column remains. */
    continue_floor_columns();
}

extern void read_last_column(void);
#pragma aux read_last_column = "mov eax, dword ptr [esp]" modify exact [eax];

void florscan_finish_spans(void);
#pragma aux florscan_finish_spans aborts;

void florscan_finish_spans(void)
{
    /* Draw the final floor spans and jump to the shared timer. */
    for (;;) {
        in_ax(from_cx() - 1);
        if (from_bx() >= from_ax())
            ceilscan_run_timer();
        in_bx(from_bx() + 1);
        read_last_column();
        hline(from_ax(), from_bx());
    }
}
