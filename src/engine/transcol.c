// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
#define max(a,b) ((a)>(b)?(a):(b))
#define min(a,b) ((a)<(b)?(a):(b))
#define FP_OFF(p) ((long)(p))
extern char chainstat;
extern char *palookup[];
extern short uwall[], dwall[], startumost[], startdmost[], tilesizx[], tilesizy[], globalpicnum;
extern long xdimen, windowx1, windowy1, globalpal, globvis, globalshade;
extern long globalyscale, globalzd, globalhoriz, globalxpanning;
extern long swall[], lwall[], waloff[], ylookup[], viewoffset, chainplace, frameplace, transarea;
extern long getpalookup(long,long);
extern long tvlineasm1(long,long,long,long,long,long);
#pragma aux tvlineasm1 parm [eax][ebx][ecx][edx][esi][edi];
#pragma aux mulscale16 =\
	"imul ebx",\
	"shrd eax, edx, 16",\
	parm nomemory [eax][ebx]\
	modify exact [eax edx]\


transmaskvline (long x)
{
	long vplc, vinc, p, i, palookupoffs, shade, bufplc;
	short y1v, y2v;

	if ((x < 0) || (x >= xdimen)) return;

	y1v = max(uwall[x],startumost[x+windowx1]-windowy1);
	y2v = min(dwall[x],startdmost[x+windowx1]-windowy1);
	y2v--;
	if (y2v < y1v) return;

	palookupoffs = FP_OFF(palookup[globalpal]) + (getpalookup((long)mulscale16(swall[x],globvis),globalshade)<<8);

	vinc = swall[x]*globalyscale;
	vplc = globalzd + vinc*(y1v-globalhoriz+1);

	i = lwall[x]+globalxpanning;
	if (i >= tilesizx[globalpicnum]) i %= tilesizx[globalpicnum];
	bufplc = waloff[globalpicnum]+i*tilesizy[globalpicnum];

	if (chainstat != 0)
		p = ylookup[y1v]+((x+viewoffset)>>2)+chainplace;
	else
		p = ylookup[y1v]+x+frameplace+viewoffset;

	tvlineasm1(vinc,palookupoffs,y2v-y1v,vplc,bufplc,p);

	transarea += y2v-y1v;
}
