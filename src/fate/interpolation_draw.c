// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See ../engine/BUILDLIC.TXT for license info.
// Historical GAME.C interpolation helpers with standalone declarations.
#define MAXINTERPOLATIONS 1024
extern long numinterpolations, startofdynamicinterpolations, smoothratio;
extern long *curipos[];
extern long oldipos[], bakipos[];
#pragma aux mulscale16 =\
    "imul ebx",\
    "shrd eax, edx, 16",\
    parm nomemory [eax][ebx]\
    modify exact [eax edx]

dointerpolations()       //Stick at beginning of drawscreen
{
	long i, j, odelta, ndelta;

	ndelta = 0; j = 0;
	for(i=numinterpolations-1;i>=0;i--)
	{
		bakipos[i] = *curipos[i];
		odelta = ndelta; ndelta = (*curipos[i])-oldipos[i];
		if (odelta != ndelta) j = mulscale16(ndelta,smoothratio);
		*curipos[i] = oldipos[i]+j;
	}
}
