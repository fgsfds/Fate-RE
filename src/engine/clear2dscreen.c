// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
extern long qsetmode, pageoffset, ydim16;

#pragma aux fillscreen16 =\
	"mov dx, 0x3ce",\
	"shl ax, 8",\
	"out dx, ax",\
	"mov ax, 0xff08",\
	"out dx, ax",\
	"shr ecx, 5",\
	"add edi, 0xa0000",\
	"rep stosd",\
	parm [edi][eax][ecx]\
	modify exact [eax ecx edx edi]\

clear2dscreen()
{
	if (qsetmode == 350)
		fillscreen16(pageoffset>>3,0L,640L*350L);
	else if (qsetmode == 480)
	{
		if (ydim16 <= 336) fillscreen16(pageoffset>>3,0L,640L*336L);
						  else fillscreen16(pageoffset>>3,0L,640L*480L);
	}
}
