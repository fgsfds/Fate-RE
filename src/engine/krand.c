// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
extern long randomseed;
int krand(void) { randomseed = randomseed*27584621+1; return ((unsigned long)randomseed)>>16; }
