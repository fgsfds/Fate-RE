/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman.
 * See BUILDLIC.TXT for license terms. */
#pragma pack(push, 1)
typedef struct {
    long x, y, z;
    char attributes[12];
    short sectnum;
    char rest[18];
} Sprite;
#pragma pack(pop)

extern Sprite sprite[];
extern void updatesector(long x, long y, short *sector);
#pragma aux updatesector modify exact [eax];
extern int changespritesect(short slot, short sector);
#pragma aux changespritesect modify exact [eax edx];

int setsprite(short slot, long x, long y, long z)
{
    short sector;
    sprite[slot].y = y;
    sprite[slot].z = z;
    sector = sprite[slot].sectnum;
    sprite[slot].x = x;
    updatesector(x, y, &sector);
    if (sector < 0)
        return -1;
    if (sector != sprite[slot].sectnum)
        changespritesect(slot, sector);
    return 0;
}
