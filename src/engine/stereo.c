// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
extern long page, stereopixelwidth;
extern void setverts(long,long,long,long,long,long);
#pragma aux koutp =\
	"out dx, al",\
	parm [edx][eax]\
	modify exact \

#pragma aux kinp =\
	"in al, dx",\
	parm nomemory [edx]\
	modify exact [eax]\

#pragma aux copybuf =\
	"rep movsd",\
	parm [esi][edi][ecx]\
	modify exact [ecx esi edi]\



stereoinit()
{
	long i;

	setverts(510L,487L,0L,479L,12L,479L);

	koutp(0x3d4,0x38); koutp(0x3d5,0x48);           //S3 Extensions enable #1
	koutp(0x3d4,0x39); koutp(0x3d5,0xa5);           //S3 Extensions enable #2
	koutp(0x3d4,0x31); koutp(0x3d5,kinp(0x3d5)|9);   //Init for start address

	koutp(0x3d4,0x9); koutp(0x3d5,kinp(0x3d5)&(255-1));
}

stereoblit(long dastereopage, char *stereobuf)
{
	if (stereopixelwidth >= 0)
	{
		if (dastereopage == 0)
		{
			koutp(0x3d4,0x35); koutp(0x3d5,page+0); copybuf(stereobuf+stereopixelwidth,0xa0000,64000>>2);
		}
		else
		{
			koutp(0x3d4,0x35); koutp(0x3d5,page+1); copybuf(stereobuf,0xa4000,49152>>2);
			koutp(0x3d4,0x35); koutp(0x3d5,page+2); copybuf(stereobuf+49152,0xa0000,14848>>2);
		}
	}
	else
	{
	}
}
