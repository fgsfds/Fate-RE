// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "../engine/BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
#define MAXPLAYERS 16
extern long connectnum[MAXPLAYERS];
extern short numplayers, connecthead, connectpoint2[MAXPLAYERS];

netuninitconnection(short goneindex)
{
	long i, j, k;

	connectnum[goneindex] = 0x7fffffff; numplayers--;

	j = 0;
	for(i=0;i<MAXPLAYERS;i++)
		if (connectnum[i] != 0x7fffffff)
		{
			if (j == 0) connecthead = i; else connectpoint2[k] = i;
			k = i; j++;
		}
	connectpoint2[k] = -1;
}
