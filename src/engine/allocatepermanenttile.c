// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
#define MAXTILES 4096
extern char walock[], picsiz[];
extern short tilesizx[], tilesizy[];
extern long waloff[], picanm[], pow2long[];
void allocache(long *handle, long size, char *lock);

allocatepermanenttile(short tilenume, long xsiz, long ysiz)
{
	long i, j, x, y, dasiz;

	if ((xsiz <= 0) || (ysiz <= 0) || ((tilenume & ~(MAXTILES-1)) != 0))
		return(0);

	dasiz = xsiz*ysiz;

	walock[tilenume] = 255;
	allocache(&waloff[tilenume],dasiz,&walock[tilenume]);

	tilesizx[tilenume] = xsiz;
	tilesizy[tilenume] = ysiz;
	picanm[tilenume] = 0;

	j = 15; while ((j > 1) && (pow2long[j] > xsiz)) j--;
	picsiz[tilenume] = ((char)j);
	j = 15; while ((j > 1) && (pow2long[j] > ysiz)) j--;
	picsiz[tilenume] += ((char)(j<<4));

	return(waloff[tilenume]);
}
