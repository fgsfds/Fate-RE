// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "../engine/BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
extern long agecount, cacnum;
extern char *lockptr[];

agecache()
{
	long cnt;
	char ch;

	if (agecount >= cacnum) agecount = cacnum-1;
	for(cnt=(cacnum>>4);cnt>=0;cnt--)
	{
		ch = (*lockptr[agecount]);
		if (((ch-2)&255) < 198)
			(*lockptr[agecount]) = ch-1;

		agecount--; if (agecount < 0) agecount = cacnum-1;
	}
}
