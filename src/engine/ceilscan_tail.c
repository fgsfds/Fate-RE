/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern long globalorientation, globalx1, globalx2, globaly1, globaly2;
extern long globalxpanning, globalypanning, half_view_width, globalbufplc;
extern long lastx[];
extern short globalpicnum, upper_plane_edge[], upper_clip_edge[], lower_clip_edge[];
extern unsigned char picsiz[], tile_x_shift, tile_y_shift;

extern void sethlinesizes(void);
extern void hline(long x, long y);
#pragma aux hline parm [eax] [edx] modify exact [eax edx];
extern void faketimerhandler(void);
#pragma aux faketimerhandler modify exact [];

/* Each stage shares the saved frame from the original ceiling scan entry. */
extern void ceilscan_flip_x(void);
#pragma aux ceilscan_flip_x aborts modify exact [];
extern void ceilscan_flip_y(void);
#pragma aux ceilscan_flip_y aborts modify exact [];
extern void ceilscan_begin_spans(void);
#pragma aux ceilscan_begin_spans aborts modify exact [];
extern void ceilscan_scan_column(void);
extern void ceilscan_empty_column(void);
extern void ceilscan_test_column(void);
#pragma aux ceilscan_test_column aborts modify exact [];
extern void ceilscan_finish_spans(void);
extern void ceilscan_run_timer(void);
#pragma aux ceilscan_run_timer aborts modify exact [];
extern void ceilscan_restore_stack(void);
#pragma aux ceilscan_restore_stack aborts modify exact [];

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
#pragma aux check_double_texture_scale = "mov ah, byte ptr [globalorientation]" "mov byte ptr [tile_y_shift], dl" "test ah, 8" \
    "db 74h, 0ch" /* marker-rel8 0,+1 */ modify exact [eax edx];

/* End the compiler's EDX lifetime after the volatile store so the following
 * register copy cannot be hoisted. This ABI constraint emits no instructions. */
extern void finish_transpose_store(void);
#pragma aux finish_transpose_store = "" modify exact [edx];

void ceilscan_texture(void);
#pragma aux ceilscan_texture aborts;

void ceilscan_texture(void)
{
    /* Choose texture shifts and transpose the axes when requested. */
    read_tile_dimensions();
    in_ax(from_ax() & 0xff);
    in_dx(8);
    in_ax(from_ax() >> 4);
    in_dx(from_dx() - from_ax());
    check_double_texture_scale();
    ++tile_x_shift;
    /* Keep a byte memory increment, rather than a DH load/increment/store. */
    ++*(volatile unsigned char *)&tile_y_shift;
    in_ax(globalorientation);
    in_ax(from_ax() & 4);
    if (from_ax() <= 0)
        ceilscan_flip_x();
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

void ceilscan_flip_x(void);
#pragma aux ceilscan_flip_x aborts;

void ceilscan_flip_x(void)
{
    /* Flip texture coordinates on the horizontal axis when requested. */
    in_ax(globalorientation);
    in_ax(from_ax() & 0x10);
    if (from_ax() <= 0)
        ceilscan_flip_y();
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

void ceilscan_flip_y(void);
#pragma aux ceilscan_flip_y aborts;

void ceilscan_flip_y(void)
{
    /* Flip texture coordinates on the vertical axis when requested. */
    in_ax(globalorientation);
    in_ax(from_ax() & 0x20);
    if (from_ax() <= 0)
        ceilscan_begin_spans();
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

/* Byte-width bindings preserve the untouched high register bits. */
extern unsigned char from_al(void);
#pragma aux from_al = value [al] modify exact [];
extern unsigned char from_bl(void);
#pragma aux from_bl = value [bl] modify exact [];
extern void in_cl(unsigned char);
#pragma aux in_cl = parm [cl] modify exact [];
extern void in_al(unsigned char);
#pragma aux in_al = parm [al] modify exact [];
extern void in_bl(unsigned char);
#pragma aux in_bl = parm [bl] modify exact [];

extern void shift_x_axis(void);
#pragma aux shift_x_axis = "shl ebx, cl" "shl esi, cl" modify exact [ebx esi];

extern void shift_y_axis(void);
#pragma aux shift_y_axis = "shl edi, cl" "shl edx, cl" modify exact [edi edx];

extern void scale_panning_offsets(void);
#pragma aux scale_panning_offsets = "shl esi, cl" "mov cl, bl" "xor eax, eax" "shl edi, cl" modify exact [eax ecx esi edi];

extern void read_sector_x_panning(void);
#pragma aux read_sector_x_panning = "mov al, byte ptr [ebp + 0x16]" modify exact [eax];

extern void clear_y_panning_byte(void);
#pragma aux clear_y_panning_byte = "xor eax, eax" modify exact [eax];

extern void read_sector_y_panning(void);
#pragma aux read_sector_y_panning = "mov al, byte ptr [ebp + 0x17]" modify exact [eax];

extern void read_raster_tile_size(void);
#pragma aux read_raster_tile_size = "mov bl, byte ptr [eax + picsiz]" "mov al, byte ptr [eax + picsiz]" "sar ebx, 4" \
    "and al, 0xf" "and eax, 0xff" "call sethlinesizes" modify exact [eax ebx ecx edx esi edi];

extern void read_first_column(void);
#pragma aux read_first_column = "mov ebx, dword ptr [esp + 4]" "movsx ebx, word ptr [ebx*2 + upper_plane_edge]" \
    "mov esi, dword ptr [esp + 4]" modify exact [ebx esi];

void ceilscan_begin_spans(void);
#pragma aux ceilscan_begin_spans aborts;

void ceilscan_begin_spans(void)
{
    /* Scale the texture steps and panning, then initialize the span renderer. */
    in_al(tile_x_shift);
    in_bx(globalx1);
    in_si(globaly1);
    in_di(globalx2);
    in_cl(from_al());
    in_dx(globaly2);
    shift_x_axis();
    globalx1 = from_bx();
    in_bl(tile_y_shift);
    globaly1 = from_si();
    in_cl(from_bl());
    in_si(globalxpanning);
    shift_y_axis();
    /* Keep these stores ahead of the next shift-count copy. */
    *(volatile long *)&globalx2 = from_di();
    *(volatile long *)&globaly2 = from_dx();
    in_cl(from_al());
    in_di(globalypanning);
    scale_panning_offsets();
    globalxpanning = from_si();
    globalypanning = from_di();
    read_sector_x_panning();
    in_ax((unsigned long)from_ax() << 24);
    in_dx(from_si() + from_ax());
    globalxpanning = from_dx();
    clear_y_panning_byte();
    in_cx(globaly1);
    read_sector_y_panning();
    in_dx(globalx1);
    in_ax((unsigned long)from_ax() << 24);
    in_dx(-from_dx());
    in_bx(from_di() + from_ax());
    in_dx(from_dx() - from_cx());
    in_ax(half_view_width);
    in_dx(from_ax() * from_dx());
    in_si(globaly2);
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
    read_first_column();
    in_cx(from_bx());
    ceilscan_test_column();
}

extern void read_column_clip_edges(void);
#pragma aux read_column_clip_edges = "movsx edi, word ptr [eax + upper_plane_edge]" "mov dx, word ptr [eax + upper_clip_edge]" \
    "dec edi" "cmp dx, word ptr [eax + lower_clip_edge]" "jge branch_59a" "mov eax, edx" \
    "jmp branch_5a1" "branch_59a:" "mov ax, word ptr [eax + lower_clip_edge]" "branch_5a1:" \
    "movsx ebp, ax" modify exact [eax edx edi];

extern void select_column_shape(void);
#pragma aux select_column_shape = "cmp edi, eax" "jge ceilscan_empty_column" "cmp edi, ecx" "db 7ch, 18h" /* marker-rel8 +1,+2 */ modify exact [eax ebx ecx edx edi esi];

extern void skip_filled_upper_rows(void);
#pragma aux skip_filled_upper_rows = "db 0ebh, 1fh" /* marker-rel8 0,+1 */ modify exact [];

extern void check_new_lower_rows(void);
#pragma aux check_new_lower_rows = "cmp ecx, ebp" "db 7dh, 2dh" /* marker-rel8 +3 */ modify exact [eax ecx];

extern void repeat_new_lower_rows(void);
#pragma aux repeat_new_lower_rows = "db 0ebh, 0f2h" /* marker-rel8 -1 */ aborts modify exact [];

void ceilscan_scan_column(void);
#pragma aux ceilscan_scan_column aborts;

void ceilscan_scan_column(void)
{
    /* Close completed horizontal spans and record the start columns of newly visible rows. */
    in_ax(from_si() * 2);
    read_column_clip_edges();
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
#pragma aux check_last_column = "cmp esi, dword ptr [esp]" "db 74h, 14h" /* marker-rel8 +2,+3 */ modify exact [eax ebx ecx];

extern void advance_past_empty_column(void);
#pragma aux advance_past_empty_column = "mov ecx, ebx" "inc esi" modify exact [ecx esi];

void ceilscan_empty_column(void);
#pragma aux ceilscan_empty_column aborts;

void ceilscan_empty_column(void)
{
    /* Drain spans at an empty column before advancing. */
    for (;;) {
        in_ax(from_cx() - 1);
        if (from_bx() >= from_ax())
            break;
        in_bx(from_bx() + 1);
        in_ax(from_si() - 1);
        hline(from_ax(), from_bx());
    }
    check_last_column();
    in_bx(upper_plane_edge[from_si() + 1]);
    advance_past_empty_column();
}

extern void continue_ceiling_columns(void);
#pragma aux continue_ceiling_columns = "cmp esi, dword ptr [esp]" "jle ceilscan_scan_column" modify exact [eax esi];

void ceilscan_test_column(void);
#pragma aux ceilscan_test_column aborts;

void ceilscan_test_column(void)
{
    /* Continue while a screen column remains. */
    continue_ceiling_columns();
}

extern void read_last_column(void);
#pragma aux read_last_column = "mov eax, dword ptr [esp]" modify exact [eax];

void ceilscan_finish_spans(void);
#pragma aux ceilscan_finish_spans aborts;

void ceilscan_finish_spans(void)
{
    /* Draw the final open spans at the rightmost column. */
    for (;;) {
        in_ax(from_cx() - 1);
        if (from_bx() >= from_ax())
            ceilscan_run_timer();
        in_bx(from_bx() + 1);
        read_last_column();
        hline(from_ax(), from_bx());
    }
}

void ceilscan_run_timer(void);
#pragma aux ceilscan_run_timer aborts;

void ceilscan_run_timer(void)
{
    /* Service the timer after completing the ceiling. */
    faketimerhandler();
    ceilscan_restore_stack();
}

extern void restore_ceiling_registers(void);
#pragma aux restore_ceiling_registers = "add esp, 0x14" "pop ebp" "pop edi" "pop esi" "pop ecx" "ret" aborts modify exact [eax];

void ceilscan_restore_stack(void);
#pragma aux ceilscan_restore_stack aborts;

void ceilscan_restore_stack(void)
{
    /* Return through the shared saved frame used by ceiling and keepaway. */
    restore_ceiling_registers();
}
