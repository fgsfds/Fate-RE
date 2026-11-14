// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
/* Isolated packed layouts; unaccessed fields remain reserved. */
#pragma pack(1)
typedef struct { short wallptr, wallnum; char reserved[36]; } sectortype;
typedef struct {
    long x, y;
    short point2, nextwall, nextsector;
    char reserved[18];
} walltype;
#pragma pack()
extern sectortype sector[];
extern walltype wall[];
extern short numsectors;
int inside(long x, long y, short sectnum);

updatesector(long x, long y, short *sectnum)
{
	walltype *wal;
	long i, j;

	if (inside(x,y,*sectnum) == 1) return;

	if ((*sectnum >= 0) && (*sectnum < numsectors))
	{
		wal = &wall[sector[*sectnum].wallptr];
		j = sector[*sectnum].wallnum;
		do
		{
			i = wal->nextsector;
			if (i >= 0)
				if (inside(x,y,(short)i) == 1)
				{
					*sectnum = i;
					return;
				}
			wal++;
			j--;
		} while (j != 0);
	}

	for(i=numsectors-1;i>=0;i--)
		if (inside(x,y,(short)i) == 1)
		{
			*sectnum = i;
			return;
		}

	*sectnum = -1;
}
