/* Apply a nearby blast to the player and qualifying status-zero sprites. */
extern long blast_player_x, blast_player_y;
extern long blast_sprite_x[], blast_sprite_y[];
extern short blast_head_sprite_status, blast_next_sprite_status[], blast_sprite_actor[];
extern short blast_sprite_lotag[], blast_sprite_tile[], blast_sprite_cstat[];
extern short blast_sprite_xvel[], blast_sprite_yvel[], blast_sprite_zvel[];
extern unsigned char blast_sprite_xrepeat[], actor_kind[];
extern const float blast_horizontal_scale, blast_vertical_scale, blast_vertical_limit, blast_vertical_velocity;

extern long absolute_long(long);
#pragma aux absolute_long parm [eax] modify exact [eax];
extern void adjust_blast_player_status(long);
#pragma aux adjust_blast_player_status parm [eax] modify exact [eax];
extern int blast_random(void);
#pragma aux blast_random parm [] modify exact [eax];
extern void play_sound(long, long, long, long);
#pragma aux play_sound parm [eax] [edx] [ebx] [ecx] modify exact [eax];
extern long blast_distance_root(long);
#pragma aux blast_distance_root parm [eax] modify exact [eax];
extern void truncate_st0(void);
#pragma aux truncate_st0 modify exact [eax];
extern void start_blast_sequence(int);
#pragma aux start_blast_sequence parm [eax] modify exact [eax];
extern void add_listed_sprite(int);
#pragma aux add_listed_sprite parm [eax] modify exact [eax];

/* Preserve the original x87 scratch slots and the incoming source index in AX. */
extern void begin_sprite_blast(void);
#pragma aux begin_sprite_blast = "push ebx" "push ecx" "push edx" "push esi" "push edi" "push ebp" "sub esp,28" \
    modify exact [];
extern void end_sprite_blast(void);
#pragma aux end_sprite_blast = "add esp,28" "pop ebp" "pop edi" "pop esi" "pop edx" "pop ecx" "pop ebx" modify exact [];
extern void store_blast_x(long);
#pragma aux store_blast_x = "mov [esp+20],edx" parm [edx] modify exact [];
extern void store_target_blast_x(long);
#pragma aux store_target_blast_x = "mov [esp+20],ecx" parm [ecx] modify exact [];
extern void store_blast_y(long);
#pragma aux store_blast_y = "mov [esp+16],edx" parm [edx] modify exact [];
extern void store_target_blast_y(long);
#pragma aux store_target_blast_y = "mov [esp+16],ecx" parm [ecx] modify exact [];
extern long blast_x(void);
#pragma aux blast_x = "mov eax,[esp+20]" value [eax] modify exact [eax];
extern long blast_y_in_edx(void);
#pragma aux blast_y_in_edx = "mov edx,[esp+16]" value [edx] modify exact [edx];
extern void select_blast_sound_variant(long);
#pragma aux select_blast_sound_variant = "mov edx,eax" "mov ecx,2" "sar edx,31" "idiv ecx" parm [ebx] modify exact [eax ecx edx];

extern void load_blast_source_x(void);
#pragma aux load_blast_source_x = "mov ebp,[eax+blast_sprite_x]" modify exact [];
extern void load_blast_source_y(void);
#pragma aux load_blast_source_y = "mov ebp,[eax+blast_sprite_y]" modify exact [];
extern long blast_source_coord(void);
#pragma aux blast_source_coord = value [ebp] modify exact [];
extern void keep_low_lotag(void);
#pragma aux keep_low_lotag = "xor ah,ah" "cwde" modify exact [eax];

/* Keep the x87 precision, rounding helper calls, and store order of the impulse. */
extern void prepare_blast_factors(void);
#pragma aux prepare_blast_factors = \
    "mov [esp+4],eax" "fild dword ptr [esp+4]" "fdivr dword ptr [blast_horizontal_scale]" \
    "imul eax,eax" "fstp dword ptr [esp+8]" "mov [esp+4],eax" "fild dword ptr [esp+4]" \
    "fdivr dword ptr [blast_vertical_scale]" "fst dword ptr [esp]" "fcomp dword ptr [blast_vertical_limit]" \
    "fnstsw ax" "sahf" "jbe next_step" "mov dword ptr [esp],40400000h" "next_step:" modify exact [eax];
extern void calculate_blast_xy(void);
#pragma aux calculate_blast_xy = \
    "fld dword ptr [esp+8]" "fild dword ptr [esp+20]" "fmul st,st(1)" \
    "fld dword ptr [esp]" "fxch st(1)" "fmul st,st(1)" "call truncate_st0" \
    "fistp dword ptr [esp+4]" "fild dword ptr [esp+16]" "fmulp st(2),st" \
    "fxch st(1)" "fmul st,st(1)" "call truncate_st0" "fistp dword ptr [esp+24]" modify exact [eax];
extern void store_blast_velocity(void);
#pragma aux store_blast_velocity = \
    "fmul dword ptr [blast_vertical_velocity]" "movsx ecx,bx" "imul edx,ecx,44" \
    "call truncate_st0" "fistp dword ptr [esp+12]" "mov eax,[esp+4]" \
    "mov [edx+blast_sprite_xvel],ax" "mov eax,[esp+24]" "mov [edx+blast_sprite_yvel],ax" \
    "mov eax,[esp+12]" "mov [edx+blast_sprite_zvel],ax" modify exact [eax ecx edx];

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
extern short in_ax(short);
#pragma aux in_ax = parm [ax] value [ax] modify exact [];
extern short in_bx(short);
#pragma aux in_bx = parm [bx] value [bx] modify exact [];
extern short in_si(short);
#pragma aux in_si = parm [si] value [si] modify exact [];
extern unsigned char in_al(unsigned char);
#pragma aux in_al = parm [al] value [al] modify exact [];
extern long eax_value(void);
#pragma aux eax_value = value [eax] modify exact [];
extern long ebx_value(void);
#pragma aux ebx_value = value [ebx] modify exact [];
extern long ecx_value(void);
#pragma aux ecx_value = value [ecx] modify exact [];
extern long edx_value(void);
#pragma aux edx_value = value [edx] modify exact [];
extern long esi_value(void);
#pragma aux esi_value = value [esi] modify exact [];
extern short ax_value(void);
#pragma aux ax_value = value [ax] modify exact [];
extern short bx_value(void);
#pragma aux bx_value = value [bx] modify exact [];
extern short di_value(void);
#pragma aux di_value = value [di] modify exact [];
extern short cx_value(void);
#pragma aux cx_value = value [cx] modify exact [];

void apply_sprite_blast(long);
#pragma aux apply_sprite_blast parm [eax] modify exact [eax ebx ecx edx esi edi];

void apply_sprite_blast(long source)
{
    long x, y, sound;
    unsigned char repeat;

    (void)source;
    begin_sprite_blast();
    in_edi(eax_value());
    in_eax(in_eax(ax_value()) * 44);
    in_edx(blast_player_x - *(const long *)((const char *)blast_sprite_x + eax_value()));
    in_ecx(*(const long *)((const char *)blast_sprite_y + eax_value()));
    store_blast_x(edx_value());
    in_edx(blast_player_y);
    x = blast_x();
    in_edx(edx_value() - ecx_value());
    x = absolute_long(x);
    store_blast_y(edx_value());
    if (x >= 1024 || absolute_long(edx_value()) >= 1024)
        goto start_list;
    /* Hit the player only inside the 1024-unit axis-aligned radius. */
    adjust_blast_player_status(-400);
    blast_random();
    select_blast_sound_variant(ebx_value());
    in_ebx(0);
    sound = in_eax(edx_value() + 15);
    in_ecx(0);
    in_edx(0);
    play_sound(sound, edx_value(), ebx_value(), ecx_value());

start_list:
    in_bx(blast_head_sprite_status);
    goto check_list;
next_sprite:
    /* Read the next link before any animation or status changes affect this sprite. */
    in_eax(in_eax(di_value()) * 44);
    in_edx(bx_value());
    in_si(blast_next_sprite_status[edx_value()]);
    in_edx(edx_value() * 44);
    load_blast_source_x();
    in_ecx(*(const long *)((const char *)blast_sprite_x + edx_value()) - blast_source_coord());
    store_target_blast_x(ecx_value());
    load_blast_source_y();
    in_ecx(*(const long *)((const char *)blast_sprite_y + edx_value()));
    x = blast_x();
    in_ecx(ecx_value() - blast_source_coord());
    x = absolute_long(x);
    store_target_blast_y(ecx_value());
    if (x >= 1024 || absolute_long(ecx_value()) >= 1024)
        goto advance;
    in_ax(*(const short *)((const char *)blast_sprite_lotag + edx_value()));
    keep_low_lotag();
    if (eax_value() != 100 && eax_value() != 101)
        goto check_tile;

    /* Sprite tags 100 and 101 receive the distance-scaled impulse. */
    x = blast_x();
    x = in_eax(x * x);
    y = blast_y_in_edx();
    y = in_edx(y * y);
    blast_distance_root(in_eax(x + y));
    prepare_blast_factors();
    calculate_blast_xy();
    store_blast_velocity();
    start_blast_sequence(in_eax(ecx_value()));
    in_ax(blast_sprite_actor[ecx_value()]);
    if (in_eax(ax_value()) != -1) {
        actor_kind[eax_value()] = 3;
        repeat = in_al(*((const unsigned char *)blast_sprite_xrepeat + edx_value()));
        in_ecx(0);
        repeat = in_al(repeat * 2);
        *(short *)((char *)blast_sprite_cstat + edx_value()) = cx_value();
        *((unsigned char *)blast_sprite_xrepeat + edx_value()) = repeat;
    }
    add_listed_sprite(in_eax(bx_value()));
check_tile:
    in_eax(bx_value());
    in_edx(in_edx(eax_value() * 44));
    in_edx(*(const short *)((const char *)blast_sprite_tile + edx_value()));
    if (edx_value() == 0x154)
        start_blast_sequence(eax_value());
advance:
    in_ebx(esi_value());
check_list:
    if (bx_value() >= 0)
        goto next_sprite;
    end_sprite_blast();
}
