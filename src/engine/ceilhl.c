// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
#define LIBVER_BUILDREV 19951025L
#define FP_OFF(p) ((long)(p))
extern long lastx[], *horizlookup, ylookup[];
extern char chainstat, pow2char[];
extern char *palookup[];
extern long globalzd, globalhoriz, horizycent, globalx1, globalx2, globaly1, globaly2;
extern long globalxpanning, globalypanning, asm1, asm2, asm3, globalpal, globvis, globalshade;
extern long viewoffset, chainplace, globalorientation, globalbufplc, transarea, frameplace;
extern long getpalookup(long,long);
extern long mhline(long,long,long,long,long,long);
#pragma aux mhline parm [eax][ebx][ecx][edx][esi][edi];
extern long mhlineskipmodify(long,long,long,long,long,long);
#pragma aux mhlineskipmodify parm [eax][ebx][ecx][edx][esi][edi];
extern long thline(long,long,long,long,long,long);
#pragma aux thline parm [eax][ebx][ecx][edx][esi][edi];
extern long thlineskipmodify(long,long,long,long,long,long);
#pragma aux thlineskipmodify parm [eax][ebx][ecx][edx][esi][edi];
#pragma aux mulscale20 =\
	"imul ebx",\
	"shrd eax, edx, 20",\
	parm nomemory [eax][ebx]\
	modify exact [eax edx]\

#pragma aux mulscale14 =\
	"imul ebx",\
	"shrd eax, edx, 14",\
	parm nomemory [eax][ebx]\
	modify exact [eax edx]\

#pragma aux mulscale28 =\
	"imul ebx",\
	"shrd eax, edx, 28",\
	parm nomemory [eax][ebx]\
	modify exact [eax edx]\

#pragma aux klabs =\
	"test eax, eax",\
	"jns skipnegate",\
	"neg eax",\
	"skipnegate:",\
	parm nomemory [eax]\

#pragma aux koutp =\
	"out dx, al",\
	parm [edx][eax]\
	modify exact \


void ceilspritehline (long x2, long y)
{
#if (LIBVER_BUILDREV < 19960427L)
	long x1, v, bx, by, x, xend, bxinc, byinc, p;
#else
	long x1, v, bx, by;
#endif

	//x = x1 + (x2-x1)t + (y1-y2)u  ³  x = 160v
	//y = y1 + (y2-y1)t + (x2-x1)u  ³  y = (scrx-160)v
	//z = z1 = z2                   ³  z = posz + (scry-horiz)v

	x1 = lastx[y]; if (x2 < x1) return;

	v = mulscale20(globalzd,horizlookup[y-globalhoriz+horizycent]);
	bx = mulscale14(globalx2*x1+globalx1,v) + globalxpanning;
	by = mulscale14(globaly2*x1+globaly1,v) + globalypanning;
	asm1 = mulscale14(globalx2,v);
	asm2 = mulscale14(globaly2,v);

	asm3 = FP_OFF(palookup[globalpal]) + (getpalookup((long)mulscale28(klabs(v),globvis),globalshade)<<8);

#if (LIBVER_BUILDREV < 19960427L)
	if (chainstat != 0)
	{
		bxinc = asm1; asm1 <<= 2;
		byinc = asm2; asm2 <<= 2;
		x1 += viewoffset; x2 += viewoffset;
		p = ylookup[y]+chainplace;
		xend = x1+3;
		if(x2 < xend) xend = x2;
		if ((globalorientation&2) == 0)
		{
			x = x1;
			if (x <= xend)
			{
				koutp(0x3c5,pow2char[x&3]);
				mhline(globalbufplc,bx,((x2-x)>>2)<<16,0L,by,p+(x>>2));
				bx += bxinc;
				by += byinc;
				x++;
			}
			while (x <= xend)
			{
				koutp(0x3c5,pow2char[x&3]);
				mhlineskipmodify(globalbufplc,bx,((x2-x)>>2)<<16,0L,by,p+(x>>2));
				bx += bxinc;
				by += byinc;
				x++;
			}
		}
		else
		{
			koutp(0x3ce,4);
			x = x1;
			if (x <= xend)
			{
				koutp(0x3c5,pow2char[x&3]);
				koutp(0x3cf,x&3);
				thline(globalbufplc,bx,((x2-x)>>2)<<16,0L,by,p+(x>>2));
				bx += bxinc;
				by += byinc;
				x++;
			}
			while (x <= xend)
			{
				koutp(0x3c5,pow2char[x&3]);
				koutp(0x3cf,x&3);
				thlineskipmodify(globalbufplc,bx,((x2-x)>>2)<<16,0L,by,p+(x>>2));
				bx += bxinc;
				by += byinc;
				x++;
			}
			transarea += (x2 - x1);
		}
	}
	else
	{
#if (LIBVER_BUILDREV < 19960320L)
		p = ylookup[y]+x1+frameplace+viewoffset;
#else
		p = ylookup[y]+x1+frameoffset;
#endif
		if ((globalorientation&2) == 0)
			mhline(globalbufplc,bx,(x2-x1)<<16,0L,by,p);
		else
		{
			thline(globalbufplc,bx,(x2-x1)<<16,0L,by,p);
			transarea += (x2-x1);
		}
	}
#else // LIBVER_BUILDREV >= 19960427L
	if ((globalorientation&2) == 0)
		mhline(globalbufplc,bx,(x2-x1)<<16,0L,by,ylookup[y]+x1+frameoffset);
	else
	{
		thline(globalbufplc,bx,(x2-x1)<<16,0L,by,ylookup[y]+x1+frameoffset);
		transarea += (x2-x1);
	}
#endif
}
