/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern int initial_sector_offset(void);
#pragma aux initial_sector_offset = value [edi] modify exact [];
extern int scale_first_wall_index(int index);
#pragma aux scale_first_wall_index = "shl eax,5" parm [eax] value [eax] modify exact [eax];
extern long prepare_neighbor_sector_offset(void);
#pragma aux prepare_neighbor_sector_offset = \
    "movsx edx,word ptr [eax+12]" "mov dword ptr [esp],edx" "mov ebp,dword ptr [esp]" \
    "shl edx,2" "add edx,ebp" "movsx ebp,word ptr [esp+4]" \
    value [edx] modify exact [edx];
extern long neighbor_height_in_edx(long height);
#pragma aux neighbor_height_in_edx = "" parm [edx] value [edx] modify exact [];
extern int sector_byte_offset_in_edi(short number);
#pragma aux sector_byte_offset_in_edi = "movsx edx,ax" "mov edi,edx" "shl edi,2" "add edi,edx" "shl edi,3" "mov ecx,-1" parm [ax] value [edi] modify exact [ecx edx edi];
extern int wall_start_in_eax(int index);
#pragma aux wall_start_in_eax = "" parm [eax] value [eax] modify exact [];
extern void seed_neighbor_reference_limit(void);
#pragma aux seed_neighbor_reference_limit = "add ebx,7fffffffh" modify exact [ebx];
extern long current_neighbor_height(void);
#pragma aux current_neighbor_height = value [edx] modify exact [];
extern void keep_floor_comparison(void);
#pragma aux keep_floor_comparison = "" modify exact [];
typedef struct { short wallptr, wallnum; long ceilingz, floorz; char rest[28]; } Sector;
typedef struct { char endpoints[12]; short nextsector; char rest[18]; } Wall;
extern Sector sector[];
extern Wall wall[];

/* Set up the 12-byte search frame used by the shared return. */
extern void begin_neighbor_height(long reference, long which, long direction);
#pragma aux begin_neighbor_height = \
    "push esi" "push edi" "push ebp" \
    "sub esp,12" "mov esi,edx" "mov dword ptr [esp+8],ebx" \
    "mov dword ptr [esp+4],ecx" "movsx edx,cx" "xor ebx,ebx" \
    "cmp edx,1" "setne dl" "mov bl,dl" \
    parm [edx] [ebx] [ecx] modify exact [ebx edx esi];
extern int choose_floor_neighbor(void);
#pragma aux choose_floor_neighbor = "movsx edx,word ptr [esp+8]" value [edx] modify exact [edx];
extern int height_search_direction(void);
#pragma aux height_search_direction = value [ebp] modify exact [];
extern long initial_neighbor_reference(void);
#pragma aux initial_neighbor_reference = value [esi] modify exact [];
extern long closest_neighbor_height(void);
#pragma aux closest_neighbor_height = value [ebx] modify exact [];
extern void record_neighbor_height(long height);
#pragma aux record_neighbor_height = "mov ebx,edx" "mov cx,word ptr [eax+12]" parm [edx] modify exact [ebx ecx];
extern Wall *neighbor_wall_in_eax(Wall *current);
#pragma aux neighbor_wall_in_eax = "" parm [eax] value [eax] modify exact [];
extern int neighbor_count_in_edi(int count);
#pragma aux neighbor_count_in_edi = "" parm [edi] value [edi] modify exact [];
extern int finish_neighbor_height(void);
#pragma aux finish_neighbor_height aborts modify exact [eax];
extern void set_neighbor_height_result(void);
#pragma aux set_neighbor_height_result = "movsx eax,cx" modify exact [eax];
#pragma aux nextsectorneighborz modify exact [eax ebx ecx edx esi edi];

int nextsectorneighborz(short sector_index, long reference, long which, long direction)
{
    Wall *current;
    int remaining;
    int wall_start;

    begin_neighbor_height(reference, which, direction);
    sector_byte_offset_in_edi(sector_index);
    wall_start = wall_start_in_eax(((const Sector *)((const char *)sector + initial_sector_offset()))->wallptr);
    seed_neighbor_reference_limit();
    wall_start = scale_first_wall_index(wall_start);
    remaining = neighbor_count_in_edi(((const Sector *)((const char *)sector + initial_sector_offset()))->wallnum);
    current = neighbor_wall_in_eax((Wall *)((char *)wall + wall_start));
    do {
        if (current->nextsector < 0)
            goto next_wall;
        if (choose_floor_neighbor() == 1) {
            neighbor_height_in_edx(((const Sector *)((const char *)sector + prepare_neighbor_sector_offset() * 8))->floorz);
            if (height_search_direction() != 1)
                goto below_floor;
above:
            if (current_neighbor_height() <= initial_neighbor_reference() || current_neighbor_height() >= closest_neighbor_height())
                goto next_wall;
            goto remember;
below_floor:
            if (current_neighbor_height() >= initial_neighbor_reference() || current_neighbor_height() <= closest_neighbor_height())
                goto next_wall;
            /* Preserve the original separate floor and ceiling branches. */
            keep_floor_comparison();
            goto remember;
        }
        neighbor_height_in_edx(((const Sector *)((const char *)sector + prepare_neighbor_sector_offset() * 8))->ceilingz);
        if (height_search_direction() == 1)
            goto above;
        if (current_neighbor_height() >= initial_neighbor_reference() || current_neighbor_height() <= closest_neighbor_height())
            goto next_wall;
remember:
        record_neighbor_height(current_neighbor_height());
next_wall:
        current = neighbor_wall_in_eax(current + 1);
    } while (--remaining);

    set_neighbor_height_result();
    return finish_neighbor_height();
}
