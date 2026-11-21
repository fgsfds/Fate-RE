/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern long chainplace, frameplace, ylookup[], lastx[], viewoffset;
extern long globalhoriz, horizycent, *horizon_aspect;
extern long globalzd, globalx1, globalx2, globaly1, globaly2;
extern long globalxpanning, globalypanning, globalshade, globvis;
extern long asm1, asm2;
extern unsigned char chainstat, pow2char[];

/* All span paths use the same saved registers and scratch slots. */
extern void hline_planar(void);
extern void hline_next_plane(void);
extern void wallfront_return(void);
#pragma aux wallfront_return aborts modify exact [];
extern void hlineasm4(void);
extern void setuphlineasm4(void);
extern void getpalookup(void);

#define ROW_OFFSET_AT_BYTE_OFFSET(offset) (*(long *)((char *)ylookup + (offset)))

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

extern long mulscale8(long first, long second);
#pragma aux mulscale8 = "imul ebx" "shrd eax, edx, 8" \
    parm nomemory [eax] [ebx] value [eax] modify exact [eax edx];

extern long mulscale10(long first, long second);
#pragma aux mulscale10 = "imul ebx" "shrd eax, edx, 10" \
    parm nomemory [eax] [ebx] value [eax] modify exact [eax edx];

extern long distance_magnitude(long distance);
#pragma aux distance_magnitude = "test eax, eax" "jns distance_nonnegative" "neg eax" \
    "distance_nonnegative:" parm nomemory [eax] value [eax] modify exact [eax];

extern long mulscale18(long first, long second);
#pragma aux mulscale18 = "imul ebx" "shrd eax, edx, 18" \
    parm nomemory [eax] [ebx] value [eax] modify exact [eax edx];

extern void save_span_frame(void);
#pragma aux save_span_frame = "push ebx" "push ecx" "push esi" "push edi" "push ebp" "sub esp, 0x24" "push eax" modify exact [eax ebx ecx edx esi edi];

extern void check_span_bounds(void);
#pragma aux check_span_bounds = "mov ebp, dword ptr [ecx + lastx]" "cmp ebp, eax" "jg near wallfront_return" modify exact [eax ebx ecx edx esi edi];

extern void check_planar_span(void);
#pragma aux check_planar_span = "cmp byte ptr [chainstat], 0" "jne hline_planar" modify exact [eax ebx ecx edx esi edi];

extern void save_linear_destination(void);
#pragma aux save_linear_destination = "mov dword ptr [esp + 4], ecx" modify exact [ebx];

extern void save_linear_texture_y(void);
#pragma aux save_linear_texture_y = "mov dword ptr [esp + 8], ebx" modify exact [eax ecx ebx edi];

extern void lookup_linear_shade(void);
#pragma aux lookup_linear_shade = "mov edx, ecx" "mov edi, dword ptr [esp + 4]" "call getpalookup" modify exact [eax ebx ecx edx esi edi];

extern void read_linear_span_parameters(void);
#pragma aux read_linear_span_parameters = "mov edx, dword ptr [esp + 8]" "mov ecx, eax" "mov eax, dword ptr [esp]" modify exact [eax ecx edx ebx];

extern void draw_linear_span(void);
#pragma aux draw_linear_span = "call hlineasm4" "jmp near wallfront_return" aborts modify exact [eax ebx ecx edx esi edi];

void hline(void);
#pragma aux hline aborts;

void hline(void)
{
    /* Project texture coordinates and draw a linear span or dispatch to the planes. */
    save_span_frame();
    in_si(from_dx());
    in_cx((unsigned long)from_dx() << 2);
    check_span_bounds();
    in_bx(globalhoriz);
    in_ax(from_dx());
    in_di(horizycent);
    in_ax(from_ax() - from_bx());
    in_bx(from_ax() + from_di());
    in_ax((long)horizon_aspect);
    in_bx((unsigned long)from_bx() << 2);
    in_bx(*(long *)(from_bx() + from_ax()));
    in_ax(globalzd);
    in_ax(mulscale10(from_ax(), from_bx()));
    in_di(from_ax());
    in_ax(globalx1);
    in_bx(from_di());
    in_ax(mulscale8(from_ax(), from_bx()));
    asm1 = from_ax();
    in_ax(globaly2);
    in_ax(mulscale8(from_ax(), from_bx()));
    asm2 = from_ax();
    in_ax(globalx1);
    in_ax((unsigned long)from_bp() * from_ax() + globaly1);
    check_planar_span();
    in_bx(ROW_OFFSET_AT_BYTE_OFFSET(from_cx()));
    in_si(frameplace);
    in_bx(from_bx() + from_bp());
    in_cx(viewoffset);
    in_bx(from_bx() + from_si());
    in_cx(from_cx() + from_bx());
    in_bx(from_di());
    in_ax(mulscale8(from_ax(), from_bx()));
    in_si(globalxpanning);
    in_si((unsigned long)from_si() + from_ax());
    in_ax(globaly2);
    in_ax((unsigned long)from_ax() * from_bp() + globalx2);
    in_ax(mulscale8(from_ax(), from_bx()));
    in_bx(globalypanning);
    save_linear_destination();
    in_bx((unsigned long)from_bx() + from_ax());
    in_cx(globalshade);
    save_linear_texture_y();
    in_ax(from_di());
    in_bx(globvis);
    in_ax(distance_magnitude(from_ax()));
    in_ax(mulscale18(from_ax(), from_bx()));
    lookup_linear_shade();
    in_bx(0);
    read_linear_span_parameters();
    in_cx((unsigned long)from_cx() << 8);
    in_ax(from_ax() - from_bp());
    draw_linear_span();
}

extern void save_planar_texture_x(void);
#pragma aux save_planar_texture_x = "mov dword ptr [esp + 0x24], ebx" modify exact [eax];

extern void save_planar_texture_y(void);
#pragma aux save_planar_texture_y = "mov dword ptr [esp + 0x20], ebx" modify exact [eax ecx ebx edi];

extern void lookup_planar_shade(void);
#pragma aux lookup_planar_shade = "mov edx, ecx" "call getpalookup" modify exact [eax ebx ecx edx edi];

extern void save_planar_shade(void);
#pragma aux save_planar_shade = "mov dword ptr [esp + 0xc], eax" modify exact [eax];

extern void save_texture_step_x(void);
#pragma aux save_texture_step_x = "mov dword ptr [esp + 0x1c], eax" modify exact [eax];

extern void save_texture_step_y_and_right_edge(void);
#pragma aux save_texture_step_y_and_right_edge = "mov ebx, dword ptr [esp]" "mov dword ptr [esp + 0x18], eax" modify exact [eax ebx];

extern void save_planar_right_edge(void);
#pragma aux save_planar_right_edge = "mov dword ptr [esp + 0x14], eax" modify exact [eax];

extern void save_planar_destination(void);
#pragma aux save_planar_destination = "mov dword ptr [esp + 0x10], eax" modify exact [eax ebx];

extern void setup_planar_renderer(void);
#pragma aux setup_planar_renderer = "call setuphlineasm4" modify exact [eax ebx ecx edx esi edi];

void hline_planar(void);
#pragma aux hline_planar aborts;

void hline_planar(void)
{
    /* Prepare per-plane coordinates, shade and raster steps. */
    in_ax(mulscale8(from_ax(), from_bx()));
    in_bx(globalxpanning);
    in_bx((unsigned long)from_bx() + from_ax());
    in_ax(globaly2);
    in_ax((unsigned long)from_ax() * from_bp());
    save_planar_texture_x();
    in_ax((unsigned long)from_ax() + globalx2);
    in_bx(from_di());
    in_ax(mulscale8(from_ax(), from_bx()));
    in_bx(globalypanning);
    in_bx((unsigned long)from_bx() + from_ax());
    in_cx(globalshade);
    save_planar_texture_y();
    in_ax(from_di());
    in_bx(globvis);
    in_ax(distance_magnitude(from_ax()));
    in_ax(mulscale18(from_ax(), from_bx()));
    lookup_planar_shade();
    in_ax((unsigned long)from_ax() << 8);
    save_planar_shade();
    in_ax(asm1);
    save_texture_step_x();
    in_ax((unsigned long)from_ax() << 2);
    asm1 = from_ax();
    in_ax(asm2);
    save_texture_step_y_and_right_edge();
    in_ax((unsigned long)from_ax() << 2);
    in_bx(from_bx() + 1);
    asm2 = from_ax();
    in_ax(from_bp() + 4);
    if (from_bx() < from_ax())
        in_ax(from_bx());
    in_cx(chainplace);
    save_planar_right_edge();
    in_ax(ylookup[from_si()]);
    in_ax(from_ax() + from_cx());
    in_bx(asm2);
    save_planar_destination();
    in_ax(asm1);
    setup_planar_renderer();
}

extern void check_for_renderer_plane(void);
#pragma aux check_for_renderer_plane = "cmp ebp, dword ptr [esp + 0x14]" "jge near wallfront_return" modify exact [eax ebx ecx edx esi edi];

extern void set_renderer_plane(void);
#pragma aux set_renderer_plane = "mov al, byte ptr [eax + pow2char]" "mov edx, 0x3c5" "and eax, 0xff" "out dx, al" modify exact [eax ebx ecx edx esi edi];

extern void read_planar_destination(void);
#pragma aux read_planar_destination = "mov edi, dword ptr [esp + 0x10]" modify exact [edi];

extern void read_planar_texture_x(void);
#pragma aux read_planar_texture_x = "mov esi, dword ptr [esp + 0x24]" modify exact [esi];

extern void read_planar_shade(void);
#pragma aux read_planar_shade = "mov ecx, dword ptr [esp + 0xc]" modify exact [ecx];

extern void read_planar_span_right_edge(void);
#pragma aux read_planar_span_right_edge = "mov eax, dword ptr [esp]" "mov ebx, 0xffffffff" modify exact [eax ebx];

extern void read_planar_texture_y(void);
#pragma aux read_planar_texture_y = "mov edx, dword ptr [esp + 0x20]" modify exact [edx];

extern void draw_planar_span(void);
#pragma aux draw_planar_span = "call hlineasm4" "mov eax, dword ptr [esp + 0x1c]" "mov ecx, dword ptr [esp + 0x24]" \
    "mov esi, dword ptr [esp + 0x20]" modify exact [eax ebx ecx edx esi edi];

extern void read_original_texture_step_y(void);
#pragma aux read_original_texture_step_y = "mov eax, dword ptr [esp + 0x18]" "inc ebp" modify exact [eax];

extern void advance_planar_renderer(void);
#pragma aux advance_planar_renderer = "mov dword ptr [esp + 0x24], ecx" "mov dword ptr [esp + 0x20], esi" "db 0ebh, 8eh" /* marker-rel8 -10,-9 widen */ aborts modify exact [eax ebx ecx edx esi edi];

void hline_next_plane(void);
#pragma aux hline_next_plane aborts;

void hline_next_plane(void)
{
    /* Draw the next VGA plane and advance the coordinates. */
    check_for_renderer_plane();
    in_ax(viewoffset);
    in_ax(from_ax() + from_bp());
    in_ax(from_ax() & 3);
    set_renderer_plane();
    in_ax(viewoffset);
    read_planar_destination();
    in_ax(from_ax() + from_bp());
    read_planar_texture_x();
    in_ax(from_ax() >> 2);
    read_planar_shade();
    in_di(from_di() + from_ax());
    read_planar_span_right_edge();
    in_ax(from_ax() - from_bp());
    read_planar_texture_y();
    in_ax(from_ax() >> 2);
    draw_planar_span();
    in_cx((unsigned long)from_cx() + from_ax());
    read_original_texture_step_y();
    in_si((unsigned long)from_si() + from_ax());
    advance_planar_renderer();
}
