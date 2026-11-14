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

restoreinterpolations()  //Stick at end of drawscreen
{
	long i;

	for(i=numinterpolations-1;i>=0;i--) *curipos[i] = bakipos[i];
}
