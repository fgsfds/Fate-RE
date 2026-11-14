// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "../engine/BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
#define O_BINARY 0x0200
#define O_RDWR 2
#define S_IREAD 0x0100
extern long groupfil, groupfilpos, numfiles;
extern char *filelist;
extern long *fileoffs;
extern char group_list_allocation_error[], group_offsets_allocation_error[];
int uninitgroupfile(void);
int open(const char *filename, int flags, ...);
int read(int handle, void *buffer, unsigned int length);
int close(int handle);
void *kmalloc(long size);
int printf(const char *format, ...);
void exit(int status);

initgroupfile(char *filename)
{
	char buf[16];
	long i, j, k;

	uninitgroupfile();

	groupfil = open(filename,O_BINARY|O_RDWR,S_IREAD);
	if (groupfil != -1)
	{
		groupfilpos = 0;
		read(groupfil,buf,16);
		if (((long)buf[0] != 'K') || ((long)buf[1] != 'e') || ((long)buf[2] != 'n') ||
			 ((long)buf[3] != 'S') || ((long)buf[4] != 'i') || ((long)buf[5] != 'l') ||
			 ((long)buf[6] != 'v') || ((long)buf[7] != 'e') || ((long)buf[8] != 'r') ||
			 ((long)buf[9] != 'm') || ((long)buf[10] != 'a') || ((long)buf[11] != 'n'))
		{
			close(groupfil);
			groupfil = -1;
			return(-1);
		}
		numfiles = ((long)buf[12])+(((long)buf[13])<<8)+(((long)buf[14])<<16)+(((long)buf[15])<<24);

		if ((filelist = (char *)kmalloc(numfiles<<4)) == 0)
			{ printf(group_list_allocation_error); exit(0); }
		if ((fileoffs = (long *)kmalloc((numfiles+1)<<2)) == 0)
			{ printf(group_offsets_allocation_error); exit(0); }

		read(groupfil,filelist,numfiles<<4);

		j = 0;
		for(i=0;i<numfiles;i++)
		{
			k = ((long)filelist[(i<<4)+12])+(((long)filelist[(i<<4)+13])<<8)+(((long)filelist[(i<<4)+14])<<16)+(((long)filelist[(i<<4)+15])<<24);
			filelist[(i<<4)+12] = 0;
			fileoffs[i] = j;
			j += k;
		}
		fileoffs[numfiles] = j;
	}
	return(groupfil);
}
