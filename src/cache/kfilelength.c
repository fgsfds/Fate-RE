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

kfilelength(long handle)
{
	long i;

	if (filepos[handle] < 0) return(filelength(filehandle[handle]));
	i = filehandle[handle];
	return(fileoffs[i+1]-fileoffs[i]);
}
