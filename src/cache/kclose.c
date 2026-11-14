// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "../engine/BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
#define SEEK_SET 0
#define SEEK_CUR 1
#define SEEK_END 2
extern long filehandle[], filepos[], groupfil;
extern long *fileoffs;
long lseek(int handle, long offset, int whence);
long filelength(int handle);
int close(int handle);

/* FATE has no negative-handle guard; valid logical handles are required. */
kclose(long handle)
{
	if (filepos[handle] < 0) close(filehandle[handle]);
	filehandle[handle] = -1;
}
