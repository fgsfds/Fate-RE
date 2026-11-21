// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "../engine/BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
void *memcpy(void *destination, const void *source, unsigned int count);
#define MAXPLAYERS 16
extern long connectnum[MAXPLAYERS], myconnectnum;
extern short numplayers, socket, connecthead, connectpoint2[MAXPLAYERS], myconnectindex;
extern char compaddr[MAXPLAYERS][12];

netinitconnection (long newconnectnum, char *newcompaddr)
{
	long i, j, k, newindex, templong;
	char tempchar;

		//Check to see if connection number already initialized
	for(i=0;i<MAXPLAYERS;i++)
		if (connectnum[i] == newconnectnum) return(-1);

		//Find blank place to put new connection number
	newindex = 0;
	while (connectnum[newindex] != 0x7fffffff)
	{
		newindex++;
		if (newindex >= MAXPLAYERS) return(-1);  //Out of space! (more than 16 players)
	}

		//Insert connection number on connection number list
	numplayers++;
	connectnum[newindex] = newconnectnum;

		//Getinternetworkaddress
	memcpy((void *)&compaddr[newindex][0],(void *)newcompaddr,10);
	compaddr[newindex][10] = (socket&255);
	compaddr[newindex][11] = (socket>>8);

		//Sort connection numbers
	for(i=1;i<MAXPLAYERS;i++)
		for(j=0;j<i;j++)
			if (connectnum[i] < connectnum[j])
			{
				templong = connectnum[i], connectnum[i] = connectnum[j], connectnum[j] = templong;
				for(k=0;k<12;k++) tempchar = compaddr[i][k], compaddr[i][k] = compaddr[j][k], compaddr[j][k] = tempchar;
			}

		//Rebuild linked list, MAKING SURE that the linked list goes through
		//   the players in the same order on all computers!
	connecthead = 0;
	for(i=0;i<numplayers-1;i++) connectpoint2[i] = i+1;
	connectpoint2[numplayers-1] = -1;

	for(i=0;i<numplayers;i++)
		if (connectnum[i] == myconnectnum) myconnectindex = i;

	return(1);
}

/* Shared compilation preserves the receive routine's common return jump. */
#include "getpkt.c"
