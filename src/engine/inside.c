// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
/* Older crossing expression from the May 1995 source, with FATE's do/while
 * traversal recovered from the verified assembly. Matches the isolated 189-byte FATE routine with Watcom 11.0c.
 * Only fields used by this leaf are modeled; other record bytes are reserved.
 */
#pragma pack(1)
typedef struct {
    short wallptr, wallnum;
    char reserved[36];
} sectortype;
typedef struct {
    long x, y;
    short point2;
    char reserved[22];
} walltype;
#pragma pack()
extern sectortype sector[];
extern walltype wall[];
extern short numsectors;

int inside(long x, long y, short sectnum)
{
    walltype *wal;
    long i, x1, y1, x2, y2;
    char cnt;
    if (sectnum < 0 || sectnum >= numsectors) return -1;
    cnt = 0;
    wal = &wall[sector[sectnum].wallptr];
    i = sector[sectnum].wallnum;
    do {
        y1 = wal->y-y;
        y2 = wall[wal->point2].y-y;
        if ((y1^y2) < 0) {
            x1 = wal->x-x;
            x2 = wall[wal->point2].x-x;
            if ((x1^x2) < 0)
                cnt ^= (x1*y2 < x2*y1) ^ (y1 < y2);
            else if (x1 >= 0)
                cnt ^= 1;
        }
        wal++;
        i--;
    } while (i);
    return cnt;
}
