// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
extern long ydim16, pageoffset;
extern char pow2char[];
void drawline16(long x1, long y1, long x2, long y2, char col);

#pragma aux mulscale14 =\
	"imul ebx",\
	"shrd eax, edx, 14",\
	parm nomemory [eax][ebx]\
	modify exact [eax edx]\

#pragma aux setcolor16 =\
	"mov dx, 0x3ce",\
	"shl ax, 8",\
	"out dx, ax",\
	parm [eax]\
	modify exact [eax edx]\

#pragma aux koutp =\
	"out dx, al",\
	parm [edx][eax]\
	modify exact \

#pragma aux vlin16first =\
	"mov al, byte ptr [edi]",\
	"mov eax, ecx",\
	"shr ecx, 2",\
	"begvlin16firsta: mov byte ptr [edi], al",\
	"mov byte ptr [edi+80], al",\
	"mov byte ptr [edi+160], al",\
	"mov byte ptr [edi+240], al",\
	"add edi, 320",\
	"dec ecx",\
	"jnz begvlin16firsta",\
	"mov ecx, eax",\
	"and ecx, 3",\
	"jz skipfirst",\
	"begvlin16firstb: mov byte ptr [edi], al",\
	"add edi, 80",\
	"dec ecx",\
	"jnz begvlin16firstb",\
	"skipfirst:",\
	parm [edi][ecx]\
	modify exact [eax ecx edi]\

draw2dgrid(long posxe, long posye, short ange, long zoome, short gride)
{
	long i, xp1, yp1, xp2, yp2, tempy, templong;
	char mask;

	if (gride > 0)
	{
		yp1 = 200-mulscale14(posye+65536,zoome);
		if (yp1 < 0) yp1 = 0;
		yp2 = 200-mulscale14(posye-65536,zoome);
		if (yp2 >= ydim16) yp2 = ydim16-1;

		if ((yp1 < ydim16) && (yp2 >= 0) && (yp2 >= yp1))
		{
			setcolor16(8);
			koutp(0x3ce,0x8);

			templong = ((yp1*640+pageoffset)>>3)+0xa0000;
			tempy = yp2-yp1+1;
			mask = 0;
			xp1 = 320-mulscale14(posxe+65536,zoome);

			for(i=-65536;i<=65536;i+=(2048>>gride))
			{
				xp2 = xp1;
				xp1 = 320-mulscale14(posxe-i,zoome);

				if (xp1 >= 640) break;
				if (xp1 >= 0)
				{
					if ((xp1|7) != (xp2|7))
					{
						koutp(0x3cf,mask);
						if (((xp2>>3) >= 0) && ((xp2>>3) < 80))
							vlin16first(templong+(xp2>>3),tempy);
						mask = 0;
					}
					mask |= pow2char[xp1&7^7];
				}
			}
			if ((i >= 65536) && (xp1 < 640))
				xp2 = xp1;
			if ((mask != 0) && ((xp2>>3) >= 0) && ((xp2>>3) < 80))
			{
				koutp(0x3cf,mask);
				vlin16first(templong+(xp2>>3),tempy);
			}
		}

		xp1 = mulscale14(posxe+65536,zoome);
		xp2 = mulscale14(posxe-65536,zoome);
		tempy = 0x80000000;
		for(i=-65536;i<=65536;i+=(2048>>gride))
		{
			yp1 = (((posye-i)*zoome)>>14);
			if (yp1 != tempy)
			{
				if ((yp1 > -200) && (yp1 <= 200))
				{
					drawline16(320-xp1,200-yp1,320-xp2,200-yp1,8);
					tempy = yp1;
				}
			}
		}
	}
}
