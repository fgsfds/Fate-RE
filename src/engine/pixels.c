// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
extern char *pixel_address(long address);
#pragma aux pixel_address = "" parm nomemory [edi] value [edi] modify exact [eax];

#pragma aux drawpixel =\
	"mov byte ptr [edi], al",\
	parm [edi][eax]\
	modify exact \

#pragma aux koutpw =\
	"out dx, ax",\
	parm [edx][eax]\
	modify exact \

extern char chainstat;
extern long chainplace, frameplace, ylookup[];
unsigned outpw(unsigned port, unsigned value);

plotpixel(long x, long y, char col)
{
	if (chainstat != 0)
	{
		outpw(0x3c4,2+(0x100<<(x&3)));
		drawpixel(ylookup[y]+(x>>2)+chainplace,(long)col);
	}
	else
	drawpixel(ylookup[y]+x+frameplace,(long)col);
}

char getpixel(long x, long y)
{
	if (chainstat != 0)
	{
		koutpw(0x3ce,4+((x&3)<<8));
		return(*pixel_address(ylookup[y]+(x>>2)+chainplace));
	}
	else
	return(*pixel_address(ylookup[y]+x+frameplace));
}
