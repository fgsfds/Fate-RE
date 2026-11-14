// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// Adapted from pinned historical ENGINE.C; unaccessed fields remain reserved.
// Only insertsprite's 21-byte wrapper currently matches exactly. The two list
// helpers are behavioral reconstructions; their shared-return layout differs.
#pragma pack(push, 1)
typedef struct {
    char reserved_position[24];
    short sectnum, statnum;
    char reserved_tail[16];
} insert_spritetype;
#pragma pack(pop)
#define MAXSECTORS 1024
#define MAXSTATUS 1024
extern insert_spritetype sprite[];
extern short headspritesect[], prevspritesect[], nextspritesect[];
extern short headspritestat[], prevspritestat[], nextspritestat[];
int insertspritesect(short sectnum);
int insertspritestat(short statnum);

insertsprite(short sectnum, short statnum)
{
    insertspritestat(statnum);
    return(insertspritesect(sectnum));
}

insertspritesect(short sectnum)
{
    short blanktouse;
    if ((sectnum >= MAXSECTORS) || (headspritesect[MAXSECTORS] == -1))
        return(-1);
    blanktouse = headspritesect[MAXSECTORS];
    headspritesect[MAXSECTORS] = nextspritesect[blanktouse];
    if (headspritesect[MAXSECTORS] >= 0)
        prevspritesect[headspritesect[MAXSECTORS]] = -1;
    prevspritesect[blanktouse] = -1;
    nextspritesect[blanktouse] = headspritesect[sectnum];
    if (headspritesect[sectnum] >= 0)
        prevspritesect[headspritesect[sectnum]] = blanktouse;
    headspritesect[sectnum] = blanktouse;
    sprite[blanktouse].sectnum = sectnum;
    return(blanktouse);
}

insertspritestat(short statnum)
{
    short blanktouse;
    if ((statnum >= MAXSTATUS) || (headspritestat[MAXSTATUS] == -1))
        return(-1);
    blanktouse = headspritestat[MAXSTATUS];
    headspritestat[MAXSTATUS] = nextspritestat[blanktouse];
    if (headspritestat[MAXSTATUS] >= 0)
        prevspritestat[headspritestat[MAXSTATUS]] = -1;
    prevspritestat[blanktouse] = -1;
    nextspritestat[blanktouse] = headspritestat[statnum];
    if (headspritestat[statnum] >= 0)
        prevspritestat[headspritestat[statnum]] = blanktouse;
    headspritestat[statnum] = blanktouse;
    sprite[blanktouse].statnum = statnum;
    return(blanktouse);
}
