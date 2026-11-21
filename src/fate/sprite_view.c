/* Prepare directional frames, interpolated positions, and sector shade before rendering. */
typedef struct {
    long x, y, z;
    short cstat, tile;
    signed char shade;
    unsigned char palette, clip_distance, unused, xrepeat, yrepeat, xoffset, yoffset;
    short sector, status, angle, owner, xvel, yvel, zvel, lotag, hitag, extra;
} ViewSprite;
extern ViewSprite temporary_view_sprites[];
extern unsigned long view_tile_animation_flags[];
extern signed char view_interpolation_modes[];
extern long view_previous_positions[], view_interpolation_fraction, view_interpolation_clock, view_sprite_count;
extern short view_sector_ceiling_flags[];
extern signed char view_sector_ceiling_shade[], view_sector_floor_shade[];
extern char directional_sprite_tiles[], sprite_view_dispatch[];

extern int getangle(long, long);
#pragma aux getangle parm [eax] [edx] modify exact [eax edx];

/* Keep the original camera coordinates, loop index, and saved registers. */
extern void begin_sprite_view(long, long);
#pragma aux begin_sprite_view = \
    "push ebx" "push ecx" "push esi" "push edi" "push ebp" "sub esp,4" \
    "push eax" "push edx" "xor edx,edx" "mov esi,offset temporary_view_sprites" \
    "mov [esp+8],edx" parm [eax] [edx] modify exact [edx esi];
extern void finish_sprite_view(void);
#pragma aux finish_sprite_view = "add esp,0ch" "pop ebp" "pop edi" "pop esi" "pop ecx" "pop ebx" modify exact [];
/* The original directional tile scan selects one of two code entry points. */
extern void classify_sprite_tile(void);
#pragma aux classify_sprite_tile = \
    "mov ecx,35h" "mov edi,offset directional_sprite_tiles" "mov ax,[esi+0eh]" \
    "db 0f2h,66h,0afh" "jmp dword ptr cs:[ecx*4+sprite_view_dispatch]" modify exact [eax ecx edi];
extern void load_view_y_in_edi(void);
#pragma aux load_view_y_in_edi = "mov edi,[esp]" modify exact [edi];
extern void load_view_x_in_ebx(void);
#pragma aux load_view_x_in_ebx = "mov ebx,[esp+4]" modify exact [ebx];
extern long view_x_in_eax(void);
#pragma aux view_x_in_eax = "mov eax,[esp+4]" value [eax] modify exact [eax];
extern long view_y_in_eax(void);
#pragma aux view_y_in_eax = "mov eax,[esp]" value [eax] modify exact [eax];
extern long absolute_view_dist(long);
#pragma aux absolute_view_dist = "test eax,eax" "jns positive" "neg eax" "positive:" parm [eax] value [eax] modify exact [eax];
extern void get_view_interpolation_fraction(void);
#pragma aux get_view_interpolation_fraction = "mov ebp,[view_interpolation_fraction]" modify exact [];
extern void interpolate_view_ticks_1(void);
#pragma aux interpolate_view_ticks_1 = "shl edx,15" "sar ebp,1" modify exact [edx];
extern void interpolate_view_ticks_3(void);
#pragma aux interpolate_view_ticks_3 = "shl edx,14" "sar ebp,2" modify exact [edx];
extern void interpolate_view_ticks_7(void);
#pragma aux interpolate_view_ticks_7 = "shl edx,13" "sar ebp,3" modify exact [edx];
extern void interpolate_view_ticks_15(void);
#pragma aux interpolate_view_ticks_15 = "shl edx,12" "sar ebp,4" modify exact [edx];
extern void apply_view_interpolation_term(void);
#pragma aux apply_view_interpolation_term = "add ebp,edx" modify exact [];
extern long multiply_view_fraction(long);
#pragma aux multiply_view_fraction = \
    "mov ebx,ebp" "imul ebx" "shrd eax,edx,16" parm [eax] value [eax] modify exact [eax ebx edx];
extern int check_view_floor_shade(void);
#pragma aux check_view_floor_shade = "xor dh,dh" "and dl,1" "movsx edx,dx" value [edx] modify exact [edx];
extern void load_view_sprite_index(void);
#pragma aux load_view_sprite_index = "mov eax,[esp+8]" modify exact [eax];
extern void save_view_sprite_index(long);
#pragma aux save_view_sprite_index = "mov [esp+8],eax" parm [eax] modify exact [];

/* Zero-byte bindings preserve the original Watcom register assignments. */
extern long in_eax(long);
#pragma aux in_eax = parm [eax] value [eax] modify exact [];
extern long in_ebx(long);
#pragma aux in_ebx = parm [ebx] value [ebx] modify exact [];
extern long in_ecx(long);
#pragma aux in_ecx = parm [ecx] value [ecx] modify exact [];
extern long in_edx(long);
#pragma aux in_edx = parm [edx] value [edx] modify exact [];
extern long in_edi(long);
#pragma aux in_edi = parm [edi] value [edi] modify exact [];
extern ViewSprite *in_esi(ViewSprite *);
#pragma aux in_esi = parm [esi] value [esi] modify exact [];
extern short in_bx(short);
#pragma aux in_bx = parm [bx] value [bx] modify exact [];
extern short in_dx(short);
#pragma aux in_dx = parm [dx] value [dx] modify exact [];
extern unsigned char in_al(unsigned char);
#pragma aux in_al = parm [al] value [al] modify exact [];
extern unsigned char in_ah(unsigned char);
#pragma aux in_ah = parm [ah] value [ah] modify exact [];
extern unsigned char in_bl(unsigned char);
#pragma aux in_bl = parm [bl] value [bl] modify exact [];
extern unsigned char in_bh(unsigned char);
#pragma aux in_bh = parm [bh] value [bh] modify exact [];
extern unsigned char in_cl(unsigned char);
#pragma aux in_cl = parm [cl] value [cl] modify exact [];
extern unsigned char in_dl(unsigned char);
#pragma aux in_dl = parm [dl] value [dl] modify exact [];
extern long eax_value(void);
#pragma aux eax_value = value [eax] modify exact [];
extern long ebx_value(void);
#pragma aux ebx_value = value [ebx] modify exact [];
extern long ecx_value(void);
#pragma aux ecx_value = value [ecx] modify exact [];
extern long edx_value(void);
#pragma aux edx_value = value [edx] modify exact [];
extern long edi_value(void);
#pragma aux edi_value = value [edi] modify exact [];
extern ViewSprite *active_sprite(void);
#pragma aux active_sprite = value [esi] modify exact [];
extern short bx_value(void);
#pragma aux bx_value = value [bx] modify exact [];
extern short dx_value(void);
#pragma aux dx_value = value [dx] modify exact [];
extern unsigned char al_value(void);
#pragma aux al_value = value [al] modify exact [];
extern unsigned char bl_value(void);
#pragma aux bl_value = value [bl] modify exact [];
extern unsigned char cl_value(void);
#pragma aux cl_value = value [cl] modify exact [];
extern unsigned char dl_value(void);
#pragma aux dl_value = value [dl] modify exact [];

extern long multiply_mirrored_frame(long, long);
#pragma aux multiply_mirrored_frame = "imul eax,edx" parm [eax] [edx] value [eax] modify exact [eax];
extern void hold_sprite_cstat(unsigned char);
#pragma aux hold_sprite_cstat = parm [ah] modify exact [];

/* Keep the interpolation phase in EDX during the native switch. */
extern void keep_view_phase(long);
#pragma aux keep_view_phase = parm [edx] modify exact [];

void update_sprite_view(long, long);
#pragma aux update_sprite_view parm [eax] [edx] modify exact [eax ebx ecx edx esi edi];
void update_sprite_view(long camera_x, long camera_y)
{
    long delta, sector_offset, phase;
    unsigned char shade, cstat;

    begin_sprite_view(camera_x, camera_y);
    goto check_count;
next:
    classify_sprite_tile();
    /* Select the directional frame, mirroring directions beyond the half-turn. */
    load_view_y_in_edi();
    in_eax(active_sprite()->tile);
    load_view_x_in_ebx();
    in_eax(view_tile_animation_flags[eax_value()]);
    in_edx(active_sprite()->y);
    in_cl(al_value());
    in_eax(active_sprite()->x);
    in_edx(edx_value() - edi_value());
    in_eax(eax_value() - ebx_value());
    in_edx(getangle(eax_value(), edx_value()));
    in_eax(active_sprite()->angle);
    in_eax(eax_value() + 3200);
    in_eax(eax_value() - edx_value());
    in_eax(eax_value() & 0x7ff);
    in_eax(eax_value() >> 8);
    in_cl(cl_value() & 63);
    in_eax(eax_value() & 7);
    in_cl(cl_value() + 1);
    if (eax_value() > 4)
        goto mirror;
    in_edx(0);
    in_dl(cl_value());
    in_eax(eax_value() * edx_value());
    in_bx(active_sprite()->tile);
    in_dl((unsigned char)active_sprite()->cstat);
    in_ebx(ebx_value() + eax_value());
    in_dl(dl_value() & 0xfb);
    active_sprite()->tile = bx_value();
    *(unsigned char *)&active_sprite()->cstat = dl_value();
    goto check_interpolation;
mirror:
    in_edx(8);
    in_edx(edx_value() - eax_value());
    in_eax(0);
    in_al(cl_value());
    multiply_mirrored_frame(eax_value(), edx_value());
    in_dx(active_sprite()->tile);
    in_edx(edx_value() + eax_value());
    cstat = in_ah((unsigned char)active_sprite()->cstat);
    active_sprite()->tile = dx_value();
    hold_sprite_cstat(cstat);
    *(unsigned char *)&active_sprite()->cstat = in_ah(cstat | 4);

check_interpolation:
    in_eax(active_sprite()->status);
    in_eax(view_interpolation_modes[eax_value()]);
    if (eax_value() < 0)
        goto nearby;
    in_edx(active_sprite()->owner);
    in_ecx(edx_value());
    in_ecx(ecx_value() * 4);
    in_ebx(view_interpolation_clock);
    in_ecx(ecx_value() - edx_value());
    in_ebx(ebx_value() - edx_value());
    in_ecx(ecx_value() * 4);
    in_edx(ebx_value());
    in_ecx(ecx_value() + (long)view_previous_positions);
    /* Quantize the interpolation fraction for status-specific tick periods. */
    phase = edx_value();
    switch (eax_value()) {
    case 0: goto mode_0;
    case 1: goto mode_1;
    case 3: goto mode_3;
    case 7: goto mode_7;
    case 15: goto mode_15;
    default: goto apply_interpolation;
    }
mode_0:
    keep_view_phase(phase);
    get_view_interpolation_fraction();
    goto apply_interpolation;
mode_1:
    keep_view_phase(phase);
    in_edx(edx_value() & eax_value());
    get_view_interpolation_fraction();
    interpolate_view_ticks_1();
    goto add_fraction;
mode_3:
    keep_view_phase(phase);
    in_edx(edx_value() & 3);
    get_view_interpolation_fraction();
    interpolate_view_ticks_3();
    goto add_fraction;
mode_7:
    keep_view_phase(phase);
    in_edx(edx_value() & 7);
    get_view_interpolation_fraction();
    interpolate_view_ticks_7();
    goto add_fraction;
mode_15:
    keep_view_phase(phase);
    in_edx(edx_value() & eax_value());
    get_view_interpolation_fraction();
    interpolate_view_ticks_15();
add_fraction:
    apply_view_interpolation_term();
apply_interpolation:
    /* Interpolate from the saved pose toward the temporary sprite position. */
    in_edi(*(const long *)ecx_value());
    in_eax(active_sprite()->x);
    active_sprite()->x = edi_value();
    if ((delta = eax_value() - edi_value()) != 0)
        active_sprite()->x += multiply_view_fraction(delta);
    in_ebx(*(const long *)(ecx_value() + 4));
    in_eax(active_sprite()->y);
    active_sprite()->y = ebx_value();
    if ((delta = eax_value() - ebx_value()) != 0)
        active_sprite()->y += multiply_view_fraction(delta);
    in_edx(*(const long *)(ecx_value() + 8));
    in_eax(active_sprite()->z);
    active_sprite()->z = edx_value();
    if ((delta = eax_value() - edx_value()) != 0)
        active_sprite()->z += multiply_view_fraction(delta);

nearby:
    /* Hide the close-range cstat bit for the original four sprite statuses. */
    in_eax(active_sprite()->status);
    if (eax_value() == 3 || eax_value() == 4 || eax_value() == 5 || eax_value() == 7) {
        delta = absolute_view_dist(in_eax(view_x_in_eax() - active_sprite()->x));
        if (delta < 256) {
            delta = absolute_view_dist(in_eax(view_y_in_eax() - active_sprite()->y));
            if (delta < 256)
                *(unsigned char *)&active_sprite()->cstat &= 0xfd;
        }
    }
    in_edx(active_sprite()->sector);
    in_eax(in_eax(edx_value()) * 4);
    shade = in_bl(active_sprite()->shade);
    in_eax(eax_value() + edx_value());
    shade = in_bl(shade + 6);
    sector_offset = in_eax(eax_value() * 8);
    active_sprite()->shade = shade;
    in_dx(*(const short *)((const char *)view_sector_ceiling_flags + sector_offset));
    /* Add the sector ceiling or floor shade to the temporary sprite. */
    if (check_view_floor_shade()) {
        shade = in_cl(bl_value());
        in_al(view_sector_ceiling_shade[eax_value()]);
        active_sprite()->shade = in_cl(shade + al_value());
    } else {
        shade = in_bh(bl_value());
        in_al(view_sector_floor_shade[eax_value()]);
        active_sprite()->shade = in_bh(shade + al_value());
    }
    load_view_sprite_index();
    in_eax(eax_value() + 1);
    in_esi(active_sprite() + 1);
    save_view_sprite_index(eax_value());
check_count:
    load_view_sprite_index();
    if (eax_value() < view_sprite_count)
        goto next;
    finish_sprite_view();
}
