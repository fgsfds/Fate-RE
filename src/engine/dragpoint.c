/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman.
 * See BUILDLIC.TXT for license terms. */
#pragma pack(push, 1)
typedef struct {
    long x, y;
    short point2, nextwall;
    char reserved[20];
} DragWall;
#pragma pack(pop)

extern DragWall wall[];

extern int lastwall(short);
#pragma aux lastwall modify exact [eax];

/* Keep the forward link separate from its temporary address register. */
extern void release_forward_index(void);
#pragma aux release_forward_index = modify exact [eax];

void dragpoint(short original, long x, long y)
{
    short point, left, next;
    wall[original].x = x;
    wall[original].y = y;
    left = 8192;
    point = original;
    do {
        next = wall[point].nextwall;
        release_forward_index();
        if (next >= 0)
            goto forward;
        point = original;
        do {
            if (wall[lastwall(point)].nextwall < 0)
                return;
            point = wall[lastwall(point)].nextwall;
            wall[point].x = x;
            wall[point].y = y;
            --left;
        } while (point != original && left > 0);
        return;

    forward:
        point = wall[next].point2;
        wall[point].x = x;
        wall[point].y = y;
        --left;
    } while (point != original && left > 0);
}
