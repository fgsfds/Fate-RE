// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// See ../engine/BUILDLIC.TXT. Adapted from the pinned MULTI.C sendpacket.
/* Target-linked storage contract: peer -1 or 0..15, history slots 0..3,
 * readable bufptr[0] even at length zero, and valid serial-ring indices.
 * Encoded IPX output must fit its 560-byte buffer. Guard rows overlap mapped
 * DS data (not separately allocated C objects), including omessnum[12..15]
 * as omessleng[-1]. Keep those physical aliases when modeling broadcasts.
 * Watcom uses unsigned char and 32-bit long for this translation unit. */
#define MAXPLAYERS 16
#define NETBACKPACKETS 4
#define MAXIPXSIZ 546
#define COMBUFSIZ 16384
#define ESC2 0x8f
#define updatecrc16(crc,dat) crc = (((crc<<8)&65535)^crctable[((((unsigned short)crc)>>8)&65535)^dat])
extern char multioption, comrateoption;
extern short myconnectindex, connecthead, connectpoint2[MAXPLAYERS];
extern long outbufindex[128], outcnt, crctable[256];
extern volatile unsigned char *outbuf;
extern volatile short *outbufend;
extern char *ecbput, *messout;
/* Broadcast history reads peer -1. Include its mapped guard row in each
 * backing object; the normal peer-zero address is one row into it. */
extern char netoutcnt_backing[MAXPLAYERS+1];
#define netoutcnt (netoutcnt_backing+1)
extern char omessout_backing[MAXPLAYERS+1][NETBACKPACKETS][MAXIPXSIZ];
#define omessout (omessout_backing+1)
extern short omessleng_backing[MAXPLAYERS+1][NETBACKPACKETS];
#define omessleng (omessleng_backing+1)
extern short omessconnectindex_backing[MAXPLAYERS+1][NETBACKPACKETS];
#define omessconnectindex (omessconnectindex_backing+1)
extern short omessnum_backing[MAXPLAYERS+1];
#define omessnum (omessnum_backing+1)
extern void comsend(char);
#pragma aux comsend modify exact [eax];
extern void startcom(void);
#pragma aux startcom modify exact [eax];
extern long getcrc(char *, short);
#pragma aux getcrc modify exact [eax edx];
extern void netsend(short, short);
#pragma aux netsend modify exact [eax edx];
void sendpacket(short, char *, short);
#pragma aux sendpacket modify exact [eax ebx edx];
void sendpacket (short otherconnectindex, char *bufptr, short messleng)
{
	long i, j, k, l;

	if (multioption <= 0) return;
	if ((long)multioption < 5)
	{
			//Allow initial incnt/outcnt syncing
		if (((long)bufptr[0] == 253) || ((long)bufptr[0] == 254)) outcnt = 0;

		outbufindex[outcnt] = *outbufend;

		comsend(((messleng&1)<<7)+outcnt);
		for(i=0;i<messleng;i++) comsend(bufptr[i]);
		if ((long)(unsigned char)(comrateoption&15) > 0)
		{
			i = getcrc(bufptr,messleng);
			updatecrc16(i,((messleng&1)<<7)+outcnt);
			comsend(i&255); comsend(i>>8);
		}
		outbuf[*outbufend] = ESC2, *outbufend = (((*outbufend)+1)&(COMBUFSIZ-1));  //Not raw

		startcom();
		outcnt = ((outcnt+1)&127);
	}
	else
	{
		i = 262144;       //Wait for last packet to be sent
		while ((i > 0) && (ecbput[8] != 0)) i--;

		messout[0] = myconnectindex; j = 1;

		if (((long)bufptr[0] >= 200) && ((long)bufptr[0] <= 255))
		{
				//Allow initial incnt/outcnt syncing
			for(i=0;i<MAXPLAYERS;i++) netoutcnt[i] = 0;
			messout[j++] = 0xfe;
			for(i=0;i<messleng;i++) messout[j++] = bufptr[i];
			netsend(otherconnectindex,j);
			return;
		}

			//Copy new packet into omess fifo
		if (otherconnectindex < 0)
		{
			for(k=connecthead;k>=0;k=connectpoint2[k])
				if (k != myconnectindex)
				{
					omessconnectindex[k][omessnum[k]] = -1;
					omessleng[k][omessnum[k]] = messleng;
					for(i=0;i<messleng;i++) omessout[k][omessnum[k]][i] = bufptr[i];
				}
		}
		else
		{
			omessconnectindex[otherconnectindex][omessnum[otherconnectindex]] = otherconnectindex;
			omessleng[otherconnectindex][omessnum[otherconnectindex]] = messleng;
			for(i=0;i<messleng;i++) omessout[otherconnectindex][omessnum[otherconnectindex]][i] = bufptr[i];
		}

			//Put last 4 packets into 1 big packet
		for(l=0;l<NETBACKPACKETS;l++)
		{
				//k = omess index
			k = ((omessnum[otherconnectindex]-l)&(NETBACKPACKETS-1));

			if (omessconnectindex[otherconnectindex][k] < 0)
			{
				messout[j++] = 255;
				for(i=connecthead;i>=0;i=connectpoint2[i])
					if (i != myconnectindex)
						messout[j++] = ((netoutcnt[i]-l)&255);
			}
			else
			{
				messout[j++] = otherconnectindex;
				messout[j++] = ((netoutcnt[otherconnectindex]-l)&255);
			}
			messout[j++] = (omessleng[otherconnectindex][k]&255);
			messout[j++] = ((omessleng[otherconnectindex][k]>>8)&255);
			for(i=0;i<omessleng[otherconnectindex][k];i++)
				messout[j++] = omessout[otherconnectindex][k][i];
		}

			//SEND!!!
		netsend(otherconnectindex,j);


			//Increment outcnt and omessnum counters
		if (otherconnectindex < 0)
		{
			for(i=connecthead;i>=0;i=connectpoint2[i])
				if (i != myconnectindex)
				{
					netoutcnt[i]++;
					omessnum[i] = ((omessnum[i]+1)&(NETBACKPACKETS-1));
				}
		}
		else
		{
			netoutcnt[otherconnectindex]++;
			omessnum[otherconnectindex] = ((omessnum[otherconnectindex]+1)&(NETBACKPACKETS-1));
		}
	}
}
