/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
typedef struct {
    long x, y;
    short point2, nextwall;
    short nextsector;
    char reserved[18];
} WallRecord;

extern WallRecord wall[];
typedef struct {
    short wallptr, wallnum;
    char reserved[36];
} WallSector;
extern short numwalls, numsectors;
extern WallSector sector[];

/* No-code constraints reproduce the original Watcom register choices. */
extern unsigned long wall_offset_in_eax(unsigned long);
#pragma aux wall_offset_in_eax = parm [eax] value [eax] modify exact [];
extern short first_wall_in_si(short);
#pragma aux first_wall_in_si = parm [si] value [si] modify exact [];

extern int end_wall_in_edx(int);
#pragma aux end_wall_in_edx = parm [edx] value [edx] modify exact [];

int sectorofwall(short wallnum)
{
    int index, half, next;

    if (wallnum < 0 || wallnum >= numwalls)
        return -1;
    next = wall[wallnum].nextwall;
    if (next >= 0)
        return ((WallRecord *)((char *)wall + wall_offset_in_eax((unsigned long)next << 5)))->nextsector;

    /* Narrow the sector range, then correct for exact wall boundaries. */
    half = numsectors >> 1;
    index = half;
    while (half > 1) {
        short first = first_wall_in_si(sector[index].wallptr);
        half >>= 1;
        if (wallnum > first)
            index += half;
        else
            index -= half;
    }
    while (wallnum < sector[index].wallptr)
        --index;
    while (end_wall_in_edx(sector[index].wallptr + sector[index].wallnum) <= wallnum)
        ++index;
    return index;
}
