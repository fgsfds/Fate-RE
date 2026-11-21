/* The original CODE table enters each call at its historical byte offset.
 * Every case shares the routing function's frame and resumes sector resolution.
 */
typedef struct RouteRecord RouteRecord;
extern short route_last_zone;
extern unsigned char *route_zone_routes, *route_zone_bounds;
extern unsigned char route_records[];
extern void resolve_route_sectors(long frame_slot);
extern void resume_route_resolution(void);
#pragma aux resume_route_resolution = "jmp near resolve_route_sectors" modify exact [eax ebx ecx edx];
extern void resume_route_21(void);
#pragma aux resume_route_21 = "db 0ebh, 6ah" modify exact [eax ebx ecx edx];
extern void resume_route_22(void);
#pragma aux resume_route_22 = "db 0ebh, 4fh" modify exact [eax ebx ecx edx];
extern void resume_route_23(void);
#pragma aux resume_route_23 = "db 0ebh, 34h" modify exact [eax ebx ecx edx];
extern void resume_route_24(void);
#pragma aux resume_route_24 = "db 0ebh, 19h" modify exact [eax ebx ecx edx];
extern void continue_to_route_resolution(void);
#pragma aux continue_to_route_resolution = "" aborts modify exact [];
extern void initialize_sprite_path_board_25(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_25 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_24(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_24 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_23(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_23 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_22(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_22 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_21(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_21 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_20(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_20 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_19(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_19 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_18(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_18 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_17(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_17 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_16(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_16 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_15(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_15 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_14(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_14 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_13(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_13 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_12(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_12 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_11(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_11 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_10(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_10 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_09(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_09 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_08(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_08 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_07(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_07 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_06(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_06 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_05(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_05 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_04(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_04 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_03(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_03 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_02(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_02 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void initialize_sprite_path_board_01(short *, unsigned char **, unsigned char **, RouteRecord *);
#pragma aux initialize_sprite_path_board_01 parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];

#define INITIALIZE_BOARD(board) initialize_sprite_path_board##board(&route_last_zone, &route_zone_routes, &route_zone_bounds, (RouteRecord *)route_records)

void initialize_board_routes(void);
#pragma aux initialize_board_routes aborts modify exact [eax ebx ecx edx];

void initialize_board_routes(void)
{
    INITIALIZE_BOARD(_25);
    resume_route_resolution();
    INITIALIZE_BOARD(_24);
    resume_route_resolution();
    INITIALIZE_BOARD(_23);
    resume_route_resolution();
    INITIALIZE_BOARD(_22);
    resume_route_resolution();
    INITIALIZE_BOARD(_21);
    resume_route_resolution();
    INITIALIZE_BOARD(_20);
    resume_route_resolution();
    INITIALIZE_BOARD(_19);
    resume_route_resolution();
    INITIALIZE_BOARD(_18);
    resume_route_resolution();
    INITIALIZE_BOARD(_17);
    resume_route_resolution();
    INITIALIZE_BOARD(_16);
    resume_route_resolution();
    INITIALIZE_BOARD(_15);
    resume_route_resolution();
    INITIALIZE_BOARD(_14);
    resume_route_resolution();
    INITIALIZE_BOARD(_13);
    resume_route_resolution();
    INITIALIZE_BOARD(_12);
    resume_route_resolution();
    INITIALIZE_BOARD(_11);
    resume_route_resolution();
    INITIALIZE_BOARD(_10);
    resume_route_resolution();
    INITIALIZE_BOARD(_09);
    resume_route_resolution();
    INITIALIZE_BOARD(_08);
    resume_route_resolution();
    INITIALIZE_BOARD(_07);
    resume_route_resolution();
    INITIALIZE_BOARD(_06);
    resume_route_resolution();
    INITIALIZE_BOARD(_05);
    resume_route_21();
    INITIALIZE_BOARD(_04);
    resume_route_22();
    INITIALIZE_BOARD(_03);
    resume_route_23();
    INITIALIZE_BOARD(_02);
    resume_route_24();
    INITIALIZE_BOARD(_01);
    continue_to_route_resolution();
}

extern signed char route_current_board;
extern short route_loaded_board;
extern unsigned long route_navigation_dispatch[];

typedef struct {
    long waypoint;
    long next;
} RouteCacheEntry;
extern RouteCacheEntry actor_route_cache[];
extern void route_find_actor_sprite(long frame_slot);

/* Both caller paths share this frame with the assembly sector resolver. */
extern void set_up_route_frame(void);
#pragma aux set_up_route_frame = "push esi" "push edi" "push ebp" "sub esp,2ch" "push eax" "push edx" "push ebx" "push ecx" modify exact [eax ebx ecx edx esi edi];

extern short set_route_ax(short);
#pragma aux set_route_ax = "" parm [ax] value [ax] modify exact [];
extern short get_route_ax(void);
#pragma aux get_route_ax = "" value [ax] modify exact [];
extern long set_route_eax(long);
#pragma aux set_route_eax = "" parm [eax] value [eax] modify exact [];
extern long get_route_eax(void);
#pragma aux get_route_eax = "" value [eax] modify exact [];
extern int set_route_ecx(int);
#pragma aux set_route_ecx = "" parm [ecx] value [ecx] modify exact [];
extern int get_route_ecx(void);
#pragma aux get_route_ecx = "" value [ecx] modify exact [];
extern short get_route_cx(void);
#pragma aux get_route_cx = "" value [cx] modify exact [];
extern int set_route_edx(int);
#pragma aux set_route_edx = "" parm [edx] value [edx] modify exact [];
extern int get_route_edx(void);
#pragma aux get_route_edx = "" value [edx] modify exact [];
extern unsigned char set_route_al(unsigned char);
#pragma aux set_route_al = "" parm [al] value [al] modify exact [];
extern unsigned char get_route_al(void);
#pragma aux get_route_al = "" value [al] modify exact [];
/* These are machine-label transfers into an existing shared stack frame,
   not C calls to the resolver's stack-parameter entry points. */
extern void skip_routes_for_loaded_board(void);
#pragma aux skip_routes_for_loaded_board = "cmp ax,[route_loaded_board]" "je near route_find_actor_sprite" modify exact [edx];
extern unsigned long checked_route_board(unsigned char);
#pragma aux checked_route_board = "cmp al,18h" "ja near resolve_route_sectors" parm [al] value [eax] modify exact [eax];
extern void dispatch_route_initializer(void);
#pragma aux dispatch_route_initializer = "jmp dword cs:[eax*4+route_navigation_dispatch]" aborts modify exact [eax];

void route_actor_toward_target(void);
#pragma aux route_actor_toward_target aborts modify exact [eax ebx ecx edx esi edi];

void route_actor_toward_target(void)
{
    set_up_route_frame();
    set_route_ax(route_current_board);
    skip_routes_for_loaded_board();
    set_route_edx(-1);
    /* Invalidate the cached waypoint in each actor slot when the board changes. */
    *(volatile short *)&route_loaded_board = get_route_ax();
    set_route_ecx(0);
    goto check_cache;
clear_entry:
    set_route_ecx(get_route_ecx() + 1);
    actor_route_cache[get_route_eax()].waypoint = get_route_edx();
check_cache:
    if (set_route_eax(get_route_cx()) < 500)
        goto clear_entry;
    set_route_al(route_current_board);
    set_route_al(get_route_al() - 1);
    set_route_eax(checked_route_board(get_route_al()) & 0xff);
    dispatch_route_initializer();
}
