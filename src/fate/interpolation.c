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

setinterpolation(long *posptr)
{
	long i;

	if (numinterpolations >= MAXINTERPOLATIONS) return;
	for(i=numinterpolations-1;i>=0;i--)
		if (curipos[i] == posptr) return;
	curipos[numinterpolations] = posptr;
	oldipos[numinterpolations] = *posptr;
	numinterpolations++;
}

stopinterpolation(long *posptr)
{
	long i;

	for(i=numinterpolations-1;i>=startofdynamicinterpolations;i--)
		if (curipos[i] == posptr)
		{
			numinterpolations--;
			oldipos[i] = oldipos[numinterpolations];
			bakipos[i] = bakipos[numinterpolations];
			curipos[i] = curipos[numinterpolations];
		}
}

updateinterpolations()  //Stick at beginning of domovethings
{
	long i;

	for(i=numinterpolations-1;i>=0;i--) oldipos[i] = *curipos[i];
}
