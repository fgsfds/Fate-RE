/* Route setup shares the dispatcher stack. Each C entry below starts at
 * an original branch target, with frame_slot naming the word at ESP.
 */
extern short route_last_zone;
extern unsigned char route_records[], route_sector_lists[];
extern void advance_route_zone(long);
extern void updatesector(long, long, short *);
#pragma aux updatesector parm [eax] [edx] [ebx] modify exact [eax ebx ecx];

#define ROUTE_STACK(type, offset) (*(volatile type *)((char *)&frame_slot + (offset)))
#define ROUTE_POINTS(offset) (*(long **)(route_records + (offset)))
#define ROUTE_SECTORS(offset) (*(short **)(route_sector_lists + (offset)))

extern long get_eax(void);
#pragma aux get_eax = "" value [eax] modify exact [];
extern long put_eax(long);
#pragma aux put_eax = "" parm [eax] value [eax] modify exact [];
extern long get_ebx(void);
#pragma aux get_ebx = "" value [ebx] modify exact [];
extern long put_ebx(long);
#pragma aux put_ebx = "" parm [ebx] value [ebx] modify exact [];
extern long get_ecx(void);
#pragma aux get_ecx = "" value [ecx] modify exact [];
extern long put_ecx(long);
#pragma aux put_ecx = "" parm [ecx] value [ecx] modify exact [];
extern long get_edx(void);
#pragma aux get_edx = "" value [edx] modify exact [];
extern long put_edx(long);
#pragma aux put_edx = "" parm [edx] value [edx] modify exact [];
extern long get_esi(void);
#pragma aux get_esi = "" value [esi] modify exact [];
extern long put_esi(long);
#pragma aux put_esi = "" parm [esi] value [esi] modify exact [];
extern long get_edi(void);
#pragma aux get_edi = "" value [edi] modify exact [];
extern long put_edi(long);
#pragma aux put_edi = "" parm [edi] value [edi] modify exact [];
extern long get_ebp(void);
#pragma aux get_ebp = "" value [ebp] modify exact [];
extern short get_cx(void);
#pragma aux get_cx = "" value [cx] modify exact [];
extern short get_ax(void);
#pragma aux get_ax = "" value [ax] modify exact [];

extern void resume_waypoint_loop(void);
#pragma aux resume_waypoint_loop = "" aborts modify exact [];
extern void skip_waypoint_terminator(void);
#pragma aux skip_waypoint_terminator = "cmp esi,-1" "je near advance_route_zone" modify exact [];

extern void continue_if_valid_waypoint(void);
#pragma aux continue_if_valid_waypoint = "cmp word ptr [esp+24h],0" "db 7dh,24h" aborts modify exact [];

void resolve_route_waypoint(long frame_slot);
#pragma aux resolve_route_waypoint parm routine [] aborts modify exact [eax ebx ecx edx esi edi];

void store_route_waypoint_sector(long frame_slot);
#pragma aux store_route_waypoint_sector parm routine [] aborts modify exact [eax ebx ecx esi];

extern void route_check_zone_index(long);
extern void route_check_waypoint_index(long);
extern void route_start_zone_scan(void);
extern void jump_to_zone_check(void);
#pragma aux jump_to_zone_check = "jmp near route_check_zone_index" aborts modify exact [];
extern void jump_to_waypoint_check(void);
#pragma aux jump_to_waypoint_check = "jmp near route_check_waypoint_index" aborts modify exact [];
extern void check_route_zone_limit(void);
#pragma aux check_route_zone_limit = "cmp ax,[route_last_zone]" "jle near route_start_zone_scan" modify exact [];

void resolve_route_sectors(long frame_slot);
#pragma aux resolve_route_sectors parm routine [] aborts modify exact [ebx];

void route_start_zone_scan(void);
#pragma aux route_start_zone_scan aborts modify exact [ecx];

void advance_route_zone(long frame_slot);
#pragma aux advance_route_zone parm routine [] aborts modify exact [];

void route_check_zone_index(long frame_slot);
#pragma aux route_check_zone_index parm routine [] aborts modify exact [eax];

extern char route_error_buffer[];
extern const char route_bad_waypoint[], route_missing_terminator[];
extern void format_route_error(char *, const char *, ...);
#pragma aux format_route_error parm caller [] modify exact [eax];
extern void report_route_error(const char *);
#pragma aux report_route_error parm [eax] modify exact [eax];
extern void repeat_route_waypoints(void);
#pragma aux repeat_route_waypoints = "movsx ebp,cx" "cmp ebp,32h" "jle near resolve_route_waypoint" modify exact [];
void route_report_bad_waypoint(long frame_slot);
#pragma aux route_report_bad_waypoint parm routine [] aborts modify exact [eax esi];

void route_check_waypoint_index(long frame_slot);
#pragma aux route_check_waypoint_index parm routine [] aborts modify exact [eax];

void resolve_route_sectors(long frame_slot)
{
    ROUTE_STACK(long, 0x30) = put_ebx(0);
    jump_to_zone_check();
}

void route_start_zone_scan(void)
{
    put_ecx(0);
    jump_to_waypoint_check();
}

void resolve_route_waypoint(long frame_slot)
{
    put_eax(ROUTE_STACK(short, 0x30));
    ROUTE_STACK(long, 0x14) = get_eax();
    put_eax(get_eax() * 22);
    put_ebx(get_ebp());
    put_ebx(get_ebx() << 3);
    put_eax((long)ROUTE_POINTS(get_eax()));
    put_eax(get_eax() + get_ebx());
    put_esi(*(long *)get_eax());
    skip_waypoint_terminator();
    put_edi(((long *)get_eax())[1]);
    put_ebx((long)&ROUTE_STACK(short, 0x24));
    put_edx(get_edi());
    put_eax(get_esi());
    updatesector(get_eax(), get_edx(), (short *)get_ebx());
    continue_if_valid_waypoint();
}

void route_report_bad_waypoint(long frame_slot)
{
    format_route_error(route_error_buffer, route_bad_waypoint, put_esi(ROUTE_STACK(long, 0x14)),
                       get_ebp(), get_esi(), get_edi());
    report_route_error(route_error_buffer);
    resume_waypoint_loop();
}

void store_route_waypoint_sector(long frame_slot)
{
    put_eax(ROUTE_STACK(short, 0x30));
    put_eax(get_eax() * 22);
    put_ebx(get_cx());
    put_esi((long)ROUTE_SECTORS(get_eax()));
    put_eax(ROUTE_STACK(long, 0x24));
    put_ecx(get_ecx() + 1);
    ((short *)get_esi())[get_ebx()] = get_ax();
    resume_waypoint_loop();
}

void route_check_waypoint_index(long frame_slot)
{
    repeat_route_waypoints();
    format_route_error(route_error_buffer, route_missing_terminator, put_eax(ROUTE_STACK(short, 0x30)));
    report_route_error(route_error_buffer);
    resume_waypoint_loop();
}

void advance_route_zone(long frame_slot)
{
    ++ROUTE_STACK(long, 0x30);
    resume_waypoint_loop();
}

void route_check_zone_index(long frame_slot)
{
    put_eax(ROUTE_STACK(long, 0x30));
    check_route_zone_limit();
    resume_waypoint_loop();
}

extern short route_actor_sprite[];
extern short route_sprite_hitag[];
extern unsigned char route_actor_sequence[];
extern long route_sprite_x[], route_sprite_y[];
extern void finish_actor_route(void);
extern void route_check_bounds_index(void);
#define SPRITE_FIELD(field, offset) (*(field##_type *)((char *)route_sprite_##field + (offset)))
typedef long x_type;
typedef long y_type;
typedef short hitag_type;
extern short put_ax(short);
#pragma aux put_ax = "" parm [ax] value [ax] modify exact [];
extern unsigned char put_dl(unsigned char);
#pragma aux put_dl = "" parm [dl] value [dl] modify exact [];
extern unsigned char get_dl(void);
#pragma aux get_dl = "" value [dl] modify exact [];
extern short put_bx(short);
#pragma aux put_bx = "" parm [bx] value [bx] modify exact [];
extern void return_for_script_route(void);
#pragma aux return_for_script_route = "xor bl,bl" "and bh,40h" "movsx ebx,bx" "test ebx,ebx" "jne near finish_actor_route" modify exact [ebx];
extern void scan_route_bounds(void);
#pragma aux scan_route_bounds = "jmp near route_check_bounds_index" aborts modify exact [];
void route_find_actor_sprite(long frame_slot);
#pragma aux route_find_actor_sprite parm routine [] aborts modify exact [eax ebx ecx edx];
void route_find_actor_sprite(long frame_slot)
{
    put_edx(ROUTE_STACK(short, 0xc));
    put_ax(route_actor_sprite[get_edx()]);
    ROUTE_STACK(long, 0x28) = get_eax();
    put_eax(get_ax());
    put_eax(get_eax() * 44);
    put_bx(SPRITE_FIELD(hitag, get_eax()));
    return_for_script_route();
    put_dl(route_actor_sequence[get_edx()]);
    ROUTE_STACK(unsigned char, 0x38) = get_dl();
    put_edx(SPRITE_FIELD(x, get_eax()));
    put_eax(SPRITE_FIELD(y, get_eax()));
    put_ecx(0);
    ROUTE_STACK(long, 0x1c) = get_eax();
    scan_route_bounds();
}


extern long *route_zone_bounds;
extern void route_read_bounds(long);
extern void route_continue_bounds_if_available(void);
#pragma aux route_continue_bounds_if_available = "cmp cx,bx" "jle near route_read_bounds" aborts modify exact [];
extern void route_sort_x_bounds(void);
#pragma aux route_sort_x_bounds = "cmp ebx,eax" "jge x_min" "mov esi,ebx" "jmp short x_max" "x_min:" "mov esi,eax" "x_max:" "mov ebp,esi" "jle x_done" "mov eax,ebx" "x_done:" modify exact [eax esi];
extern void route_sort_y_bounds(void);
#pragma aux route_sort_y_bounds = "cmp ebx,eax" "jge y_min" "mov esi,ebx" "jmp short y_max" "y_min:" "mov esi,eax" "y_max:" "jle y_done" "mov eax,ebx" "y_done:" modify exact [eax esi];
extern void check_route_target_y_bounds(void);
#pragma aux check_route_target_y_bounds = "cmp esi,[esp+4]" "db 7fh, 0ah" /* marker-rel8 0,+1 */ "cmp eax,[esp+4]" "db 7ch, 04h" /* marker-rel8 0,+1 */ modify exact [];
extern void finish_bounds_iteration(void);
#pragma aux finish_bounds_iteration = "" aborts modify exact [];

void route_read_bounds(long frame_slot);
#pragma aux route_read_bounds parm routine [] aborts modify exact [eax ebx ecx esi edi];
void route_read_bounds(long frame_slot)
{
    put_eax(get_cx());
    put_ebx((long)route_zone_bounds);
    put_eax(get_eax() << 4);
    put_eax(get_eax() + get_ebx());
    put_ebx(((long *)get_eax())[0]);
    put_eax(((long *)get_eax())[2]);
    route_sort_x_bounds();
    put_edi(get_eax());
    put_eax(get_cx());
    put_ebx((long)route_zone_bounds);
    put_eax(get_eax() << 4);
    put_eax(get_eax() + get_ebx());
    put_ebx(((long *)get_eax())[1]);
    put_eax(((long *)get_eax())[3]);
    route_sort_y_bounds();
    put_ebx(get_eax());

    if (get_ebp() > ROUTE_STACK(long, 8))
        goto check_actor;
    if (get_edi() < ROUTE_STACK(long, 8))
        goto check_actor;
    check_route_target_y_bounds();
    ROUTE_STACK(long, 0x34) = get_ecx();
check_actor:
    if (get_edx() < get_ebp() || get_edx() > get_edi())
        goto advance;
    put_edi(ROUTE_STACK(long, 0x1c));
    if (get_esi() > get_edi() || get_ebx() < get_edi())
        goto advance;
    ROUTE_STACK(long, 0x2c) = get_ecx();
advance:
    put_ecx(get_ecx() + 1);
    finish_bounds_iteration();
}

void route_check_bounds_index(void);
#pragma aux route_check_bounds_index aborts modify exact [ebx];
void route_check_bounds_index(void)
{
    put_bx(route_last_zone);
    route_continue_bounds_if_available();
}

extern unsigned char *route_zone_routes;
extern void route_move_to_zone_exit(long);
extern long absolute_long(long);
#pragma aux absolute_long parm [eax] modify exact [eax];

extern short get_bx(void);
#pragma aux get_bx = "" value [bx] modify exact [];
extern unsigned char put_al(unsigned char);
#pragma aux put_al = "" parm [al] value [al] modify exact [];
extern unsigned char put_ah(unsigned char);
#pragma aux put_ah = "" parm [ah] value [ah] modify exact [];
extern void check_route_exit_distance(void);
#pragma aux check_route_exit_distance = "cmp eax,100h" "jge near route_move_to_zone_exit" modify exact [];
extern void load_actor_y_in_ebp(void);
#pragma aux load_actor_y_in_ebp = "mov ebp,[esp+1ch]" modify exact [];
extern void continue_zone_route(void);
#pragma aux continue_zone_route = "" aborts modify exact [];

void route_read_zone_route(long frame_slot);
#pragma aux route_read_zone_route parm routine [] aborts modify exact [eax ebx ecx edx esi edi];
void route_read_zone_route(long frame_slot)
{
    /* Each source/destination pair has a three-byte route record. */
    put_eax(get_bx());
    put_ebx(ROUTE_STACK(short, 0x2c));
    put_eax(get_eax() + 1);
    put_ecx(get_ebx());
    put_ecx(get_ecx() * get_eax());
    put_esi(get_ecx());
    put_esi(get_esi() << 2);
    put_eax((long)route_zone_routes);
    put_esi(get_esi() - get_ecx());
    put_ecx(ROUTE_STACK(short, 0x34));
    put_esi(get_esi() + get_eax());

    put_eax(get_ecx());
    put_eax(get_eax() << 2);
    put_eax(get_eax() - get_ecx());
    put_ecx(get_eax());
    put_al(((unsigned char *)get_esi())[get_ecx()]);
    put_ah(0);
    put_eax(get_eax() - 1);
    ROUTE_STACK(long, 0x20) = get_eax();
    put_eax(get_ebx() * 22);
    put_esi(ROUTE_STACK(short, 0x20));
    put_esi(get_esi() << 3);
    put_edi((long)ROUTE_POINTS(get_eax()));
    put_edi(get_edi() + get_esi());
    put_eax(((long *)get_edi())[0]);
    put_eax(get_eax() - get_edx());
    put_edi(((long *)get_edi())[1]);
    absolute_long(get_eax());
    check_route_exit_distance();
    load_actor_y_in_ebp();
    put_eax(get_edi());
    absolute_long(get_eax() - get_ebp());
    check_route_exit_distance();
    continue_zone_route();
}

extern short route_sprite_sector[];
extern long route_sprite_z[], route_sector_floor_z[];
typedef struct {
    long waypoint, next;
} RouteCacheEntry;
extern RouteCacheEntry actor_route_cache[];
#define SPRITE_AT(type, field, offset) (*(type *)((char *)route_sprite_##field + (offset)))
#define FLOOR_AT(offset) (*(long *)((char *)route_sector_floor_z + (offset)))
extern short get_dx(void);
#pragma aux get_dx = "" value [dx] modify exact [];
extern void load_crossing_sprite(void);
#pragma aux load_crossing_sprite = "movsx ebp,word ptr [esp+28h]" modify exact [];
extern void changespritesect(int,int);
#pragma aux changespritesect parm [eax] [edx] modify exact [eax edx];
extern void load_zone_crossing_indices(void);
#pragma aux load_zone_crossing_indices = "xor edx,edx" "mov dl,[eax+ecx+1]" "xor ebx,ebx" "dec edx" "mov bl,[eax+ecx+2]" modify exact [ebx edx];
extern void read_crossing_x(void);
#pragma aux read_crossing_x = "mov esi,[edi+ebx*8]" modify exact [esi];
extern void read_crossing_sector(void);
#pragma aux read_crossing_sector = "mov ax,[eax+edx*2]" modify exact [eax];
extern void finish_zone_crossing(void);
#pragma aux finish_zone_crossing = "db 0ebh, 65h" aborts modify exact [];
void route_cross_zone(long frame_slot);
#pragma aux route_cross_zone parm routine [] aborts modify exact [eax ebx ecx edx esi edi];
void route_cross_zone(long frame_slot)
{
    put_edx(route_last_zone);
    put_edx(get_edx() + 1);
    put_edx(get_edx() * get_ebx());
    put_eax(get_edx());
    put_eax(get_eax() << 2);
    put_eax(get_eax() - get_edx());
    put_edx(get_eax());
    put_eax((long)route_zone_routes);
    put_eax(get_eax() + get_edx());

    load_zone_crossing_indices();
    put_eax(get_dx());
    put_eax(get_eax() * 22);
    put_ebx(get_ebx() - 1);
    put_edx(get_bx());
    put_ebx(get_edx());
    put_edi((long)ROUTE_POINTS(get_eax()));
    load_crossing_sprite();
    read_crossing_x();
    put_edi(((long *)get_edi())[get_ebx()*2 + 1]);
    put_ebx(get_ebp() * 44);
    put_eax((long)*(short **)(route_sector_lists + get_eax()));
    read_crossing_sector();
    put_edx(SPRITE_AT(short, sector, get_ebx()));
    ROUTE_STACK(long, 0x24) = get_eax();

    /* Keep the sprite at the same height relative to the new sector floor. */
    put_eax(get_edx());
    put_eax(get_eax() << 2);
    put_eax(get_eax() + get_edx());
    put_eax(get_eax() << 3);
    put_edx(ROUTE_STACK(short, 0x24));
    ROUTE_STACK(long, 0x10) = get_eax();
    put_eax(get_edx());
    put_eax(get_eax() << 2);
    put_eax(get_eax() + get_edx());
    put_eax(route_sector_floor_z[get_eax()*2]);
    ROUTE_STACK(long, 0x18) = get_eax();
    put_eax(ROUTE_STACK(long, 0x10));
    put_ecx(ROUTE_STACK(long, 0x18));
    put_eax(FLOOR_AT(get_eax()));
    put_ecx(get_ecx() - get_eax());
    put_eax(get_ecx());
    put_ecx(SPRITE_AT(long, z, get_ebx()));
    put_ecx(get_ecx() + get_eax());
    put_eax(get_ebp());
    SPRITE_AT(long, z, get_ebx()) = get_ecx();
    changespritesect(get_eax(), get_edx());
    put_eax(ROUTE_STACK(short, 0xc));
    SPRITE_AT(long, x, get_ebx()) = get_esi();
    put_esi(-1);
    SPRITE_AT(long, y, get_ebx()) = get_edi();
    actor_route_cache[get_eax()].waypoint = get_esi();
    finish_zone_crossing();
}

extern unsigned char route_floor_offsets[], route_ceiling_offsets[], route_widths[], route_next_hops[];
#define ROUTE_VALUE(type, column, offset) (*(type *)(route_##column + (offset)))
/* The path selector removes the nine arguments staged by either entry. */
extern void push_path_argument(long);
#pragma aux push_path_argument = "" parm routine [] modify exact [];
extern void load_route_ceiling_offset(void);
#pragma aux load_route_ceiling_offset = "mov ebp,dword ptr [eax+route_ceiling_offsets]" modify exact [];
extern void select_sprite_path_target(void);
#pragma aux select_sprite_path_target modify exact [eax ebx ecx edx esi edi];
extern void restore_path_frame(void);
#pragma aux restore_path_frame = "add esp,3ch" "pop ebp" "pop edi" "pop esi" "ret" aborts modify exact [];
void route_move_to_zone_exit(long frame_slot);
#pragma aux route_move_to_zone_exit parm routine [] aborts modify exact [eax ebx ecx edx esi edi];
void route_move_to_zone_exit(long frame_slot)
{
    put_eax(ROUTE_STACK(short, 0xc));
    put_eax(get_eax() << 3);
    put_eax(get_eax() + (long)actor_route_cache);
    push_path_argument(get_eax());
    put_eax(0);
    put_al(ROUTE_STACK(unsigned char, 0x3c));
    push_path_argument(get_eax());
    put_eax(ROUTE_STACK(short, 0x34));
    put_eax(get_eax() * 22);
    put_edx(ROUTE_VALUE(long, floor_offsets, get_eax()));
    push_path_argument(get_edx());
    put_ebx(ROUTE_VALUE(long, ceiling_offsets, get_eax()));
    push_path_argument(get_ebx());
    put_edx(ROUTE_VALUE(short, widths, get_eax()));
    put_ecx(ROUTE_VALUE(long, next_hops, get_eax()));
    push_path_argument(get_edx());
    put_esi(ROUTE_VALUE(long, sector_lists, get_eax()));
    put_edi(ROUTE_VALUE(long, records, get_eax()));
    push_path_argument(get_ecx());
    put_eax(ROUTE_STACK(short, 0x38));
    push_path_argument(get_esi());
    put_ebx(ROUTE_STACK(long, 0x20));
    put_edx(ROUTE_STACK(long, 0x24));
    push_path_argument(get_edi());
    put_ecx(ROUTE_STACK(short, 0x20));
    push_path_argument(get_eax());
    put_eax(ROUTE_STACK(short, 0x4c));
    continue_zone_route();
}

extern void route_select_target_tail(void);
extern void branch_for_different_zone(void);
#pragma aux branch_for_different_zone = "cmp ax,[esp+34h]" "db 75h,61h" modify exact [];
extern void enter_route_target_tail(void);
#pragma aux enter_route_target_tail = "jmp near route_select_target_tail" aborts modify exact [];
void route_choose_actor_target(long frame_slot);
#pragma aux route_choose_actor_target parm routine [] aborts modify exact [eax ebx ecx edx esi edi];
void route_choose_actor_target(long frame_slot)
{
    put_eax(ROUTE_STACK(long, 0x2c));
    branch_for_different_zone();
    put_eax(ROUTE_STACK(short, 0xc));
    put_eax(get_eax() << 3);
    put_eax(get_eax() + (long)actor_route_cache);
    push_path_argument(get_eax());
    put_eax(0);
    put_al(ROUTE_STACK(unsigned char, 0x3c));
    push_path_argument(get_eax());
    put_eax(ROUTE_STACK(short, 0x34));
    put_eax(get_eax() * 22);
    put_edi(ROUTE_VALUE(long, floor_offsets, get_eax()));
    push_path_argument(get_edi());
    load_route_ceiling_offset();
    push_path_argument(get_ebp());
    put_edx(ROUTE_VALUE(short, widths, get_eax()));
    push_path_argument(get_edx());
    put_edx(ROUTE_VALUE(long, next_hops, get_eax()));
    push_path_argument(get_edx());
    put_ebx(ROUTE_VALUE(long, sector_lists, get_eax()));
    put_ecx(ROUTE_VALUE(long, records, get_eax()));
    push_path_argument(get_ebx());
    put_eax(ROUTE_STACK(short, 0x44));
    push_path_argument(get_ecx());
    put_edx(ROUTE_STACK(long, 0x28));
    put_ebx(ROUTE_STACK(long, 0x24));
    push_path_argument(-1);
    put_ecx(ROUTE_STACK(short, 0x24));
    enter_route_target_tail();
}

void route_select_target_tail(void);
#pragma aux route_select_target_tail aborts modify exact [eax ebx ecx edx esi edi];
void route_select_target_tail(void)
{
    select_sprite_path_target();
    restore_path_frame();
}
