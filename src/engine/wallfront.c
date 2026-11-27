/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

/* The renderer reads x, y and the next wall from each 32-byte record. */
typedef struct {
    long x, y;
    short point2;
    unsigned char reserved[22];
} Wall;
extern Wall wall[];
extern short scan_wall_index[];
extern long camera_x, camera_y;

/* Low 32 bits of the signed 64-bit multiply-add, shifted right by two. */
extern long dmulscale2(long a, long b, long c, long d);
#pragma aux dmulscale2 = "imul ebx" "xchg esi, eax" "mov ebx, edx" "imul edi" \
    "add eax, esi" "adc edx, ebx" "shrd eax, edx, 2" \
    parm nomemory [eax] [ebx] [esi] [edi] modify exact [eax ebx edx esi] value [eax];

/* Drop locals and use the register restore tail shared with ceilings. */
extern void finish_wallfront(int result);
extern void ceiling_sprite_restore_registers(void);
#pragma aux ceiling_sprite_restore_registers aborts modify exact [];
#pragma aux finish_wallfront = "add esp, 40" "jmp ceiling_sprite_restore_registers" \
    aborts parm nomemory [eax] modify exact [];

extern void save_wallfront_registers(void);
#pragma aux save_wallfront_registers = "push ebx" "push ecx" "push esi" "push edi" "push ebp" modify exact [];

/* Watcom emits the five entry saves separately so geometry keeps its
 * original stack layout and branches into the shared epilogue. */
void wallfront(void);
#pragma aux wallfront aborts;

void wallfront(void)
{
    save_wallfront_registers();
}

/* BUILD performs these coordinate differences modulo 2^32. */
#define WALL_DELTA(a, b) ((long)((unsigned long)(a) - (unsigned long)(b)))

void wallfront_geometry(int l1, int l2);
#pragma aux wallfront_geometry aborts;

void wallfront_geometry(int l1, int l2)
{
    const Wall *endpoint;
    long x11, y11, x21, y21, x12, y12, x22, y22;
    long dx, dy, first, second;
    int result;

    endpoint = &wall[scan_wall_index[l1]];
    x11 = endpoint->x;
    y11 = endpoint->y;
    endpoint = &wall[endpoint->point2];
    x21 = endpoint->x;
    y21 = endpoint->y;

    endpoint = &wall[scan_wall_index[l2]];
    x12 = endpoint->x;
    y12 = endpoint->y;
    endpoint = &wall[endpoint->point2];
    x22 = endpoint->x;
    y22 = endpoint->y;

    /* Classify both endpoints of the second wall against the first. */
    dx = WALL_DELTA(x21, x11);
    dy = WALL_DELTA(y21, y11);
    first = dmulscale2(WALL_DELTA(x12, x11), dy, WALL_DELTA(0, dx), WALL_DELTA(y12, y11));
    second = dmulscale2(WALL_DELTA(x22, x11), dy, WALL_DELTA(0, dx), WALL_DELTA(y22, y11));
    if (!first) {
        first = second;
        if (!first) {
collinear:
            result = -1;
            goto done;
        }
    }
    if (!second)
        second = first;
    if ((first ^ second) >= 0) {
        second = dmulscale2(WALL_DELTA(camera_x, x11), dy, WALL_DELTA(0, dx), WALL_DELTA(camera_y, y11));
        result = (first ^ second) >= 0;
        goto done;
    }

    /* They straddle the first line. Try the opposite classification. */
    dx = WALL_DELTA(x22, x12);
    dy = WALL_DELTA(y22, y12);
    first = dmulscale2(WALL_DELTA(x11, x12), dy, WALL_DELTA(0, dx), WALL_DELTA(y11, y12));
    second = dmulscale2(WALL_DELTA(x21, x12), dy, WALL_DELTA(0, dx), WALL_DELTA(y21, y12));
    if (!first) {
        first = second;
        if (!first)
            goto collinear;
    }
    if (!second)
        second = first;
    if ((first ^ second) >= 0) {
        second = dmulscale2(WALL_DELTA(camera_x, x12), dy, WALL_DELTA(0, dx), WALL_DELTA(camera_y, y12));
        result = (first ^ second) < 0;
        goto done;
    }

    result = -2;

done:
    finish_wallfront(result);
}
