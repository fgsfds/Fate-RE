// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See ../engine/BUILDLIC.TXT for license info.
// Adapted from historical 19961013 GAME.C: declarations and bound symbol names.
#define MAXANIMATES 512
extern long animatecnt;
extern long *animateptr[];
extern long animategoal[], animatevel[], animateacc[];
extern void setinterpolation(long *);

getanimationgoal(long animptr)
{
    long i;
    for(i=animatecnt-1;i>=0;i--)
        if (animptr == animateptr[i]) return(i);
    return(-1);
}

setanimation(long *animptr, long thegoal, long thevel, long theacc)
{
    long i, j;
    if (animatecnt >= MAXANIMATES) return(-1);
    j = animatecnt;
    for(i=animatecnt-1;i>=0;i--)
        if (animptr == animateptr[i])
            { j = i; break; }
    setinterpolation(animptr);
    animateptr[j] = animptr;
    animategoal[j] = thegoal;
    animatevel[j] = thevel;
    animateacc[j] = theacc;
    if (j == animatecnt) animatecnt++;
    return(j);
}
