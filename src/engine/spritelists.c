// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// Adapted from pinned historical ENGINE.C; unaccessed fields remain reserved.
// Watcom shares the deletion epilogue with the local insertion helpers.
// Only deletion code is linked from this object. The exact build binds its
// jumps to the identical register-restore epilogue shared by the game.
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
int insertspritesect(short), insertspritestat(short);
int deletespritesect(short), deletespritestat(short);

insertsprite(short sectnum, short statnum)
{
	insertspritestat(statnum);
	return(insertspritesect(sectnum));
}

insertspritesect(short sectnum)
{
	short blanktouse;

	if (((long)sectnum >= MAXSECTORS) || (headspritesect[MAXSECTORS] == -1))
		return(-1);  //list full

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

	if (((long)statnum >= MAXSTATUS) || (headspritestat[MAXSTATUS] == -1))
		return(-1);  //list full

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

deletesprite(short spritenum)
{
	deletespritestat(spritenum);
	return(deletespritesect(spritenum));
}

deletespritesect(short deleteme)
{
	if ((long)sprite[deleteme].sectnum == MAXSECTORS)
		return(-1);

	if (headspritesect[sprite[deleteme].sectnum] == deleteme)
		headspritesect[sprite[deleteme].sectnum] = nextspritesect[deleteme];

	if (prevspritesect[deleteme] >= 0) nextspritesect[prevspritesect[deleteme]] = nextspritesect[deleteme];
	if (nextspritesect[deleteme] >= 0) prevspritesect[nextspritesect[deleteme]] = prevspritesect[deleteme];

	if (headspritesect[MAXSECTORS] >= 0) prevspritesect[headspritesect[MAXSECTORS]] = deleteme;
	prevspritesect[deleteme] = -1;
	nextspritesect[deleteme] = headspritesect[MAXSECTORS];
	headspritesect[MAXSECTORS] = deleteme;

	sprite[deleteme].sectnum = MAXSECTORS;
	return(0);
}

deletespritestat (short deleteme)
{
	if ((long)sprite[deleteme].statnum == MAXSTATUS)
		return(-1);

	if (headspritestat[sprite[deleteme].statnum] == deleteme)
		headspritestat[sprite[deleteme].statnum] = nextspritestat[deleteme];

	if (prevspritestat[deleteme] >= 0) nextspritestat[prevspritestat[deleteme]] = nextspritestat[deleteme];
	if (nextspritestat[deleteme] >= 0) prevspritestat[nextspritestat[deleteme]] = prevspritestat[deleteme];

	if (headspritestat[MAXSTATUS] >= 0) prevspritestat[headspritestat[MAXSTATUS]] = deleteme;
	prevspritestat[deleteme] = -1;
	nextspritestat[deleteme] = headspritestat[MAXSTATUS];
	headspritestat[MAXSTATUS] = deleteme;

	sprite[deleteme].statnum = MAXSTATUS;
	return(0);
}
