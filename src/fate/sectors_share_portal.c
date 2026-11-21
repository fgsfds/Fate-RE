typedef struct {
    unsigned char prefix[12];
    short next_sector;
    unsigned char rest[18];
} MapWall;
extern MapWall wall[];

extern int keep_first_count(int);
#pragma aux keep_first_count = parm [ecx] value [ecx] modify exact [];
extern int keep_portal_result(int);
#pragma aux keep_portal_result = parm [edx] value [edx] modify exact [];

extern const short sector_wall_counts[];
extern const short sector_wall_starts[];
/* Prepare offsets with C while preserving the original register lifetimes. */
extern void portal_keep_first(int);
#pragma aux portal_keep_first = "" parm [edi] modify exact [];
extern void portal_keep_second(int);
#pragma aux portal_keep_second = "" parm [esi] modify exact [];
extern short portal_ax(void);
#pragma aux portal_ax = "" value [ax] modify exact [];
extern int portal_eax(void);
#pragma aux portal_eax = "" value [eax] modify exact [];
extern int portal_edx(void);
#pragma aux portal_edx = "" value [edx] modify exact [];
extern int portal_ecx(void);
#pragma aux portal_ecx = "" value [ecx] modify exact [];
extern int portal_ebx(int);
#pragma aux portal_ebx = "" parm [ebx] value [ebx] modify exact [];
extern int portal_eax_set(int);
#pragma aux portal_eax_set = "" parm [eax] value [eax] modify exact [];
extern int first_sector_offset(void);
#pragma aux first_sector_offset = value [ebx] modify exact [];
extern int second_sector_offset_before_scale(void);
#pragma aux second_sector_offset_before_scale = value [edx] modify exact [];
extern int keep_second_sector_offset(int);
#pragma aux keep_second_sector_offset = parm [edx] value [edx] modify exact [];
extern short first_sector_id(void);
#pragma aux first_sector_id = value [di] modify exact [];
extern short second_sector_id(void);
#pragma aux second_sector_id = value [si] modify exact [];
extern short keep_count_in_ax(short);
#pragma aux keep_count_in_ax = parm [ax] value [ax] modify exact [];
extern short portal_bx(short);
#pragma aux portal_bx = "" parm [bx] value [bx] modify exact [];
extern int keep_offset(int);
#pragma aux keep_offset = parm [edx] value [edx] modify exact [];


/* Retain the starting wall in ECX as the descending index changes in AX. */
extern int read_portal_wall_base(void);
#pragma aux read_portal_wall_base = value [ecx] modify exact [];
extern short read_portal_wall_cursor(void);
#pragma aux read_portal_wall_cursor = value [ax] modify exact [];
int sectors_share_portal(int first, int second)
{
    volatile int first_count_storage;
    short first_count, second_count, offset;
    int first_offset, second_offset;
    short first_id, second_id;

    /* The first wall count lives in the low 16 bits of this saved word. */
    portal_keep_first(first);
    portal_keep_second(second);
    portal_ebx(portal_ax());
    keep_second_sector_offset(first_sector_offset());
    keep_second_sector_offset(portal_edx() << 2);
    keep_first_count(second_sector_id());
    portal_ebx(first_sector_offset() + portal_edx());
    keep_second_sector_offset(portal_ecx());
    portal_ebx(first_sector_offset() << 3);
    keep_second_sector_offset(portal_edx() << 2);
    keep_count_in_ax(*(const short *)((const char *)sector_wall_counts + first_sector_offset()));
    keep_second_sector_offset(portal_edx() + portal_ecx());
    first_count_storage = portal_eax();
    first_offset = first_sector_offset();
    second_offset = keep_second_sector_offset(second_sector_offset_before_scale() << 3);
    first_count = (short)keep_first_count(first_count_storage);
    second_count = keep_count_in_ax(*(const short *)((const char *)sector_wall_counts
                                   + second_offset));
    first_id = first_sector_id();
    second_id = second_sector_id();
    if (second_count > first_count) {
        short base;
        portal_eax_set(portal_ecx());
        base = portal_bx(*(const short *)((const char *)sector_wall_starts + first_offset));
        offset = read_portal_wall_cursor() - 1;
        keep_first_count(base);
        for (; offset >= 0; --offset) {
            if (wall[keep_offset(read_portal_wall_base() + offset)].next_sector == second_id)
                return keep_portal_result(1);
        }
    } else {
        short base = portal_bx(*(const short *)((const char *)sector_wall_starts + second_offset));
        offset = second_count - 1;
        keep_first_count(base);
        for (; offset >= 0; --offset) {
            if (wall[keep_offset(read_portal_wall_base() + offset)].next_sector == first_id)
                return keep_portal_result(1);
        }
    }
    return keep_portal_result(0);
}
