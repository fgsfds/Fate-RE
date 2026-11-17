/* Select a random spawn sector and resolve the centroid against nearby walls. */
extern short numsectors;
extern short spawn_hitag[], spawn_lotag[], spawn_floor_flags[];
extern short spawn_first_wall[], spawn_wall_count[];
extern long spawn_ceiling[], spawn_floor[], spawn_wall_x[], spawn_wall_y[];

extern int krand(void);
#pragma aux krand modify exact [eax];
extern int inside(long, long, int);
#pragma aux inside parm [eax] [edx] [ebx] modify exact [eax];
extern int pushmove_spawn(void);
#pragma aux pushmove_spawn "pushmove_" modify exact [eax ebx ecx edx];

/* Retain the original scratch frame and saved output pointers. */
extern void begin_spawn(long *, long *, short *);
#pragma aux begin_spawn = "push ecx" "push esi" "push edi" "push ebp" \
    "sub esp,1ch" "push eax" "push edx" "push ebx" "mov dword ptr [esp+18h],100h" \
    parm [eax] [edx] [ebx] modify exact [];
extern void end_spawn(void);
#pragma aux end_spawn = "add esp,28h" "pop ebp" "pop edi" "pop esi" "pop ecx" modify exact [];
extern long spawn_random_sector(int);
#pragma aux spawn_random_sector = "imul ebx" "shrd eax,edx,10h" parm [eax] value [eax] modify exact [eax edx];
extern void save_sector_pick(long);
#pragma aux save_sector_pick = "mov [esp+20h],eax" parm [eax] modify exact [];
extern void squash_spawn_hitag(void);
#pragma aux squash_spawn_hitag = "xor dh,dh" modify exact [edx];
extern long spawn_slope_flag(void);
#pragma aux spawn_slope_flag = "xor dh,dh" "and dl,1" "movsx edx,dx" value [edx] modify exact [edx];
extern void add_spawn_x(long);
#pragma aux add_spawn_x = "add [esp+14h],eax" parm [eax] modify exact [];
extern void add_spawn_y(long);
#pragma aux add_spawn_y = "add [esp+10h],eax" parm [eax] modify exact [];
extern void widen_spawn_max_y(long, long);
#pragma aux widen_spawn_max_y = "cmp ebp,edx" "jge enough" "mov ebp,edx" "enough:" parm [edx] [ebx] modify exact [];
extern void measure_spawn_y(void);
#pragma aux measure_spawn_y = "sub ebp,edi" modify exact [];
extern short load_spawn_wall_end(void);
#pragma aux load_spawn_wall_end = "mov eax,[esp+1ch]" value [ax] modify exact [eax];
extern long load_spawn_wall_first(void);
#pragma aux load_spawn_wall_first = "movsx eax,word ptr [esp+24h]" value [eax] modify exact [eax];
extern long load_spawn_sum_x(void);
#pragma aux load_spawn_sum_x = "mov eax,[esp+14h]" value [eax] modify exact [eax];
extern long load_spawn_sum_y(void);
#pragma aux load_spawn_sum_y = "mov eax,[esp+10h]" value [eax] modify exact [eax];
extern void store_spawn_average_x(long);
#pragma aux store_spawn_average_x = "mov [esp+14h],eax" parm [eax] modify exact [];
extern void store_spawn_average_y(long);
#pragma aux store_spawn_average_y = "mov [esp+10h],eax" parm [eax] modify exact [];
extern void load_spawn_inside_arg(void);
#pragma aux load_spawn_inside_arg = "movsx ebx,word ptr [esp+20h]" modify exact [ebx];

/* Zero-byte bindings preserve the original Watcom register assignments. */
extern long in_eax(long);
#pragma aux in_eax = parm [eax] value [eax] modify exact [];
extern long in_ebx(long);
#pragma aux in_ebx = parm [ebx] value [ebx] modify exact [];
extern long in_ecx(long);
#pragma aux in_ecx = parm [ecx] value [ecx] modify exact [];
extern long in_edx(long);
#pragma aux in_edx = parm [edx] value [edx] modify exact [];
extern long in_esi(long);
#pragma aux in_esi = parm [esi] value [esi] modify exact [];
extern long in_edi(long);
#pragma aux in_edi = parm [edi] value [edi] modify exact [];
extern short in_bx(short);
#pragma aux in_bx = parm [bx] value [bx] modify exact [];
extern short in_dx(short);
#pragma aux in_dx = parm [dx] value [dx] modify exact [];
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
extern long edi_value(void);
#pragma aux edi_value = value [edi] modify exact [];
extern long ebp_value(void);
#pragma aux ebp_value = value [ebp] modify exact [];
extern short ax_value(void);
#pragma aux ax_value = value [ax] modify exact [];
extern short bx_value(void);
#pragma aux bx_value = value [bx] modify exact [];
extern short cx_value(void);
#pragma aux cx_value = value [cx] modify exact [];
extern short dx_value(void);
#pragma aux dx_value = value [dx] modify exact [];

/* These two relative branch targets are verified at their original offsets. */
extern void spawn_try_sector(void);
extern void spawn_test_retry_budget(void);
extern void jump_spawn_budget_check(void);
#pragma aux jump_spawn_budget_check = "jmp near spawn_test_retry_budget" modify exact [];
extern void decrement_spawn_budget(void);
#pragma aux decrement_spawn_budget = "dec dword ptr [esp+18h]" modify exact [];
extern void check_spawn_budget(void);
#pragma aux check_spawn_budget = "cmp dword ptr [esp+18h],0" "jge near spawn_try_sector" modify exact [];

extern void store_wall_start(void);
#pragma aux store_wall_start = "mov [esp+24h],edx" modify exact [];
extern void load_wall_start_in_ecx(void);
#pragma aux load_wall_start_in_ecx = "mov ecx,[esp+24h]" modify exact [ecx];
extern void store_wall_end(void);
#pragma aux store_wall_end = "mov [esp+1ch],edx" modify exact [];
extern void load_wall_start_in_ebx(void);
#pragma aux load_wall_start_in_ebx = "mov ebx,[esp+24h]" modify exact [ebx];
extern void clear_wall_sums(long);
#pragma aux clear_wall_sums = "mov [esp+14h],esi" "mov [esp+10h],esi" parm [esi] modify exact [];
extern void initialize_maximum_y(void);
#pragma aux initialize_maximum_y = "mov ebp,esi" modify exact [];
extern void load_output_x(void);
#pragma aux load_output_x = "mov edx,[esp+8]" modify exact [edx];
extern void load_output_y(void);
#pragma aux load_output_y = "mov edx,[esp+4]" modify exact [edx];
extern void load_output_sector(void);
#pragma aux load_output_sector = "mov edx,[esp]" modify exact [edx];
extern void load_final_sector(void);
#pragma aux load_final_sector = "mov eax,[esp+20h]" modify exact [eax];
extern void begin_spawn_clip(void);
#pragma aux begin_spawn_clip = "movsx edx,word ptr [esp+20h]" "push 0" modify exact [edx];
extern void push_spawn_floor_clearance(void);
#pragma aux push_spawn_floor_clearance = "push 400h" modify exact [];
extern void prepare_spawn_clip_sector(void);
#pragma aux prepare_spawn_clip_sector = "lea ecx,[esp+28h]" modify exact [ecx];
extern void push_spawn_ceiling_clearance_and_prepare_z(void);
#pragma aux push_spawn_ceiling_clearance_and_prepare_z = "push 400h" "lea ebx,[esp+18h]" modify exact [ebx];
extern void push_spawn_clip_radius(void);
#pragma aux push_spawn_clip_radius = "push 80h" modify exact [];
extern void clip_prepare_y(long);
#pragma aux clip_prepare_y = "lea edx,[esp+20h]" parm [eax] modify exact [edx];
extern void clip_prepare_x(long);
#pragma aux clip_prepare_x = "mov [esp+1ch],eax" "lea eax,[esp+24h]" parm [eax] modify exact [eax];

void find_spawn_position(long *, long *, short *);
#pragma aux find_spawn_position parm [eax] [edx] [ebx] modify exact [eax ebx ecx edx esi edi];

void find_spawn_position(long *x, long *y, short *sector)
{
    long offset, ceiling, floor, coord, sum;
    short wall_end;

    begin_spawn(x, y, sector);
    jump_spawn_budget_check();

sample_sector:
    /* Exclude low ceilings, tagged sectors, and sloped floors before spending a retry. */
    in_dx(numsectors);
    in_ebx(dx_value());
    spawn_random_sector(krand());
    in_edx(ax_value());
    save_sector_pick(eax_value());
    offset = in_eax((in_eax(edx_value()) * 4 + edx_value()) * 8);
    ceiling = in_edx(*(const long *)((const char *)spawn_ceiling + offset));
    floor = in_ecx(*(const long *)((const char *)spawn_floor + eax_value()));
    if (in_edx(ceiling + 2048) >= floor)
        goto sample_sector;
    in_dx(*(const short *)((const char *)spawn_hitag + eax_value()));
    squash_spawn_hitag();
    in_ecx(dx_value());
    in_edx(*(const short *)((const char *)spawn_lotag + eax_value()));
    if (edx_value() | ecx_value())
        goto sample_sector;
    in_dx(*(const short *)((const char *)spawn_floor_flags + eax_value()));
    if (spawn_slope_flag())
        goto sample_sector;
    in_dx(*(const short *)((const char *)spawn_first_wall + eax_value()));
    in_bx(*(const short *)((const char *)spawn_wall_count + eax_value()));
    store_wall_start();
    in_edx(edx_value() + ebx_value());
    load_wall_start_in_ecx();
    store_wall_end();
    if (dx_value() <= cx_value())
        goto failed;

    /* Accumulate the vertex centroid and require at least 256 units on both axes. */
    in_ecx(2147483647L);
    in_esi(0);
    load_wall_start_in_ebx();
    clear_wall_sums(esi_value());
    in_esi(-2147483647L - 1);
    in_edi(ecx_value());
    initialize_maximum_y();
    goto check_walls;
collect_wall:
    offset = in_edx(in_edx(bx_value()) * 32);
    add_spawn_x(in_eax(*(const long *)((const char *)spawn_wall_x + offset)));
    add_spawn_y(in_eax(*(const long *)((const char *)spawn_wall_y + edx_value())));
    coord = in_eax(*(const long *)((const char *)spawn_wall_x + edx_value()));
    if (ecx_value() > coord)
        in_ecx(coord);
    offset = in_eax(in_eax(bx_value()) * 32);
    coord = in_edx(*(const long *)((const char *)spawn_wall_x + offset));
    if (esi_value() < coord)
        in_esi(coord);
    offset = in_eax(in_eax(bx_value()) * 32);
    coord = in_edx(*(const long *)((const char *)spawn_wall_y + offset));
    if (edi_value() > coord)
        in_edi(coord);
    offset = in_eax(in_eax(bx_value()) * 32);
    widen_spawn_max_y(in_edx(*(const long *)((const char *)spawn_wall_y + offset)), ebx_value());
    in_ebx(ebx_value() + 1);

check_walls:
    wall_end = load_spawn_wall_end();
    if (bx_value() < wall_end)
        goto collect_wall;
    if (in_esi(esi_value() - ecx_value()) <= 256)
        goto failed;
    measure_spawn_y();
    if (ebp_value() <= 256)
        goto failed;

    /* Reject centroids outside the sector or positions that wall clipping cannot resolve. */
    in_ebx(ax_value());
    in_ebx(ebx_value() - load_spawn_wall_first());
    sum = load_spawn_sum_x();
    store_spawn_average_x(sum / ebx_value());
    sum = in_eax(load_spawn_sum_y() / ebx_value());
    load_spawn_inside_arg();
    store_spawn_average_y(sum);
    in_edx(eax_value());
    if (!inside(load_spawn_sum_x(), edx_value(), ebx_value()))
        goto failed;
    /* Set up the original callee-cleanup pushmove arguments around the floor lookup. */
    begin_spawn_clip();
    in_eax(edx_value());
    push_spawn_floor_clearance();
    in_eax(eax_value() * 4);
    prepare_spawn_clip_sector();
    in_eax(eax_value() + edx_value());
    push_spawn_ceiling_clearance_and_prepare_z();
    in_eax(spawn_floor[eax_value() * 2]);
    push_spawn_clip_radius();
    in_eax(eax_value() - 8192);
    clip_prepare_y(eax_value());
    clip_prepare_x(eax_value());
    if (pushmove_spawn() < 0)
        goto failed;
    load_output_x();
    load_spawn_sum_x();
    *(long *)edx_value() = eax_value();
    load_output_y();
    load_spawn_sum_y();
    *(long *)edx_value() = eax_value();
    load_output_sector();
    load_final_sector();
    *(short *)edx_value() = ax_value();
    goto done;
failed:
    decrement_spawn_budget();
    check_spawn_budget();
done:
    end_spawn();
}
