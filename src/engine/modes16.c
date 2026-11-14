// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
extern long qsetmode, stereofps, pageoffset, ydim16;

#pragma aux setvmode =\
	"int 0x10",\
	parm [eax]\

#pragma aux koutpw =\
	"out dx, ax",\
	parm [edx][eax]\
	modify exact \

#pragma aux koutp =\
	"out dx, al",\
	parm [edx][eax]\
	modify exact \

#pragma aux kinp =\
	"in al, dx",\
	parm nomemory [edx]\
	modify exact [eax]\

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

qsetmode640350()
{
	if (qsetmode != 350)
	{
		if (stereofps != 0) stereofps = 1;

		setvmode(0x10);

		pageoffset = 0;
		ydim16 = 350;
		koutpw(0x3d4,0xc+((pageoffset>>11)<<8));

		koutpw(0x3ce,0x0f00);  //set/reset
		koutpw(0x3ce,0x0f01);  //enable set/reset
		fillscreen16(0L,0L,640L*350L);
	}
	qsetmode = 350;
}

qsetmode640480()
{
	short i;

	if (qsetmode != 480)
	{
		if (stereofps != 0) stereofps = 1;

		setvmode(0x12);

		i = 479-144;
		koutpw(0x3d4,0x18+((i&255)<<8));             //line compare
		koutp(0x3d4,0x7); koutp(0x3d5,(kinp(0x3d5)&239)|((i&256)>>4));
		koutp(0x3d4,0x9); koutp(0x3d5,(kinp(0x3d5)&191)|((i&512)>>3));

		pageoffset = 92160;
		koutpw(0x3d4,0xc+((pageoffset>>11)<<8));

		koutpw(0x3ce,0x0f00);  //set/reset
		koutpw(0x3ce,0x0f01);  //enable set/reset
		fillscreen16(0L,8L,640L*144L);
		fillscreen16((640L*144L)>>3,0L,640L*336L);
		pageoffset = 92160; ydim16 = 336;
	}

	qsetmode = 480;
}
