/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

extern unsigned char sector[], wall[];
extern short clipsectorlist[], clipsectnum, sintable[];

extern int clipinsidebox(void);
#pragma aux clipinsidebox value [eax] modify exact [eax ebx ecx edx];
extern long getflorzofslope(void);
#pragma aux getflorzofslope value [eax] modify exact [eax ebx edx];
extern long getceilzofslope(void);
#pragma aux getceilzofslope value [eax] modify exact [eax ebx edx];
extern long getangle(void);
#pragma aux getangle value [eax] modify exact [eax ebx ecx edx];
extern void updatesector(void);
#pragma aux updatesector modify exact [eax ebx ecx edx];
extern int finish_wall_push(int status);
#pragma aux finish_wall_push aborts parm [eax] modify exact [eax];
extern void pushmove_test_wall(void);
#pragma aux pushmove_test_wall aborts modify exact [];
extern void pushmove_closest_wall(void);
#pragma aux pushmove_closest_wall aborts modify exact [];
extern void begin_wall_push(long *x, long *y, long *z, short *sect);
#pragma aux begin_wall_push = "push esi" "push edi" "push ebp" "sub esp,40h" "mov esi,eax" \
    "mov edi,edx" "mov [esp+0ch],ebx" "mov [esp+8],ecx" parm [eax] [edx] [ebx] [ecx] modify exact [esi edi];
extern short *active_push_sector(void);
#pragma aux active_push_sector = value [ecx] modify exact [];
extern long push_scan_direction(void);
#pragma aux push_scan_direction = value [ebp] modify exact [];
extern long wall_push_dot(void);
#pragma aux wall_push_dot = value [eax] modify exact [];
extern long wall_push_blocked(void);
#pragma aux wall_push_blocked = value [ecx] modify exact [];
extern void block_wall_push(long value);
#pragma aux block_wall_push = "" parm [ecx] modify exact [];
extern long active_push_height(void);
#pragma aux active_push_height = value [eax] modify exact [];
extern long compare_push_height(void);
#pragma aux compare_push_height = value [edx] modify exact [];
extern long *push_z(void);
#pragma aux push_z = value [edx] modify exact [];
extern long queued_push_index(void);
#pragma aux queued_push_index = value [ecx] modify exact [];
extern short queued_push_sector_count(void);
#pragma aux queued_push_sector_count = value [dx] modify exact [];
extern long failed_push_value(void);
#pragma aux failed_push_value = value [ebx] modify exact [];
extern long push_complete_value(void);
#pragma aux push_complete_value = value [ecx] modify exact [];
#pragma aux pushmove modify exact [eax ebx ecx edx esi edi];

extern void initialize_wall_push(void);
#pragma aux initialize_wall_push = "mov edx, 20h" "mov ebx, 1h" "mov [esp + 18h], edx" "mov [esp + 10h], ebx" modify exact [edx ebx];
extern void seed_push_queue(void);
#pragma aux seed_push_queue = "mov eax, [esp + 8h]" "xor ecx, ecx" "xor ebx, ebx" "mov [esp + 4h], ecx" \
    "mov [esp + 34h], ebx" "mov ax, [eax]" "mov ecx, 1h" "mov [clipsectorlist], ax" \
    "mov [clipsectnum], cx" modify exact [eax ebx ecx];
extern void prepare_pushed_sector(void);
#pragma aux prepare_pushed_sector = "movsx eax, word ptr [esp + 34h]" "movsx edx, word ptr [eax*2 + clipsectorlist]" "mov eax, edx" "shl eax, 2h" \
    "add eax, edx" "shl eax, 3h" "mov ebp, [esp + 10h]" "add eax, offset sector" modify exact [eax edx];
extern void prepare_forward_walls(void);
#pragma aux prepare_forward_walls = "mov dx, [eax]" "mov ax, [eax + 2h]" "add eax, edx" "mov [esp + 38h], eax" modify exact [eax edx];
extern void prepare_reverse_walls(void);
#pragma aux prepare_reverse_walls = "mov dx, [eax]" "mov bx, [eax + 2h]" "mov [esp + 38h], edx" "add edx, ebx" modify exact [edx ebx];
extern void prepare_push_wall_pointer(void);
#pragma aux prepare_push_wall_pointer = "movsx eax, dx" "mov ebp, eax" "shl ebp, 5h" "mov [esp + 30h], eax" \
    "add ebp, offset wall"  "jmp pushmove_test_wall" modify exact [eax];
extern void prepare_push_box_query(void);
#pragma aux prepare_push_box_query = "mov ecx, [esp + 50h]" "movsx ebx, word ptr [esp + 30h]" "mov edx, [edi]" "mov eax, [esi]" \
    "sub ecx, 4h" modify exact [eax ebx ecx edx];
extern void test_push_wall_flags(void);
#pragma aux test_push_wall_flags = "mov bx, [ebp + 0ch]" "xor ecx, ecx" "test bx, bx" "jnl first_wall_flag" \
    "mov ecx, eax" "first_wall_flag:" "cmp byte ptr [esp + 5ch], 00h" "jnz second_wall_flag" \
    "mov ax, [ebp + 0eh]" "xor ah, ah" "and al, 1h" "cwde" \
    "test eax, eax" "jz second_wall_flag" "mov ecx, 1h" "second_wall_flag:" \
    "xor eax, eax" "mov al, [esp + 5ch]" "cmp eax, 1h" "jnz wall_flags_done" \
    "mov ax, [ebp + 0eh]" "xor ah, ah" "and al, 40h" "cwde" \
    "test eax, eax" "jz wall_flags_done" "mov ecx, 1h"  "wall_flags_done:" modify exact [eax ebx ecx];
extern void prepare_push_portal(void);
#pragma aux prepare_push_portal = "movsx edx, word ptr [ebp + 0ch]" "mov eax, edx" "shl eax, 2h" "add eax, edx" \
    "mov edx, offset sector" "shl eax, 3h" "add edx, eax" "movsx eax, word ptr [ebp + 8h]" \
    "mov ebx, [ebp + 00h]" "shl eax, 5h" "mov [esp + 14h], edx" "mov edx, dword ptr [eax + wall]" \
    "sub edx, ebx" "mov eax, dword ptr [eax + wall+4]" "mov [esp + 20h], edx" "mov edx, [ebp + 4h]" \
    "sub eax, edx" "mov [esp + 24h], eax" modify exact [eax ebx edx];

/* Register constraints for the nearest-wall projection and angle inputs. */
extern long proj_eax(void);
#pragma aux proj_eax = value [eax] modify exact [];
extern void proj_set_eax(long value);
#pragma aux proj_set_eax = "" parm [eax] modify exact [];
extern long proj_ebx(void);
#pragma aux proj_ebx = value [ebx] modify exact [];
extern void proj_set_ebx(long value);
#pragma aux proj_set_ebx = "" parm [ebx] modify exact [];
extern long proj_edx(void);
#pragma aux proj_edx = value [edx] modify exact [];
extern void proj_set_edx(long value);
#pragma aux proj_set_edx = "" parm [edx] modify exact [];
extern const long *push_point_x(void);
#pragma aux push_point_x = value [esi] modify exact [];
extern const long *push_point_y(void);
#pragma aux push_point_y = value [edi] modify exact [];
extern long load_wall_dx(void);
#pragma aux load_wall_dx = "mov ebx,[esp+20h]" value [ebx] modify exact [ebx];
extern long load_wall_dy(void);
#pragma aux load_wall_dy = "mov edx,[esp+24h]" value [edx] modify exact [edx];

extern void select_zero_push_fraction(void);
#pragma aux select_zero_push_fraction = "mov [esp + 1ch], ecx" modify exact [];
extern void select_full_push_fraction(void);
#pragma aux select_full_push_fraction = "mov dword ptr [esp + 1ch], 40000000h" modify exact [];
extern void select_fractional_wall_point(void);
#pragma aux select_fractional_wall_point = "mov edx, eax" "sar edx, 2h" "shl eax, 1eh" "idiv ebx" \
    "mov [esp + 1ch], eax" modify exact [eax edx];
extern void configure_near_floor_query(void);
#pragma aux configure_near_floor_query = "mov ebx, [esp + 1ch]" "mov eax, [esp + 20h]" "imul ebx" "shrd eax, edx, 1eh" \
    "mov edx, [ebp + 00h]" "add edx, eax" "mov eax, [esp + 24h]" "mov [esp + 20h], edx" \
    "imul ebx" "shrd eax, edx, 1eh" "mov edx, [ebp + 4h]" "add edx, eax" \
    "movsx eax, word ptr [esp + 34h]" "mov [esp + 24h], edx" "mov ebx, edx" "mov edx, [esp + 20h]" \
    "movsx eax, word ptr [eax*2 + clipsectorlist]" modify exact [eax ebx edx];
extern void configure_far_floor_query(void);
#pragma aux configure_far_floor_query = "mov ebx, [esp + 24h]" "mov edx, [esp + 20h]" "mov [esp], eax" "movsx eax, word ptr [ebp + 0ch]" modify exact [eax ebx edx];
extern long load_floor_threshold(void);
#pragma aux load_floor_threshold = "mov edx,[esp]" "sub edx,100h" value [edx] modify exact [edx];
extern long push_floor_is_parallax(void);
#pragma aux push_floor_is_parallax = "mov edx, [esp + 14h]" "mov dx, [edx + 0eh]" "xor dh, dh" "and dl, 1h" \
    "movsx edx, dx" value [edx] modify exact [edx];
extern void prepare_push_floor_clearance(void);
#pragma aux prepare_push_floor_clearance = "mov edx, [esp + 58h]" "dec edx" "sub eax, edx" "mov edx, [esp + 0ch]" modify exact [eax edx];
extern void configure_near_ceiling_query(void);
#pragma aux configure_near_ceiling_query = "movsx eax, word ptr [esp + 34h]" "mov ebx, [esp + 24h]" "mov edx, [esp + 20h]" "movsx eax, word ptr [eax*2 + clipsectorlist]" modify exact [eax ebx edx];
extern void configure_far_ceiling_query(void);
#pragma aux configure_far_ceiling_query = "mov ebx, [esp + 24h]" "mov edx, [esp + 20h]" "mov [esp], eax" "movsx eax, word ptr [ebp + 0ch]" modify exact [eax ebx edx];
extern long load_ceiling_threshold(void);
#pragma aux load_ceiling_threshold = "mov edx,[esp]" "add edx,100h" value [edx] modify exact [edx];
extern long push_ceiling_is_parallax(void);
#pragma aux push_ceiling_is_parallax = "mov edx, [esp + 14h]" "mov dx, [edx + 0ch]" "xor dh, dh" "and dl, 1h" \
    "movsx edx, dx" value [edx] modify exact [edx];
extern void prepare_push_ceiling_clearance(void);
#pragma aux prepare_push_ceiling_clearance = "mov edx, [esp + 54h]" "dec edx" "add eax, edx" "mov edx, [esp + 0ch]" modify exact [eax edx];
extern const unsigned char *push_angle_wall(void);
#pragma aux push_angle_wall = value [ebp] modify exact [];
extern long push_angle_y(void);
#pragma aux push_angle_y = value [ecx] modify exact [];
extern void record_push_angle_y(long y);
#pragma aux record_push_angle_y = "" parm [ecx] modify exact [];

/* Keep the two sine lookups in the original register order. */
extern void nudge_x_in_edx(long x);
#pragma aux nudge_x_in_edx = "" parm [edx] modify exact [];
extern void nudge_y_in_eax(long y);
#pragma aux nudge_y_in_eax = "" parm [eax] modify exact [];
extern long nudge_x_value(void);
#pragma aux nudge_x_value = value [edx] modify exact [];
extern long nudge_y_value(void);
#pragma aux nudge_y_value = value [eax] modify exact [];
extern void save_nudge_x(void);
#pragma aux save_nudge_x = "mov [esp + 28h], edx" modify exact [];
extern void save_nudge_y(void);
#pragma aux save_nudge_y = "mov dl, 10h" "mov [esp + 2ch], eax" "mov [esp + 3ch], dl" modify exact [edx];
/* Advance away from this wall at most sixteen times. */
extern void nudge_until_clear(void);
#pragma aux nudge_until_clear = "nudge_again:" "mov eax, [esp + 28h]" "add [esi], eax" "mov eax, [esp + 2ch]" "add [edi], eax" \
    "mov dh, [esp + 3ch]" "dec dh" "mov [esp + 3ch], dh" "jz done_nudging" \
    "mov ecx, [esp + 50h]" "movsx ebx, word ptr [esp + 30h]" "mov edx, [edi]" "mov eax, [esi]" \
    "sub ecx, 4h" "call clipinsidebox" "test eax, eax" "jnz nudge_again"  "done_nudging:" modify exact [eax ebx ecx edx];
extern long step_push_retry_count(void);
#pragma aux step_push_retry_count = "mov ecx, [esp + 18h]" "mov ebx, 0ffffffffh" "dec ecx" "mov [esp + 4h], ebx" \
    "mov [esp + 18h], ecx" value [ecx] modify exact [ebx ecx];
extern void prepare_push_sector_update(void);
#pragma aux prepare_push_sector_update = "mov ebx, [esp + 8h]" "mov edx, [edi]" "mov eax, [esi]" modify exact [eax ebx edx];
extern void begin_push_neighbor_scan(void);
#pragma aux begin_push_neighbor_scan = "movsx ecx, word ptr [clipsectnum]" modify exact [ecx];
extern short push_neighbor_sector(void);
#pragma aux push_neighbor_sector = "mov dx, [ebp + 0ch]" value [dx] modify exact [edx];
extern long decrement_push_neighbor(void);
#pragma aux decrement_push_neighbor = "dec ecx" value [ecx] modify exact [ecx];
extern void append_push_neighbor(void);
#pragma aux append_push_neighbor = "mov ax, [clipsectnum]" "movsx edx, ax" "inc eax" "mov [clipsectnum], ax" \
    "mov ax, [ebp + 0ch]" "mov [edx*2 + clipsectorlist], ax" modify exact [eax edx];
extern void advance_push_wall(void);
#pragma aux advance_push_wall = "mov eax, [esp + 10h]" "mov edx, [esp + 30h]" "add edx, eax" "shl eax, 5h" \
    "mov [esp + 30h], edx" "add ebp, eax" modify exact [eax edx];
extern void check_push_wall_cursor(void);
#pragma aux check_push_wall_cursor = "movsx eax,word ptr [esp+38h]" "cmp eax,[esp+30h]" "jne pushmove_closest_wall" modify exact [eax];
extern short advance_push_sector(void);
#pragma aux advance_push_sector = "mov ecx, [esp + 34h]" "inc ecx" "mov dx, [clipsectnum]" "mov [esp + 34h], ecx" value [cx] modify exact [ecx edx];
extern long finish_push_pass(void);
#pragma aux finish_push_pass = "mov ebx, [esp + 10h]" "neg ebx" "mov ecx, [esp + 4h]" "mov [esp + 10h], ebx" value [ecx] modify exact [ebx ecx];
extern void drop_push_frame(void);
#pragma aux drop_push_frame = "add esp,40h" modify exact [];

int pushmove(long *x, long *y, long *z, short *sect,
             long radius, long ceiling_clearance, long floor_clearance, int clip_type)
{
    int result;
    long dot, floor_threshold, ceiling_threshold, angle;

    begin_wall_push(x, y, z, sect);
    if (*active_push_sector() < 0) {
        result = -1;
        goto done;
    }
    /* Use a bounded retry budget and alternate the wall scan direction. */
    initialize_wall_push();

retry:
    seed_push_queue();
sector_scan:
    prepare_pushed_sector();
    if (push_scan_direction() > 0)
        prepare_forward_walls();
    else
        prepare_reverse_walls();
    prepare_push_wall_pointer();

    prepare_push_box_query();
    if (clipinsidebox() != 1)
        goto next_wall;
    test_push_wall_flags();
    if (wall_push_blocked())
        goto check_blocking;
    prepare_push_portal();
    /* Dot product of the wall vector and the offset from its start. */
    proj_set_eax(*push_point_y());
    proj_set_eax((unsigned long)proj_eax() - (unsigned long)proj_edx());
    proj_set_edx((unsigned long)load_wall_dy() * (unsigned long)proj_eax());
    proj_set_eax(*push_point_x());
    proj_set_eax((unsigned long)proj_eax() - (unsigned long)proj_ebx());
    proj_set_eax((unsigned long)proj_eax() * (unsigned long)load_wall_dx());
    proj_set_eax((unsigned long)proj_eax() + (unsigned long)proj_edx());
    /* Clamp the nearest point to one of the endpoints or the wall segment. */
    dot = wall_push_dot();
    if (dot <= 0)
        select_zero_push_fraction();
    else {
        proj_set_ebx((unsigned long)proj_ebx() * (unsigned long)proj_ebx());
        proj_set_edx(load_wall_dy());
        proj_set_edx((unsigned long)proj_edx() * (unsigned long)proj_edx());
        proj_set_ebx((unsigned long)proj_ebx() + (unsigned long)proj_edx());
        if (wall_push_dot() >= proj_ebx())
            select_full_push_fraction();
        else
            select_fractional_wall_point();
    }

    /* A nonparallax portal step can block the requested vertical clearance. */
    configure_near_floor_query();
    getflorzofslope();
    configure_far_floor_query();
    getflorzofslope();
    floor_threshold = load_floor_threshold();
    if (active_push_height() < floor_threshold && !push_floor_is_parallax()) {
        prepare_push_floor_clearance();
        if (active_push_height() <= *push_z())
            block_wall_push(1);
    }
    configure_near_ceiling_query();
    getceilzofslope();
    configure_far_ceiling_query();
    getceilzofslope();
    ceiling_threshold = load_ceiling_threshold();
    if (active_push_height() > ceiling_threshold && !push_ceiling_is_parallax()) {
        prepare_push_ceiling_clearance();
        if (active_push_height() >= *push_z())
            block_wall_push(1);
    }

check_blocking:
    if (!wall_push_blocked())
        goto neighbor_scan;
    /* The point2 wall supplies the opposite endpoint for the wall angle. */
    proj_set_eax(*(const short *)(push_angle_wall() + 8));
    record_push_angle_y(*(const long *)(push_angle_wall() + 4));
    proj_set_eax((unsigned long)proj_eax() << 5);
    proj_set_ebx(*(const long *)push_angle_wall());
    proj_set_edx(*(const long *)(wall + proj_eax() + 4));
    proj_set_eax(*(const long *)(wall + proj_eax()));
    proj_set_edx((unsigned long)proj_edx() - (unsigned long)push_angle_y());
    proj_set_eax((unsigned long)proj_eax() - (unsigned long)proj_ebx());
    angle = getangle();
    nudge_x_in_edx((angle + 1024) & 2047);
    nudge_y_in_eax(angle + 512);
    nudge_x_in_edx(sintable[nudge_x_value()]);
    nudge_y_in_eax(nudge_y_value() & 2047);
    nudge_x_in_edx(nudge_x_value() >> 11);
    nudge_y_in_eax(sintable[nudge_y_value()]);
    save_nudge_x();
    nudge_y_in_eax(nudge_y_value() >> 11);
    save_nudge_y();
    nudge_until_clear();
    if (step_push_retry_count() <= 0) {
        result = failed_push_value();
        goto done;
    }
    prepare_push_sector_update();
    updatesector();
    goto next_wall;

neighbor_scan:
    begin_push_neighbor_scan();
    goto check_neighbor;
    do {
        if (push_neighbor_sector() == clipsectorlist[queued_push_index()])
            goto seen;
check_neighbor:;
    } while (decrement_push_neighbor() >= 0);
seen:
    if (queued_push_index() < 0)
        append_push_neighbor();

next_wall:
    advance_push_wall();
    check_push_wall_cursor();
    if (advance_push_sector() < queued_push_sector_count())
        goto sector_scan;
    if (finish_push_pass())
        goto retry;
    result = push_complete_value();
done:
    drop_push_frame();
    return finish_wall_push(result);
}
