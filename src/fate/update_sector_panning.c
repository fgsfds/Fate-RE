/* Update the sector pan bytes using the historical, one-based list.
 * The frame and the 12 original jump-table targets share live registers.
 */
extern short pan_sector_count, pan_sectors[], pan_sector_tag[];
extern long pan_clock;
extern unsigned char pan_clock_byte;
extern unsigned char pan_ceiling_x[], pan_ceiling_y[], pan_floor_x[], pan_floor_y[];
extern unsigned long pan_dispatch[];
extern void pan_check_count(void);
extern void pan_advance(void);
extern void pan_prepare_sector(long);
#define FRAME(type, offset) (*(volatile type *)((char *)&frame_slot + (offset)))
#define TAG_AT(offset) (*(short *)((char *)pan_sector_tag + (offset)))

extern long put_eax(long);
#pragma aux put_eax = "" parm [eax] value [eax] modify exact [];
extern long get_eax(void);
#pragma aux get_eax = "" value [eax] modify exact [];
extern long put_edx(long);
#pragma aux put_edx = "" parm [edx] value [edx] modify exact [];
extern long get_edx(void);
#pragma aux get_edx = "" value [edx] modify exact [];
extern long put_ebx(long);
#pragma aux put_ebx = "" parm [ebx] value [ebx] modify exact [];
extern long get_ebx(void);
#pragma aux get_ebx = "" value [ebx] modify exact [];
extern long put_esi(long);
#pragma aux put_esi = "" parm [esi] value [esi] modify exact [];
extern long put_edi(long);
#pragma aux put_edi = "" parm [edi] value [edi] modify exact [];
extern long get_edi(void);
#pragma aux get_edi = "" value [edi] modify exact [];
extern short put_cx(short);
#pragma aux put_cx = "" parm [cx] value [cx] modify exact [];
extern short get_cx(void);
#pragma aux get_cx = "" value [cx] modify exact [];
extern short put_dx(short);
#pragma aux put_dx = "" parm [dx] value [dx] modify exact [];
extern short get_bx(void);
#pragma aux get_bx = "" value [bx] modify exact [];
extern unsigned char put_dh(unsigned char);
#pragma aux put_dh = "" parm [dh] value [dh] modify exact [];
extern unsigned char get_dh(void);
#pragma aux get_dh = "" value [dh] modify exact [];
extern unsigned char put_dl(unsigned char);
#pragma aux put_dl = "" parm [dl] value [dl] modify exact [];
extern unsigned char get_dl(void);
#pragma aux get_dl = "" value [dl] modify exact [];
extern unsigned char get_al(void);
#pragma aux get_al = "" value [al] modify exact [];

extern void save_panning_frame(void);
#pragma aux save_panning_frame = "push ebx" "push ecx" "push edx" "push esi" "push edi" "sub esp,8" modify exact [ebx ecx edx esi edi];
extern void enter_panning_count(void);
#pragma aux enter_panning_count = "jmp near pan_check_count" aborts modify exact [];
extern void skip_invalid_tag(void);
#pragma aux skip_invalid_tag = "cmp dx,11" "ja near pan_advance" modify exact [edi esi];
extern void set_panning_mode_index(void);
#pragma aux set_panning_mode_index = "mov si,dx" modify exact [esi];
extern void dispatch_panning_mode(void);
#pragma aux dispatch_panning_mode = "jmp dword cs:[esi*4+pan_dispatch]" aborts modify exact [];
extern void advance_panning_near(void);
#pragma aux advance_panning_near = "jmp near pan_advance" modify exact [eax edx esi edi];
extern void finish_panning_span(void);
#pragma aux finish_panning_span = "" aborts modify exact [];

extern void skip_floor_slow(void);
#pragma aux skip_floor_slow = "db 0ebh, 5bh" modify exact [eax edx esi edi];
extern void skip_floor_normal(void);
#pragma aux skip_floor_normal = "db 0ebh, 53h" modify exact [eax edx esi edi];
extern void skip_ceil_slow(void);
#pragma aux skip_ceil_slow = "db 0ebh, 25h" modify exact [eax edx esi edi];
extern void skip_ceil_normal(void);
#pragma aux skip_ceil_normal = "db 0ebh, 1dh" modify exact [eax edx esi edi];
extern void skip_ceil_fast(void);
#pragma aux skip_ceil_fast = "db 0ebh, 15h" modify exact [eax edx esi edi];
extern void skip_ceil_y(void);
#pragma aux skip_ceil_y = "db 0ebh, 0e1h" modify exact [eax edx esi edi];

extern void check_next_panning(void);
#pragma aux check_next_panning = "cmp bx,[pan_sector_count]" "jle near pan_prepare_sector" modify exact [];
extern void restore_panning_frame(void);
#pragma aux restore_panning_frame = "add esp,8" "pop edi" "pop esi" "pop edx" "pop ecx" "pop ebx" "ret" aborts modify exact [];
void update_sector_panning(void);
#pragma aux update_sector_panning aborts modify exact [eax ebx ecx edx esi edi];
void update_sector_panning(void)
{
    save_panning_frame();
    put_ebx(1);
    enter_panning_count();
}

void pan_prepare_sector(long frame_slot);
#pragma aux pan_prepare_sector parm routine [] aborts modify exact [eax ecx edx esi edi];
void pan_prepare_sector(long frame_slot)
{
    put_eax(get_bx());
    put_cx(pan_sectors[get_eax()]);
    put_edx(get_cx());
    put_eax(get_edx());
    put_eax(get_eax() << 2);
    put_eax(get_eax() + get_edx());
    put_eax(get_eax() << 3);
    put_dx(TAG_AT(get_eax()));
    put_edx(get_edx() - 18);
    skip_invalid_tag();

    put_esi(0);
    put_edi(*(volatile long *)&pan_clock);
    set_panning_mode_index();
    put_dh(pan_clock_byte);
    put_edi(get_edi() >> 2);
    put_dl(get_dh());
    put_edi(get_edi() & 255);
    put_dl(get_dl() << 2);
    FRAME(long, 0) = get_edi();
    dispatch_panning_mode();
}

void pan_floor_cases(long frame_slot);
#pragma aux pan_floor_cases parm routine [] aborts modify exact [eax edx esi edi];
void pan_floor_cases(long frame_slot)
{
    put_dl(FRAME(unsigned char, 0));
    pan_floor_x[get_eax()] = get_dl();
    advance_panning_near();
    pan_floor_x[get_eax()] = get_dh();
    advance_panning_near();
    put_dl(FRAME(unsigned char, 0));
    pan_floor_y[get_eax()] = get_dl();
    skip_floor_slow();
    pan_floor_y[get_eax()] = get_dh();
    skip_floor_normal();
    /* The fast floor-Y case also falls through to the slow ceiling-X update. */
    pan_floor_y[get_eax()] = get_dl();
    finish_panning_span();
}

extern void finish_slow_clock(long);
#pragma aux finish_slow_clock = "" parm [eax] modify exact [edx];
void pan_ceiling_cases(long frame_slot);
#pragma aux pan_ceiling_cases parm routine [] aborts modify exact [eax edx esi edi];
void pan_ceiling_cases(long frame_slot)
{
    put_eax(pan_clock);
    put_eax(get_eax() >> 4);
    finish_slow_clock(put_eax(get_eax() & 255));
    put_edx(get_cx());
    FRAME(unsigned char, 4) = get_al();
    put_eax(get_edx());
    put_eax(get_eax() << 2);
    put_eax(get_eax() + get_edx());
    put_dl(FRAME(unsigned char, 4));
    pan_ceiling_x[get_eax()*8] = get_dl();
    skip_ceil_slow();
    pan_ceiling_x[get_eax()] = get_dh();
    skip_ceil_normal();
    pan_ceiling_x[get_eax()] = get_dl();
    skip_ceil_fast();
    put_edx(pan_clock);
    put_edx(get_edx() >> 4);
    put_edx(get_edx() & 255);
    pan_ceiling_y[get_eax()] = get_dl();
    finish_panning_span();
}

void pan_advance(void);
#pragma aux pan_advance aborts modify exact [eax ebx ecx edx esi edi];
void pan_advance(void)
{
    put_ebx(get_ebx() + 1);
    check_next_panning();
    restore_panning_frame();
}

void pan_ceiling_y_normal(void);
#pragma aux pan_ceiling_y_normal aborts modify exact [];
void pan_ceiling_y_normal(void)
{
    pan_ceiling_y[get_eax()] = get_dh();
    skip_ceil_y();
    finish_panning_span();
}
