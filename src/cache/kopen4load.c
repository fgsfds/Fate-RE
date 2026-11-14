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

kopen4load(char *filename, char searchfirst)
{
	long i, j, fil, newhandle;
	char ch1, ch2, bad;

	newhandle = MAXOPENFILES-1;
	while (filehandle[newhandle] != -1)
	{
		newhandle--;
		if (newhandle < 0)
		{
			printf(group_too_many_files);
			exit(0);
		}
	}

	if (searchfirst == 0)
		if ((fil = open(filename,O_BINARY|O_RDONLY)) != -1)
		{
			filehandle[newhandle] = fil;
			filepos[newhandle] = -1;
			return(newhandle);
		}
	if (groupfil != -1)
	{
		for(i=numfiles-1;i>=0;i--)
		{
			j = 0; bad = 0;
			while ((filename[j] != 0) && (j < 13))
			{
				ch1 = filename[j]; if (((long)ch1 >= 97) && ((long)ch1 <= 123)) ch1 -= 32;
				ch2 = filelist[(i<<4)+j]; if (((long)ch2 >= 97) && ((long)ch2 <= 123)) ch2 -= 32;
				if (ch1 != ch2) { bad = 1; break; }
				j++;
			}
			if (bad != 0) continue;

			filepos[newhandle] = 0;
			filehandle[newhandle] = i;
			return(newhandle);
		}
	}
	return(-1);
}
