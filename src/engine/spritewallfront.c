// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
/* Minimal packed wall layout for isolated matching; see BUILDLIC.TXT. */
#pragma pack(1)
typedef struct {
    long x, y;
    short point2;
    char reserved[22];
} walltype;
#pragma pack()
extern walltype wall[];

typedef struct { long x, y; } spritetype;

#pragma aux dmulscale32 =\
	"imul ebx",\
	"xchg esi, eax",\
	"mov ebx, edx",\
	"imul edi",\
	"add eax, esi",\
	"adc edx, ebx",\
	parm nomemory [eax][ebx][esi][edi]\
	modify exact [eax ebx edx esi]\
	value [edx]\

spritewallfront (spritetype *s, long w)
{
	walltype *wal;
	long x1, y1;

	wal = &wall[w]; x1 = wal->x; y1 = wal->y;
	wal = &wall[wal->point2];
	return (dmulscale32(wal->x-x1,s->y-y1,-(s->x-x1),wal->y-y1) >= 0);
}
