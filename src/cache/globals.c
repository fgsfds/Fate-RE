// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "../engine/BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
/* Scalar/array definitions; final linked bases remain external constraints. */
long cachecount = 0;
char zerochar = 0;
long cachestart = 0, cachesize = 0, cacnum = 0, agecount = 0;
long cacleng[4096];
char *lockptr[4096];
long *handptr[4096];
long numfiles, groupfil = -1, groupfilpos;
char *filelist;
long *fileoffs;
long filehandle[64] = {
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
};
long filepos[64];
