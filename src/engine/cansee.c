/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

extern short visibility_queue[];
extern unsigned char sector[], wall[];

extern void visibility_cleanup(void);
#pragma aux visibility_cleanup aborts modify exact [];
extern void visibility_blocked(void);
#pragma aux visibility_blocked aborts modify exact [];
extern void visibility_wall_test(void);
#pragma aux visibility_wall_test aborts modify exact [];
extern void visibility_wall_start(void);
#pragma aux visibility_wall_start aborts modify exact [];
extern int finish_visibility(int visible);
#pragma aux finish_visibility aborts parm [eax] modify exact [eax];
extern int lintersect(void);
#pragma aux lintersect value [eax] modify exact [eax ebx ecx edx];
extern void getzsofslope(void);
#pragma aux getzsofslope modify exact [eax ebx ecx edx];

extern void begin_visibility(long x, long y, long z, short initial_sector);
#pragma aux begin_visibility = "push esi" "push edi" "push ebp" "sub esp,32" \
    "push eax" "push edx" "push ebx" parm [eax] [edx] [ebx] [cx] modify exact [];
extern short visibility_source_sector(void);
#pragma aux visibility_source_sector = value [cx] modify exact [];
extern long visibility_sector_index(void);
#pragma aux visibility_sector_index = value [esi] modify exact [];
extern void stage_visibility_sector(long sector_index);
#pragma aux stage_visibility_sector = "mov [esp+36],eax" parm [eax] modify exact [];
/* Shared cleanup returns the sector comparison for a zero-length sight line. */
extern void check_identical_visibility_xy(void);
#pragma aux check_identical_visibility_xy = "cmp eax,[esp+60]" "jne seed_queue" "mov eax,[esp+4]" "cmp eax,[esp+64]" \
    "jne seed_queue" "cmp cx,[esp+72]" "sete al" "and eax,255" \
    "jmp visibility_cleanup" "seed_queue:"  modify exact [eax];
extern void start_visibility_queue(void);
#pragma aux start_visibility_queue = "xor ecx,ecx" "mov ebp,1" "mov [esp+32],ecx"  modify exact [ecx];
extern void load_visibility_walls(void);
#pragma aux load_visibility_walls = "mov edx,eax" "shl eax,2" "add eax,edx" "shl eax,3" \
    "add eax,offset sector" "movsx esi,word ptr [eax]" "movsx edx,word ptr [eax+2]" "shl esi,5" \
    "mov [esp+40],edx" "add esi,offset wall" "jmp visibility_wall_test"  modify exact [eax edx esi];
/* Load the wall endpoints and the origin of the sight line. */
extern void keep_visibility_wall_offset(long offset);
#pragma aux keep_visibility_wall_offset = "" parm [eax] modify exact [];
extern long visibility_wall_offset(void);
#pragma aux visibility_wall_offset = value [eax] modify exact [];
extern void load_visibility_cross_origin_y(void);
#pragma aux load_visibility_cross_origin_y = "mov edx,[esp+4]" modify exact [edx];
extern void keep_visibility_wall_end(const unsigned char *ptr);
#pragma aux keep_visibility_wall_end = "" parm [eax] modify exact [];
extern void load_visibility_cross_origin_x(void);
#pragma aux load_visibility_cross_origin_x = "mov ebx,[esp+8]" modify exact [ebx];
typedef struct {
    long x, y;
    short point2;
} visibility_wall_point;

extern const visibility_wall_point *visibility_wall_begin(void);
#pragma aux visibility_wall_begin = value [esi] modify exact [];
extern const visibility_wall_point *visibility_wall_end(void);
#pragma aux visibility_wall_end = value [eax] modify exact [];
extern long visibility_cross_origin_x(void);
#pragma aux visibility_cross_origin_x = value [ebx] modify exact [];
extern long visibility_cross_origin_y(void);
#pragma aux visibility_cross_origin_y = value [edx] modify exact [];
extern long visibility_cross_dy(void);
#pragma aux visibility_cross_dy = value [ecx] modify exact [];
extern void set_visibility_cross_left(long product);
#pragma aux set_visibility_cross_left = "" parm [edi] modify exact [];
extern void set_visibility_cross_right(long product);
#pragma aux set_visibility_cross_right = "" parm [edx] modify exact [];
extern void set_visibility_cross_dy(long delta);
#pragma aux set_visibility_cross_dy = "" parm [ecx] modify exact [];
extern long left_visibility_cross(void);
#pragma aux left_visibility_cross = value [edi] modify exact [];
extern long right_visibility_cross(void);
#pragma aux right_visibility_cross = value [edx] modify exact [];
extern void push_visibility_intersection_outputs(void);
#pragma aux push_visibility_intersection_outputs = "lea edx,[esp+20]" "push edx" "lea edx,[esp+28]" "push edx" \
    "lea edx,[esp+36]" "push edx"  modify exact [edx];
extern void push_visibility_intersection_arguments(void);
#pragma aux push_visibility_intersection_arguments = "mov ecx,[eax+4]" "push ecx" "mov edi,[eax]" "push edi" \
    "mov eax,[esi+4]" "push eax" "mov edx,[esi]" "push edx" \
    "mov ebx,[esp+96]" "mov ecx,[esp+92]" "push ebx" "mov eax,[esp+40]" \
    "mov edx,[esp+36]" "push ecx" "mov ebx,[esp+36]" "mov ecx,[esp+96]"  modify exact [eax ebx ecx edx edi];
extern long read_visibility_portal(void);
#pragma aux read_visibility_portal = "movsx edi,word ptr [esi+12]" value [edi] modify exact [edi];
extern long visibility_portal_blocks(void);
#pragma aux visibility_portal_blocks = "mov ax,[esi+14]" "xor ah,ah" "and al,32" "cwde" value [eax] modify exact [eax];
extern void prepare_visibility_sector_heights(void);
#pragma aux prepare_visibility_sector_heights = "lea eax,[esp+12]" "lea ecx,[esp+16]" "mov ebx,[esp+24]" "mov edx,[esp+28]" \
    "push eax" "movsx eax,word ptr [esp+40]"  modify exact [eax ebx ecx edx];
/* The shared frame stores both height outputs and the intersection Z. */
extern void check_visible_z(void);
#pragma aux check_visible_z = "mov eax,[esp+20]" "cmp eax,[esp+16]" "jle visibility_blocked" "cmp eax,[esp+12]" \
    "jge visibility_blocked"  modify exact [eax];
extern void prepare_visibility_neighbor_heights(void);
#pragma aux prepare_visibility_neighbor_heights = "lea eax,[esp+12]" "lea ecx,[esp+16]" "mov ebx,[esp+24]" "mov edx,[esp+28]" \
    "push eax" "movsx eax,di"  modify exact [eax ebx ecx edx];
extern void find_last_queued_sector(void);
#pragma aux find_last_queued_sector = "lea eax,[ebp-1]" modify exact [eax];
extern long queued_portal_index(void);
#pragma aux queued_portal_index = value [eax] modify exact [];
extern long visibility_neighbor(void);
#pragma aux visibility_neighbor = value [edi] modify exact [];
extern long read_queued_portal(void);
#pragma aux read_queued_portal = "movsx edx,word ptr [eax*2+visibility_queue]" \
    value [edx] modify exact [edx];
extern void check_previous_sector(void);
#pragma aux check_previous_sector = "dec eax" modify exact [eax];
extern void increase_visibility_queue(void);
#pragma aux increase_visibility_queue = "inc ebp" modify exact [];
extern long visibility_queue_count(void);
#pragma aux visibility_queue_count = value [ebp] modify exact [];
extern void advance_visibility_wall(void);
#pragma aux advance_visibility_wall = "mov ebx,[esp+40]" "dec ebx" "add esi,32" "mov [esp+40],ebx"  modify exact [ebx esi];
/* Keep the original ESP-relative wall-loop condition. */
extern void check_visibility_wall(void);
#pragma aux check_visibility_wall = "cmp dword ptr [esp+40],0" "jg visibility_wall_start" "inc dword ptr [esp+32]"  modify exact [];
extern long load_visibility_queue_cursor(void);
#pragma aux load_visibility_queue_cursor = "mov esi,[esp+32]" value [esi] modify exact [esi];
extern void load_visibility_destination(void);
#pragma aux load_visibility_destination = "mov ebx,[esp+72]" "lea eax,[ebp-1]"  modify exact [eax ebx];
extern short destination_visibility_sector(void);
#pragma aux destination_visibility_sector = value [bx] modify exact [];
extern void drop_visibility_frame(void);
#pragma aux drop_visibility_frame = "add esp,44" modify exact [];
#pragma aux cansee modify exact [eax ebx ecx edx esi edi];

/* Calculate modulo 2^32, then compare the products as signed longs. */
#define CROSS_DELTA(a, b) ((long)((unsigned long)(a) - (unsigned long)(b)))
#define CROSS_PRODUCT(a, b) ((long)((unsigned long)(a) * (unsigned long)(b)))

int cansee(long x, long y, long z, short initial_sector,
           long target_x, long target_y, long target_z, short target_sector)
{
    int visible;
    long portal;

    begin_visibility(x, y, z, initial_sector);
    check_identical_visibility_xy();
    visibility_queue[0] = visibility_source_sector();
    start_visibility_queue();
    goto test_queue;
    do {
        stage_visibility_sector(visibility_queue[visibility_sector_index()]);
        load_visibility_walls();
        /* Compare the two products of the wall-side cross product relative to the origin. */
        keep_visibility_wall_offset((long)((unsigned long)visibility_wall_begin()->point2 << 5));
        load_visibility_cross_origin_y();
        keep_visibility_wall_end(wall + visibility_wall_offset());
        load_visibility_cross_origin_x();
        set_visibility_cross_left(visibility_wall_begin()->x);
        set_visibility_cross_dy(visibility_wall_end()->y);
        set_visibility_cross_left(CROSS_DELTA(left_visibility_cross(), visibility_cross_origin_x()));
        set_visibility_cross_dy(CROSS_DELTA(visibility_cross_dy(), visibility_cross_origin_y()));
        set_visibility_cross_left(CROSS_PRODUCT(left_visibility_cross(), visibility_cross_dy()));
        set_visibility_cross_dy(CROSS_DELTA(visibility_wall_begin()->y, visibility_cross_origin_y()));
        set_visibility_cross_right(CROSS_DELTA(visibility_wall_end()->x, visibility_cross_origin_x()));
        set_visibility_cross_right(CROSS_PRODUCT(right_visibility_cross(), visibility_cross_dy()));
        if (left_visibility_cross() < right_visibility_cross())
            goto next_wall;
        push_visibility_intersection_outputs();
        push_visibility_intersection_arguments();
        if (!lintersect())
            goto next_wall;
        if (read_visibility_portal() < 0 || visibility_portal_blocks())
            goto blocked;
        prepare_visibility_sector_heights();
        getzsofslope();
        check_visible_z();
        prepare_visibility_neighbor_heights();
        getzsofslope();
        check_visible_z();

        /* Enqueue the portal sector once. */
        find_last_queued_sector();
        goto test_seen;
        do {
            portal = read_queued_portal();
            if (portal == visibility_neighbor())
                goto seen;
            check_previous_sector();
test_seen:;
        } while (queued_portal_index() >= 0);
seen:
        if (queued_portal_index() >= 0)
            goto next_wall;
        increase_visibility_queue();
        visibility_queue[visibility_queue_count() - 1] = (short)visibility_neighbor();
next_wall:
        advance_visibility_wall();
        check_visibility_wall();
test_queue:;
    } while (visibility_queue_count() > load_visibility_queue_cursor());

    load_visibility_destination();
    goto test_destination;
    do {
        if (destination_visibility_sector() == visibility_queue[queued_portal_index()]) {
            visible = 1;
            goto done;
        }
        check_previous_sector();
test_destination:;
    } while (queued_portal_index() >= 0);
blocked:
    visible = 0;
done:
    drop_visibility_frame();
    return finish_visibility(visible);
}
