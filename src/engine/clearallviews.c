/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern long qsetmode, stereofps, brightness_video_mode;
extern unsigned long *clear_stereo_buffer, *frameplace;
extern unsigned char video_backend;
extern unsigned long clearallviews_dispatch_table[];
extern long display_page_count, presentation_width, presentation_height;
extern unsigned long display_page_bytes;

extern void shared_graphics_epilogue(void);
#pragma aux shared_graphics_epilogue aborts modify exact [];
/* Each entry shares the caller's register save and the timer epilogue. */
extern void clearallviews_fill_dwords(void);
extern void clearallviews_service_timer(void);
#pragma aux clearallviews_service_timer aborts modify exact [];
extern void faketimerhandler(void);
#pragma aux faketimerhandler modify exact [];
extern void select_display_page(long page);
#pragma aux select_display_page parm [eax] modify exact [eax edx];

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

extern void in_dx(long value);
#pragma aux in_dx = "" parm [edx] modify exact [];

extern void in_di(long value);
#pragma aux in_di = "" parm [edi] modify exact [];

extern long from_si(void);
#pragma aux from_si = value [esi] modify exact [];

extern void in_si(long value);
#pragma aux in_si = "" parm [esi] modify exact [];

extern void setup_clear_registers(void);
#pragma aux setup_clear_registers = "push ebx" "push ecx" "push edx" "push esi" "push edi" "mov ebx, eax" \
    modify exact [eax ebx ecx edx esi edi];

extern void choose_stereo_clear(void);
#pragma aux choose_stereo_clear = "test ecx, ecx" "db 74h, 44h" /* marker-rel8 +3,+4 */ "cmp dword ptr [brightness_video_mode], 6" "db 75h, 27h" /* marker-rel8 +2,+3 */ \
    "mov edx, 0x3d4" "xor esi, esi" "db 0ebh, 19h" /* marker-rel8 +2 */ modify exact [eax ebx ecx edx esi edi];

extern void select_stereo_crtc_bank(void);
#pragma aux select_stereo_crtc_bank = "mov edi, 0xa0000" "out dx, ax" "xor eax, eax" modify exact [eax ecx edx esi edi];

extern void clear_stereo_bank(void);
#pragma aux clear_stereo_bank = "rep stosd" "cmp esi, 4" "db 7ch, 0e2h" /* marker-rel8 -2,-1 */ modify exact [eax ecx edi];

void clearallviews(void);
#pragma aux clearallviews aborts;

void clearallviews(void)
{
    /* Prepare the repeated pixel value and clear the stereo banks if enabled. */
    setup_clear_registers();
    if (qsetmode != 0xc8)
        shared_graphics_epilogue();
    in_ax((unsigned long)from_ax() << 8);
    in_bx((unsigned long)from_bx() + from_ax());
    in_ax((unsigned long)from_bx() << 16);
    in_cx(stereofps);
    in_bx((unsigned long)from_bx() + from_ax());
    choose_stereo_clear();
    in_ax(from_si() << 8);
    in_cx(0x4000);
    in_ax(from_ax() + 0x35);
    select_stereo_crtc_bank();
    in_si(from_si() + 1);
    clear_stereo_bank();
    in_cx(0x7d00);
    in_di((long)clear_stereo_buffer);
    in_ax(from_bx());
}

extern void fill_clear_dwords(void);
#pragma aux fill_clear_dwords = "rep stosd" modify exact [ecx edi];

void clearallviews_fill_dwords(void);
#pragma aux clearallviews_fill_dwords aborts;

void clearallviews_fill_dwords(void)
{
    /* Fill the selected framebuffer before servicing the timer. */
    fill_clear_dwords();
    clearallviews_service_timer();
}

extern void dispatch_clear_backend(unsigned long backend);
#pragma aux dispatch_clear_backend = "jmp dword cs:[eax*4 + clearallviews_dispatch_table]" parm [eax] aborts modify exact [];

void clearallviews_dispatch_backend(void);
#pragma aux clearallviews_dispatch_backend aborts;

void clearallviews_dispatch_backend(void)
{
    unsigned char backend;

    /* Use the original code-segment dispatch table. */
    backend = video_backend;
    if (backend > 7)
        clearallviews_service_timer();
    dispatch_clear_backend((unsigned long)backend);
}

extern void select_all_vga_planes(void);
#pragma aux select_all_vga_planes = "out dx, ax" modify exact [eax ecx edx edi];

extern void fill_vga_framebuffer(void);
#pragma aux fill_vga_framebuffer = "db 0ebh, 0c5h" /* marker-rel8 -5,-4 */ aborts modify exact [];

void clearallviews_vga_planes(void);
#pragma aux clearallviews_vga_planes aborts;

void clearallviews_vga_planes(void)
{
    /* Clear all VGA planes together. */
    in_ax(0xf02);
    in_dx(0x3c4);
    in_cx(0x4000);
    in_di(0xa0000);
    select_all_vga_planes();
    in_ax(0);
    fill_vga_framebuffer();
}

/* The byte and word stores align EDI before the doubleword fill. */
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

void clearallviews_paged_display(void);
#pragma aux clearallviews_paged_display aborts;

void clearallviews_paged_display(void)
{
    long page;

    /* Visit each display page and clear its visible storage. */
    for (page = 0; page < display_page_count; ++page) {
        select_display_page(page);
        in_cx(display_page_bytes);
        in_di((long)frameplace);
        in_ax(0);
        if ((unsigned long)from_cx() < 4) {
            if (from_cx() & 1)
                store_clear_byte();
            in_cx((unsigned long)from_cx() >> 1);
            store_clear_words();
        } else {
            align_clear_dwords();
            in_bx(from_cx());
            in_cx((unsigned long)from_cx() >> 2);
            store_clear_dwords();
            if (from_bx() & 2)
                store_clear_word();
            if (from_bx() & 1)
                store_clear_byte();
        }
    }
}

void clearallviews_linear_frame(void);
#pragma aux clearallviews_linear_frame aborts;

void clearallviews_linear_frame(void)
{
    /* Clear the current linear framebuffer. */
    in_cx(presentation_width * presentation_height);
    in_di((long)frameplace);
    in_ax(0);
    in_cx(from_cx() >> 2);
    clearallviews_fill_dwords();
}

extern void select_port_3cd_bank(void);
#pragma aux select_port_3cd_bank = "mov edi, 0xa0000" "out dx, al" "xor eax, esi" "rep stosd" modify exact [eax ecx edx edi];

void clearallviews_port_3cd_banks(void);
#pragma aux clearallviews_port_3cd_banks aborts;

void clearallviews_port_3cd_banks(void)
{
    /* Keep the original initial jump to a bottom test. All three bank loops
       visit ESI 0..3, so their signed shifts and increments are defined. */
    in_dx(0x3cd);
    in_si(0);
    goto check_bank;
    do {
        in_cx(0x3e80);
        in_ax(from_si());
        select_port_3cd_bank();
        in_si(from_si() + 1);
    check_bank:
        ;
    } while (from_si() < 4);
    clearallviews_service_timer();
}

extern void select_graphics_controller_bank(void);
#pragma aux select_graphics_controller_bank = "mov edi, 0xa0000" "out dx, ax" "xor eax, eax" modify exact [eax ecx edx esi edi];

extern void clear_graphics_controller_bank(void);
#pragma aux clear_graphics_controller_bank = "rep stosd" modify exact [ecx edi];

void clearallviews_graphics_controller_banks(void);
#pragma aux clearallviews_graphics_controller_banks aborts;

void clearallviews_graphics_controller_banks(void)
{
    /* Clear four banks selected with the graphics controller. */
    in_dx(0x3ce);
    in_si(0);
    goto check_bank;
    do {
        in_ax(from_si() << 12);
        in_cx(0x3e80);
        in_ax(from_ax() + 9);
        select_graphics_controller_bank();
        in_si(from_si() + 1);
        clear_graphics_controller_bank();
    check_bank:
        ;
    } while (from_si() < 4);
    clearallviews_service_timer();
}

extern void select_crtc_bank(void);
#pragma aux select_crtc_bank = "mov edi, 0xa0000" "out dx, ax" "xor eax, eax" modify exact [eax ecx edx esi edi];

extern void clear_crtc_bank(void);
#pragma aux clear_crtc_bank = "rep stosd" modify exact [ecx edi];

void clearallviews_crtc_banks(void);
#pragma aux clearallviews_crtc_banks aborts;

void clearallviews_crtc_banks(void)
{
    /* Clear four banks selected with the CRTC, then share the timer frame. */
    in_dx(0x3d4);
    in_si(0);
    goto check_bank;
    do {
        in_ax(from_si() << 8);
        in_cx(0x3e80);
        in_ax(from_ax() + 0x35);
        select_crtc_bank();
        in_si(from_si() + 1);
        clear_crtc_bank();
    check_bank:
        ;
    } while (from_si() < 4);
}

void clearallviews_service_timer(void)
{
    /* Service the timer and restore the graphics registers. */
    faketimerhandler();
    shared_graphics_epilogue();
}
