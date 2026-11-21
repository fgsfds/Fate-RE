/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern long qsetmode, stereofps, windowx1, windowx2, windowy1, windowy2;
extern long ylookup[];
extern long clear_stereo_buffer, frameplace, chainplace;
extern unsigned char chainstat, pow2char[];

/* The internal entry points share the original saved registers and stack slots. */
extern void clearview_restore(void);
#pragma aux clearview_restore aborts modify exact [];
extern void clearview_stereo_row(void);
#pragma aux clearview_stereo_row aborts modify exact [];
extern void clearview_check_stereo_row(void);
extern void clearview_check_planar(void);
extern void clearview_linear(void);
extern void clearview_service_timer(void);
#pragma aux clearview_service_timer aborts modify exact [];
extern void faketimerhandler(void);
#pragma aux faketimerhandler modify exact [];

#define ROW_OFFSET_AT_BYTE_OFFSET(index) (*(long *)((char *)ylookup + (index)))

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

/* ECX supplies the row count to the string instructions. */
extern long current_row_width(void);
#pragma aux current_row_width = "" value [ecx] modify exact [ecx];

extern void store_clear_byte(void);
#pragma aux store_clear_byte = "stosb" modify exact [edi];

extern void store_clear_word(void);
#pragma aux store_clear_word = "stosw" modify exact [edi];

extern void store_clear_words(void);
#pragma aux store_clear_words = "db 0f3h" "stosw" modify exact [ecx edi];

extern void store_clear_dwords(void);
#pragma aux store_clear_dwords = "rep stosd" modify exact [ecx edi];

extern void read_clear_pixel(void);
#pragma aux read_clear_pixel = "mov eax, dword ptr [esp]" modify exact [eax];

#define FILL_CLEARVIEW_ROW() do { \
    if ((unsigned long)current_row_width() < 4) { \
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

extern void setup_clearview(void);
#pragma aux setup_clearview = "push ebx" "push ecx" "push edx" "push esi" "push edi" "push ebp" "sub esp, 4" "push eax" \
    "cmp dword ptr [qsetmode], 0xc8" "jne near clearview_restore" modify exact [eax ebx ecx edx esi edi];

extern void read_row_width_and_pixel(void);
#pragma aux read_row_width_and_pixel = "lea ebp, [eax + 1]" "mov eax, dword ptr [esp]" "mov ecx, dword ptr [esp]" modify exact [eax ecx];

extern void save_lo_pixel(void);
#pragma aux save_lo_pixel = "mov dword ptr [esp], ecx" modify exact [];

extern void save_pixel_and_check_stereo(void);
#pragma aux save_pixel_and_check_stereo = "mov dword ptr [esp], esi" "test edi, edi" "je clearview_check_planar" modify exact [eax ebx ecx edx esi edi];

extern void start_stereo_rows(void);
#pragma aux start_stereo_rows = "jmp clearview_check_stereo_row" aborts modify exact [];

void clearview(void);
#pragma aux clearview aborts;

void clearview(void)
{
    /* Prepare the fill pixel and select stereo or ordinary rendering. */
    setup_clearview();
    in_ax(windowx2);
    in_bx(windowx1);
    in_ax(from_ax() - from_bx());
    read_row_width_and_pixel();
    in_ax((unsigned long)from_ax() << 8);
    in_cx((unsigned long)from_cx() + from_ax());
    in_dx(windowy1);
    in_ax(from_cx());
    in_di(stereofps);
    in_ax((unsigned long)from_ax() << 16);
    save_lo_pixel();
    in_si((unsigned long)from_cx() + from_ax());
    in_dx(from_dx() << 2);
    save_pixel_and_check_stereo();
    in_ax(clear_stereo_buffer);
    in_ax(from_ax() + ROW_OFFSET_AT_BYTE_OFFSET(from_dx()));
    in_dx(windowy1);
    in_si(from_bx() + from_ax());
    start_stereo_rows();
}

void clearview_stereo_row(void);
#pragma aux clearview_stereo_row aborts;

void clearview_stereo_row(void)
{
    /* Fill corresponding rows in both stereo buffers. */
    read_clear_pixel();
    in_cx(from_bp());
    in_di(from_si());
    FILL_CLEARVIEW_ROW();
    read_clear_pixel();
    in_di(from_si() + 0x10000);
    in_cx(from_bp());
    FILL_CLEARVIEW_ROW();
    in_bx(ylookup[1]);
    in_dx(from_dx() + 1);
    in_si(from_si() + from_bx());
}

void clearview_check_stereo_row(void);
#pragma aux clearview_check_stereo_row aborts;

void clearview_check_stereo_row(void)
{
    /* Finish the stereo viewport or return to its next scanline. */
    if (from_dx() <= windowy2)
        clearview_stereo_row();
    clearview_service_timer();
}

extern void require_planar_mode(void);
#pragma aux require_planar_mode = "cmp byte ptr [chainstat], 0" "je clearview_linear" modify exact [eax ebx ecx edx edi esi];

extern void select_plane_mask_register(void);
#pragma aux select_plane_mask_register = "mov dword ptr [esp + 4], eax" "mov eax, 2" "mov ecx, ebx" "out dx, al" "test bl, 3" \
    "db 74h, 4ah" /* marker-rel8 +5 */ modify exact [eax ecx edx edi esi];

extern void read_left_plane_mask(void);
#pragma aux read_left_plane_mask = "mov al, byte ptr [eax + pow2char]" "mov edx, 0x10" "and eax, 0xff" modify exact [eax edx];

extern void select_left_planes(void);
#pragma aux select_left_planes = "out dx, al" modify exact [eax edx esi ebx];

extern void load_left_edge_pixel(void);
#pragma aux load_left_edge_pixel = "mov bl, byte ptr [esp]" modify exact [ebx];

extern void start_left_edge_rows(void);
#pragma aux start_left_edge_rows = "db 0ebh, 0bh" /* marker-rel8 +1 */ modify exact [eax edx esi];

extern void check_left_edge_rows(void);
#pragma aux check_left_edge_rows = "cmp edx, dword ptr [windowy2]" "db 7eh, 0edh" /* marker-rel8 -1,0 */ "test byte ptr [esp + 4], 3" "db 74h, 46h" /* marker-rel8 +5 */ modify exact [eax ebx edx esi edi];

extern void load_right_boundary(void);
#pragma aux load_right_boundary = "mov eax, dword ptr [esp + 4]" modify exact [eax];

extern void read_right_plane_mask(void);
#pragma aux read_right_plane_mask = "mov al, byte ptr [eax + pow2char]" "and eax, 0xff" "mov edx, 0x3c5" modify exact [eax edx ebx];

extern void select_right_planes(void);
#pragma aux select_right_planes = "mov bl, byte ptr [esp]" "out dx, al" "mov eax, dword ptr [esp + 4]" modify exact [eax ebx];

extern void start_right_edge_rows(void);
#pragma aux start_right_edge_rows = "db 0ebh, 0bh" /* marker-rel8 +1 */ modify exact [eax edx esi];

extern void check_right_edge_rows(void);
#pragma aux check_right_edge_rows = "cmp edx, dword ptr [windowy2]" "db 7eh, 0edh" /* marker-rel8 -1,0 */ "mov eax, dword ptr [esp + 4]" modify exact [eax ecx edx esi edi];

extern void check_for_planar_interior(void);
#pragma aux check_for_planar_interior = "mov dword ptr [esp + 4], eax" "cmp ecx, eax" "jge clearview_service_timer" modify exact [eax ebx ecx edx esi edi];

extern void select_interior_planes(void);
#pragma aux select_interior_planes = "out dx, al" modify exact [eax ebx edx esi edi];

extern void load_interior_width(void);
#pragma aux load_interior_width = "mov ebp, dword ptr [esp + 4]" modify exact [];

extern void set_interior_width(void);
#pragma aux set_interior_width = "sub ebp, ecx" modify exact [];

extern void start_planar_rows(void);
#pragma aux start_planar_rows = "db 0ebh, 4dh" /* marker-rel8 +8 */ modify exact [eax ecx esi edi];

extern void check_planar_rows(void);
#pragma aux check_planar_rows = "cmp edx, dword ptr [windowy2]" "db 7eh, 0abh" /* marker-rel8 -7 */ "db 0ebh, 72h" /* marker-rel8 +9,+10 widen */ aborts modify exact [];

void clearview_check_planar(void);
#pragma aux clearview_check_planar aborts;

void clearview_check_planar(void)
{
    /* Clip the planar edge masks and fill each interior scanline. */
    require_planar_mode();
    in_ax(windowx2 + 1);
    in_dx(0x3c4);
    select_plane_mask_register();
    in_ax(from_bx() & 3);
    read_left_plane_mask();
    in_dx(from_dx() - from_ax());
    in_ax(from_dx());
    in_dx(0x3c5);
    select_left_planes();
    in_si(chainplace);
    in_ax(from_bx());
    in_dx(windowy1);
    in_ax(from_ax() >> 2);
    load_left_edge_pixel();
    in_ax(from_ax() + from_si());
    start_left_edge_rows();
    in_si(ylookup[from_dx()]);
    in_dx(from_dx() + 1);
    *(unsigned char *)(from_si() + from_ax()) = (unsigned char)from_bx();
    check_left_edge_rows();
    load_right_boundary();
    in_ax(from_ax() & 3);
    read_right_plane_mask();
    in_ax(from_ax() - 1);
    select_right_planes();
    in_di(chainplace);
    in_ax(from_ax() >> 2);
    in_dx(windowy1);
    in_ax(from_ax() + from_di());
    start_right_edge_rows();
    in_si(ylookup[from_dx()]);
    in_dx(from_dx() + 1);
    *(unsigned char *)(from_si() + from_ax()) = (unsigned char)from_bx();
    check_right_edge_rows();
    in_cx(from_cx() + 3);
    in_ax(from_ax() >> 2);
    in_cx(from_cx() >> 2);
    check_for_planar_interior();
    in_ax(0xf);
    in_dx(0x3c5);
    select_interior_planes();
    in_dx(windowy1);
    in_ax(chainplace);
    in_bx(ylookup[from_dx()]);
    load_interior_width();
    in_ax(from_ax() + from_bx());
    set_interior_width();
    in_si(from_ax() + from_cx());
    start_planar_rows();
    read_clear_pixel();
    in_cx(from_bp());
    in_di(from_si());
    FILL_CLEARVIEW_ROW();
    in_di(ylookup[1]);
    in_dx(from_dx() + 1);
    in_si(from_si() + from_di());
    check_planar_rows();
}

extern void start_linear_rows(void);
#pragma aux start_linear_rows = "db 0ebh, 4dh" /* marker-rel8 +8 */ modify exact [eax edx esi ebx ecx edi];

extern void check_linear_rows(void);
#pragma aux check_linear_rows = "cmp edx, dword ptr [windowy2]" "db 7eh, 0abh" /* marker-rel8 -7 */ modify exact [];

void clearview_linear(void);
#pragma aux clearview_linear aborts;

void clearview_linear(void)
{
    /* Fill each linear frame scanline in the viewport. */
    in_ax(frameplace);
    in_bx(ROW_OFFSET_AT_BYTE_OFFSET(from_dx()));
    in_si(windowx1);
    in_ax(from_ax() + from_bx());
    in_dx(windowy1);
    in_si(from_si() + from_ax());
    start_linear_rows();
    read_clear_pixel();
    in_cx(from_bp());
    in_di(from_si());
    FILL_CLEARVIEW_ROW();
    in_bx(ylookup[1]);
    in_dx(from_dx() + 1);
    in_si(from_si() + from_bx());
    check_linear_rows();
}


void clearview_service_timer(void);
#pragma aux clearview_service_timer aborts;

void clearview_service_timer(void)
{
    /* Service the timer before restoring the shared frame. */
    faketimerhandler();
    clearview_restore();
}
