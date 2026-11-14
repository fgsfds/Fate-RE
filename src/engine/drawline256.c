// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
extern char chainstat, pow2char[];
extern char *palookup[];
extern long wx1, wx2, wy1, wy2, chainplace, frameplace, ylookup[];
extern short startumost[], startdmost[];

#pragma aux scale =\
	"imul ebx",\
	"idiv ecx",\
	parm nomemory [eax][ebx][ecx]\
	modify exact [eax edx]\

#pragma aux klabs =\
	"test eax, eax",\
	"jns skipnegate",\
	"neg eax",\
	"skipnegate:",\
	parm nomemory [eax]\

#pragma aux divscale12 =\
	"mov edx, eax",\
	"sar edx, 20",\
	"shl eax, 12",\
	"idiv ebx",\
	parm nomemory [eax][ebx]\
	modify exact [eax edx]\

#pragma aux mulscale12 =\
	"imul ebx",\
	"shrd eax, edx, 12",\
	parm nomemory [eax][ebx]\
	modify exact [eax edx]\

#pragma aux drawpixel =\
	"mov byte ptr [edi], al",\
	parm [edi][eax]\
	modify exact \

#pragma aux koutp =\
	"out dx, al",\
	parm [edx][eax]\
	modify exact \

drawline256 (long x1, long y1, long x2, long y2, char col)
{
	long dx, dy, i, j, p, inc, plc, daend;

	col = palookup[0][col];

	dx = x2-x1; dy = y2-y1;
	if (dx >= 0)
	{
		if ((x1 >= wx2) || (x2 < wx1)) return;
		if (x1 < wx1) y1 += scale(wx1-x1,dy,dx), x1 = wx1;
		if (x2 > wx2) y2 += scale(wx2-x2,dy,dx), x2 = wx2;
	}
	else
	{
		if ((x2 >= wx2) || (x1 < wx1)) return;
		if (x2 < wx1) y2 += scale(wx1-x2,dy,dx), x2 = wx1;
		if (x1 > wx2) y1 += scale(wx2-x1,dy,dx), x1 = wx2;
	}
	if (dy >= 0)
	{
		if ((y1 >= wy2) || (y2 < wy1)) return;
		if (y1 < wy1) x1 += scale(wy1-y1,dx,dy), y1 = wy1;
		if (y2 > wy2) x2 += scale(wy2-y2,dx,dy), y2 = wy2;
	}
	else
	{
		if ((y2 >= wy2) || (y1 < wy1)) return;
		if (y2 < wy1) x2 += scale(wy1-y2,dx,dy), y2 = wy1;
		if (y1 > wy2) x1 += scale(wy2-y1,dx,dy), y1 = wy2;
	}

	if (klabs(dx) >= klabs(dy))
	{
		if (dx == 0) return;
		if (dx < 0)
		{
			i = x1; x1 = x2; x2 = i;
			i = y1; y1 = y2; y2 = i;
		}

		inc = divscale12(dy,dx);
		plc = y1+mulscale12((2047-x1)&4095,inc);
		i = ((x1+2048)>>12); daend = ((x2+2048)>>12);
		if (chainstat != 0)
		{
			koutp(0x3c4,2);
			for(;i<daend;i++)
			{
				j = (plc>>12);
				if ((j >= startumost[i]) && (j < startdmost[i]))
				{
					koutp(0x3c5,pow2char[i&3]);
					drawpixel(ylookup[j]+(i>>2)+chainplace,col);
				}
				plc += inc;

			}
		}
		else
		{
		for(;i<daend;i++)
		{
			j = (plc>>12);
			if ((j >= startumost[i]) && (j < startdmost[i]))
				drawpixel(ylookup[j]+i+frameplace,col);
			plc += inc;
		}
		}
	}
	else
	{
		if (dy < 0)
		{
			i = x1; x1 = x2; x2 = i;
			i = y1; y1 = y2; y2 = i;
		}

		inc = divscale12(dx,dy);
		plc = x1+mulscale12((2047-y1)&4095,inc);
		i = ((y1+2048)>>12); daend = ((y2+2048)>>12);
		if (chainstat != 0)
		{
			koutp(0x3c4,2);
			p = ylookup[i]+chainplace;
			for(;i<daend;i++)
			{
				j = (plc>>12);
				if ((i >= startumost[j]) && (i < startdmost[j]))
				{
					koutp(0x3c5,pow2char[j&3]);
					drawpixel((j>>2)+p,col);
				}
				plc += inc; p += ylookup[1];
			}
		}
		else
		{
		p = ylookup[i]+frameplace;
		for(;i<daend;i++)
		{
			j = (plc>>12);
			if ((i >= startumost[j]) && (i < startdmost[j]))
				drawpixel(j+p,col);
			plc += inc; p += ylookup[1];
		}
		}
	}
}
