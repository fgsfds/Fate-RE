// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release

#pragma pack(1)
typedef struct
{
	short wallptr, wallnum;
	long ceilingz, floorz;
	short ceilingstat, floorstat;
	short ceilingpicnum, ceilingheinum;
	signed char ceilingshade;
	char ceilingpal, ceilingxpanning, ceilingypanning;
	short floorpicnum, floorheinum;
	signed char floorshade;
	char floorpal, floorxpanning, floorypanning;
	char visibility, filler;
	short lotag, hitag, extra;
} sectortype;
typedef struct { long x, y; short point2; char reserved[22]; } walltype;
#pragma pack()
extern sectortype sector[];
extern walltype wall[];
extern short sqrtable[];

#pragma aux scale =\
	"imul ebx",\
	"idiv ecx",\
	parm nomemory [eax][ebx][ecx]\
	modify exact [eax edx]\

#pragma aux ksqrtasm = \
	"test eax, eax",\
	"jns skipnegate",\
	"neg eax",\
	"skipnegate: bsr ecx, eax",\
	"cmp cl, 11",\
	"jge short over2048",\
	"movzx eax, word ptr sqrtable[eax*2]",\
	"jmp short end",\
	"over2048: sub cl, 9",\
	"and cl, 0xfe",\
	"sar eax, cl",\
	"movzx eax, word ptr sqrtable[eax*2]",\
	"sar cl, 1",\
	"shl eax, cl",\
	"end: sar eax, 10",\
	parm nomemory [eax]\
	modify exact [eax ebx ecx edx]\

alignceilslope(short dasect, long x, long y, long z)
{
	long i, j, dax, day;

	j = sector[dasect].wallptr;
    i = wall[j].point2;
	dax = wall[i].x-wall[j].x;
	day = wall[i].y-wall[j].y;

	i = (y-wall[j].y)*dax - (x-wall[j].x)*day; if (i == 0) return;
	sector[dasect].ceilingheinum = scale((z-sector[dasect].ceilingz)<<8,
													 ksqrtasm(dax*dax+day*day),i);

	if (sector[dasect].ceilingheinum == 0) sector[dasect].ceilingstat &= ~2;
												 else sector[dasect].ceilingstat |= 2;
}

alignflorslope(short dasect, long x, long y, long z)
{
	long i, j, dax, day;

	j = sector[dasect].wallptr;
    i = wall[j].point2;
	dax = wall[i].x-wall[j].x;
	day = wall[i].y-wall[j].y;

	i = (y-wall[j].y)*dax - (x-wall[j].x)*day; if (i == 0) return;
	sector[dasect].floorheinum = scale((z-sector[dasect].floorz)<<8,
												  ksqrtasm(dax*dax+day*day),i);

	if (sector[dasect].floorheinum == 0) sector[dasect].floorstat &= ~2;
											  else sector[dasect].floorstat |= 2;
}
