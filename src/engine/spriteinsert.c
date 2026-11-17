// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// Adapted from pinned historical ENGINE.C; unaccessed fields remain reserved.
// The helpers return through the register-restore tail shared with the rasterizer.
// Keep distinct success and error exits for each helper so Watcom emits both jumps.
extern void return_sector_sprite(int);
#pragma aux return_sector_sprite "shared_graphics_epilogue_" parm [eax] aborts modify exact [];
extern void return_sector_sprite_error(int);
#pragma aux return_sector_sprite_error "shared_graphics_epilogue_" parm [eax] aborts modify exact [];
extern void return_status_sprite(int);
#pragma aux return_status_sprite "shared_graphics_epilogue_" parm [eax] aborts modify exact [];
extern void return_status_sprite_error(int);
#pragma aux return_status_sprite_error "shared_graphics_epilogue_" parm [eax] aborts modify exact [];

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
    if (((long)sectnum >= MAXSECTORS) || (headspritesect[MAXSECTORS] == -1))
        return_sector_sprite_error(-1);
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
    return_sector_sprite(blanktouse);
}

insertspritestat(short statnum)
{
    short blanktouse;
    if (((long)statnum >= MAXSTATUS) || (headspritestat[MAXSTATUS] == -1))
        return_status_sprite_error(-1);
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
    return_status_sprite(blanktouse);
}
