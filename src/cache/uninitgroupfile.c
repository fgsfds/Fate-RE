// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "../engine/BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
#define MAXOPENFILES 64
#define O_BINARY 0x0200
#define O_RDONLY 0
#define SEEK_SET 0
extern long filehandle[], filepos[], groupfil, groupfilpos, numfiles;
extern char *filelist;
extern long *fileoffs;
extern char group_too_many_files[];
int open(const char *filename, int flags, ...);
int read(int handle, void *buffer, unsigned int length);
int close(int handle);
long lseek(int handle, long offset, int whence);
int min(long first, long second);
int printf(const char *format, ...);
void exit(int status);
int kfree(void *pointer);

uninitgroupfile()
{
	if (groupfil != -1)
	{
		kfree(filelist); kfree(fileoffs);
		close(groupfil);
		groupfil = -1;
	}
}
