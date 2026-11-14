// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "../engine/BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
extern long cachestart, cachesize, cacnum;
extern long cacleng[];
extern char *lockptr[];
extern char zerochar;

initcache(long dacachestart, long dacachesize)
{
    cachestart = dacachestart;
    cachesize = dacachesize;
    cacleng[0] = cachesize;
    lockptr[0] = &zerochar;
    cacnum = 1;
}
