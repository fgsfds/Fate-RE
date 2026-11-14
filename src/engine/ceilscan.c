// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
extern short uwall[], dwall[];
extern long lastx[];
extern void ceilspritehline(long,long), faketimerhandler(void);

ceilspritescan (long x1, long x2)
{
	long x, y1, y2, twall, bwall;

	y1 = uwall[x1]; y2 = y1;
	for(x=x1;x<=x2;x++)
	{
		twall = uwall[x]-1; bwall = dwall[x];
		if (twall < bwall-1)
		{
			if (twall >= y2)
			{
				while (y1 < y2-1) ceilspritehline(x-1,++y1);
				y1 = twall;
			}
			else
			{
				while (y1 < twall) ceilspritehline(x-1,++y1);
				while (y1 > twall) lastx[y1--] = x;
			}
			while (y2 > bwall) ceilspritehline(x-1,--y2);
			while (y2 < bwall) lastx[y2++] = x;
		}
		else
		{
			while (y1 < y2-1) ceilspritehline(x-1,++y1);
			if (x == x2) break;
			y1 = uwall[x+1]; y2 = y1;
		}
	}
	while (y1 < y2-1) ceilspritehline(x2,++y1);
	faketimerhandler();
}
