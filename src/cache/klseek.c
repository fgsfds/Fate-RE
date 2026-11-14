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

klseek(long handle, long offset, long whence)
{
	long i;

	if (filepos[handle] < 0) return(lseek(filehandle[handle],offset,whence));
	if (groupfil != -1)
	{
		switch(whence)
		{
			case SEEK_SET: filepos[handle] = offset; break;
			case SEEK_END: i = filehandle[handle];
								filepos[handle] = (fileoffs[i+1]-fileoffs[i])+offset;
								break;
			case SEEK_CUR: filepos[handle] += offset; break;
		}
		return(filepos[handle]);
	}
	return(-1);
}
