// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See ../engine/BUILDLIC.TXT for license info.
// Historical GAME.C animation step, with FATE's observed pre-step call.
#define TICSPERFRAME 3
#define min(a,b) ((a)<(b)?(a):(b))
#define max(a,b) ((a)>(b)?(a):(b))
extern long animatecnt;
extern long *animateptr[];
extern long animategoal[],animatevel[],animateacc[];
extern void stopinterpolation(long *);
extern void animation_prestep(void);

doanimations()
{
	long i, j;
    animation_prestep();

	for(i=animatecnt-1;i>=0;i--)
	{
		j = *animateptr[i];

		if (j < animategoal[i])
			j = min(j+animatevel[i]*TICSPERFRAME,animategoal[i]);
		else
			j = max(j-animatevel[i]*TICSPERFRAME,animategoal[i]);
		animatevel[i] += animateacc[i];

		*animateptr[i] = j;

		if (j == animategoal[i])
		{
			animatecnt--;
			if (i != animatecnt)
			{
				stopinterpolation(animateptr[i]);
				animateptr[i] = animateptr[animatecnt];
				animategoal[i] = animategoal[animatecnt];
				animatevel[i] = animatevel[animatecnt];
				animateacc[i] = animateacc[animatecnt];
			}
		}
	}
}
