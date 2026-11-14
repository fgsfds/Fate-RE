// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// Adapted from pinned historical ENGINE.C; unaccessed fields remain reserved.
#pragma pack(push, 1)
typedef struct {
    char reserved_position[24];
    short sectnum, statnum;
    char reserved_tail[16];
} change_spritetype;
#pragma pack(pop)
#define MAXSECTORS 1024L
#define MAXSTATUS 1024L
extern change_spritetype sprite[];
extern int deletespritesect(short), deletespritestat(short);
extern int insertspritesect(short), insertspritestat(short);

int changespritesect(short spritenum, short newsectnum)
{
    if ((newsectnum < 0) || ((long)newsectnum > MAXSECTORS)) return(-1);
    if (sprite[spritenum].sectnum == newsectnum) return(0);
    if ((long)sprite[spritenum].sectnum == MAXSECTORS) return(-1);
    if (deletespritesect(spritenum) < 0) return(-1);
    insertspritesect(newsectnum);
    return(0);
}

int changespritestat(short spritenum, short newstatnum)
{
    if ((newstatnum < 0) || ((long)newstatnum > MAXSTATUS)) return(-1);
    if (sprite[spritenum].statnum == newstatnum) return(0);
    if ((long)sprite[spritenum].statnum == MAXSTATUS) return(-1);
    if (deletespritestat(spritenum) < 0) return(-1);
    insertspritestat(newstatnum);
    return(0);
}
