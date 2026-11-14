// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
extern long ydim16, pageoffset;

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

#pragma aux setcolor16 =\
	"mov dx, 0x3ce",\
	"shl ax, 8",\
	"out dx, ax",\
	parm [eax]\
	modify exact [eax edx]\

#pragma aux koutpw =\
	"out dx, ax",\
	parm [edx][eax]\
	modify exact \

#pragma aux koutp =\
	"out dx, al",\
	parm [edx][eax]\
	modify exact \

#pragma aux vlin16 =\
	"mov esi, edi",\
	"begvlin16: movsb",\
	"add edi, 79",\
	"add esi, 79",\
	"dec ecx",\
	"jnz begvlin16",\
	parm [edi][ecx]\
	modify exact [ecx esi edi]\

#pragma aux mul5 =\
	"lea eax, [eax+eax*4]",\
	parm nomemory [eax]\

#pragma aux drawpixel =\
	"mov byte ptr [edi], al",\
	parm [edi][eax]\
	modify exact \

#pragma aux readpixel =\
	"mov al, byte ptr [edi]",\
	parm nomemory [edi]\
	modify exact [eax]\

#pragma aux clearbufbyte =\
	"cmp ecx, 4",\
	"jae longcopy",\
	"test cl, 1",\
	"jz preskip",\
	"stosb",\
	"preskip: shr ecx, 1",\
	"rep stosw",\
	"jmp endit",\
	"longcopy: test edi, 1",\
	"jz skip1",\
	"stosb",\
	"dec ecx",\
	"skip1: test edi, 2",\
	"jz skip2",\
	"stosw",\
	"sub ecx, 2",\
	"skip2: mov ebx, ecx",\
	"shr ecx, 2",\
	"rep stosd",\
	"test bl, 2",\
	"jz skip3",\
	"stosw",\
	"skip3: test bl, 1",\
	"jz endit",\
	"stosb",\
	"endit:",\
	parm [edi][ecx][eax]\
	modify [ebx]\

#pragma aux drawpixel16 =\
	"mov ecx, edi",\
	"mov eax, 0x00008008",\
	"mov dx, 0x3ce",\
	"ror ah, cl",\
	"shr edi, 3",\
	"out dx, ax",\
	"mov cl, byte ptr [edi+0xa0000]",\
	"mov byte ptr [edi+0xa0000], al",\
	parm [edi]\
	modify exact [eax ecx edx edi]\

drawline16(long x1, long y1, long x2, long y2, char col)
{
	long i, dx, dy, p, pinc, d;
	char lmask, rmask;

	dx = x2-x1; dy = y2-y1;
	if (dx >= 0)
	{
		if ((x1 > 639) || (x2 < 0)) return;
		if (x1 < 0) { if (dy) y1 += scale(0-x1,dy,dx); x1 = 0; }
		if (x2 > 639) { if (dy) y2 += scale(639-x2,dy,dx); x2 = 639; }
	}
	else
	{
		if ((x2 > 639) || (x1 < 0)) return;
		if (x2 < 0) { if (dy) y2 += scale(0-x2,dy,dx); x2 = 0; }
		if (x1 > 639) { if (dy) y1 += scale(639-x1,dy,dx); x1 = 639; }
	}
	if (dy >= 0)
	{
		if ((y1 >= ydim16) || (y2 < 0)) return;
		if (y1 < 0) { if (dx) x1 += scale(0-y1,dx,dy); y1 = 0; }
		if (y2 >= ydim16) { if (dx) x2 += scale(ydim16-1-y2,dx,dy); y2 = ydim16-1; }
	}
	else
	{
		if ((y2 >= ydim16) || (y1 < 0)) return;
		if (y2 < 0) { if (dx) x2 += scale(0-y2,dx,dy); y2 = 0; }
		if (y1 >= ydim16) { if (dx) x1 += scale(ydim16-1-y1,dx,dy); y1 = ydim16-1; }
	}

	setcolor16((long)col);
	if (x1 == x2)
	{
		if (y2 < y1) i = y1, y1 = y2, y2 = i;
		koutpw(0x3ce,0x8+(256<<(x1&7^7)));  //bit mask
		vlin16((((mul5(y1)<<7)+x1+pageoffset)>>3)+0xa0000,y2-y1+1);
		return;
	}
	if (y1 == y2)
	{
		if (x2 < x1) i = x1, x1 = x2, x2 = i;
		lmask = (0x00ff>>(x1&7));
		rmask = (0xff80>>(x2&7));

		p = (((mul5(y1)<<7)+x1+pageoffset)>>3)+0xa0000;

		dx = (x2>>3)-(x1>>3);
		if (dx == 0)
		{
			koutpw(0x3ce,0x8+((lmask&rmask)<<8)); drawpixel(p,readpixel(p));
			return;
		}

		dx--;

		koutpw(0x3ce,0x8+(lmask<<8)); drawpixel(p,readpixel(p)); p++;
		if (dx > 0) { koutp(0x3cf,0xff); clearbufbyte(p,dx,0L); p += dx; }
		koutp(0x3cf,rmask); drawpixel(p,readpixel(p));
		return;
	}

	dx = klabs(x2-x1)+1; dy = klabs(y2-y1)+1;
	if (dx >= dy)
	{
		if (x2 < x1)
		{
			i = x1; x1 = x2; x2 = i;
			i = y1; y1 = y2; y2 = i;
		}
		p = (mul5(y1)<<7)+x1+pageoffset;
		d = 0;
		if (y2 > y1) pinc = 640; else pinc = -640;
		for(i=dx;i>0;i--)
		{
			drawpixel16(p);
			d += dy;
			if (d >= dx) { d -= dx; p += pinc; }
			p++;
		}
		return;
	}

	if (y2 < y1)
	{
		i = x1; x1 = x2; x2 = i;
		i = y1; y1 = y2; y2 = i;
	}
	p = (mul5(y1)<<7)+x1+pageoffset;
	d = 0;
	if (x2 > x1) pinc = 1; else pinc = -1;
	for(i=dy;i>0;i--)
	{
		drawpixel16(p);
		d += dx;
		if (d >= dy) { d -= dy; p += pinc; }
		p += 640;
	}
}
