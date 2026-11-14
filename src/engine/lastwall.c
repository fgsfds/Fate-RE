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
#define MAXWALLS 8192

lastwall(short point)
{
	long i, j, cnt;

	if ((point > 0) && (wall[point-1].point2 == point)) return(point-1);
	i = point;
	cnt = MAXWALLS;
	do
	{
		j = wall[i].point2;
		if (j == point) return(i);
		i = j;
		cnt--;
	} while (cnt > 0);
	return(point);
}
