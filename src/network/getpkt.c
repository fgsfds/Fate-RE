// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// See ../engine/BUILDLIC.TXT. Adapted from the pinned MULTI.C getpacket.
/* Included after netinitconnection so Watcom can reuse its exact return tail.
 * Contract: bounded serial/IPX framing, ring indices 0..16383, syncbufleng
 * 0..546, comreset 0..2, bounded escape counts and a 546-byte output buffer.
 * IPX broadcast sender must differ from local, and the player chain must
 * contain local; otherwise the historical parser reads an uninitialized j.
 * Two prefix bytes back truncated serial CRC reads; they overlap getmess's
 * final bytes in the target-linked DS image. Watcom plain char is unsigned. */
#define MAXPLAYERS 16
#define NETBACKPACKETS 4
#define MAXIPXSIZ 546
#define COMBUFSIZ 16384
#define ESC1 0x83
#define ESC2 0x8f
#define updatecrc16(crc,dat) crc = (((((unsigned long)(unsigned short)crc)<<8)&65535)^crctable[((((unsigned short)crc)>>8)&65535)^dat])
extern char multioption, comrateoption, syncstate;
extern short myconnectindex, connecthead, connectpoint2[MAXPLAYERS];
extern long comescape, comreset, syncbufleng, outcnt, outbufindex[128];
extern long myconnectnum, otherconnectnum, crctable[256];
extern volatile unsigned char *inbuf, *comresend, *comerror, *incnt;
extern volatile short *inbufplc, *inbufend, *outbufplc;
extern char syncbuf_backing[MAXIPXSIZ+2];
#define syncbuf (syncbuf_backing+2)
extern char getmess[MAXIPXSIZ], netincnt[MAXPLAYERS];
extern volatile char *netinbuf;
extern volatile short *netinbufplc, *netinbufend;
extern void startcom(void);
#pragma aux startcom modify exact [eax];
extern long getcrc(char *, short);
#pragma aux getcrc modify exact [eax edx];
extern void processreservedmessage(short, char *);
#pragma aux processreservedmessage modify exact [eax edx];
short getpacket(short *, char *);
#pragma aux getpacket modify exact [eax edx];
short getpacket (short *otherconnectindex, char *bufptr)
{
	char toindex, bad, totbad;
	short i, j, k, messleng, submessleng;

	if (multioption <= 0) return(0);
	if ((long)multioption < 5)
	{
		*otherconnectindex = (myconnectindex^1);

		bad = 0;
		while (*inbufplc != *inbufend)
		{
			i = (short)inbuf[*inbufplc], *inbufplc = (((*inbufplc)+1)&(COMBUFSIZ-1));

			if ((long)i != ESC2)
			{
				if ((long)i == ESC1) { comescape++; continue; }
				if (comescape != 0)
				{
					comescape--;
					if (((long)i < 128) && (*comresend == 0) && (((i-outcnt)&127) > 4))
					{
						*comresend = 2;
						*outbufplc = outbufindex[i];
						startcom();
						continue;
					}
					if (syncbufleng < MAXIPXSIZ)
					{
						if ((long)i == 128) { syncbuf[syncbufleng++] = ESC1; continue; }
						if ((long)i == 129) { syncbuf[syncbufleng++] = ESC2; continue; }
					}
				}
				if (syncbufleng < MAXIPXSIZ) syncbuf[syncbufleng++] = i;
				continue;
			}

			if (comescape != 0)
			{
				comescape = 0; comreset = 0; *comerror = 0;
				syncbufleng = 0;
				continue;
			}

			messleng = syncbufleng-3+(((long)(unsigned char)(comrateoption&15)==0)<<1);
			if ((syncbuf[0]&127) != *incnt)
			{
				bad |= 1;      //Packetcnt error
				if (((long)*incnt == 1) && ((long)syncbuf[1] == 254))  //Prevent 2 Masters!
					myconnectindex = (myconnectnum<otherconnectnum);
			}
			if (((syncbuf[0]&128)>>7) != (messleng&1)) bad |= 2;   //messleng error
			for(i=0;i<messleng;i++) bufptr[i] = syncbuf[i+1];
			if ((long)(unsigned char)(comrateoption&15) > 0)
			{
				i = getcrc(bufptr,messleng);
				updatecrc16(i,syncbuf[0]);
				if (((unsigned short)i) != ((long)syncbuf[syncbufleng-2])+((long)syncbuf[syncbufleng-1]<<8))
					bad |= 2;   //CRC error
			}

			syncbufleng = 0;
			if (bad != 0)
			{
					//Don't send reset again if outbufplc is not before incnt!
				if (((long)bad == 1) && ((((syncbuf[0]&127)-(*incnt))&127) >= 124))
				{
					bad = 0;
					continue;
				}

				bad = 0;
				if (comreset != 0) comreset--;
				if (((*comerror)|comreset) == 0)
				{
					*comerror = 2; comreset = 2;
					startcom();
				}
				continue;
			}

			*incnt = (((*incnt)+1)&127);
			if ((messleng > 0) && ((long)bufptr[0] >= 200))  //200-255 are messages for engine's use only
				processreservedmessage(messleng,bufptr);

			comescape = 0; comreset = 0; *comerror = 0;
			return(messleng);
		}
		return(0);
	}
	else
	{
		if (*netinbufplc == *netinbufend) return(0);

		messleng = (short)netinbuf[*netinbufplc] + (((short)netinbuf[((*netinbufplc)+1)&(COMBUFSIZ-1)])<<8);
		for(i=0;i<messleng;i++)
			getmess[i] = netinbuf[((*netinbufplc)+i+2)&(COMBUFSIZ-1)];

		k = 0; *otherconnectindex = getmess[k++];

		for(totbad=0;(long)totbad<NETBACKPACKETS;totbad++)   //Number of sub-packets per packet
		{
			toindex = getmess[k++];
			if ((long)toindex == 0xfe)
			{
				netincnt[*otherconnectindex] = 0;  // (>= 200) && ( <= 254)
				submessleng = messleng-2;          // Submessleng not necessary
			}
			else
			{
				if ((long)toindex == 0xff)
				{
					for(i=connecthead;i>=0;i=connectpoint2[i])
						if (i != *otherconnectindex)
						{
							if (i == myconnectindex) j = getmess[k];
							k++;
						}
				}
				else
					j = getmess[k++];

				if (j != netincnt[*otherconnectindex])
				{
					submessleng = (short)getmess[k]+(((short)getmess[k+1])<<8);
					k += submessleng+2;
					continue;
				}
				netincnt[*otherconnectindex]++;

				submessleng = (short)getmess[k]+(((short)getmess[k+1])<<8); k += 2;
			}
			for(i=0;i<submessleng;i++) bufptr[i] = getmess[k++];

			if (totbad == 0)
			{
					//Increment inbufplc only if first sub-message is read
				*netinbufplc = (((*netinbufplc)+messleng+2)&(COMBUFSIZ-1));
				if ((submessleng > 0) && ((long)bufptr[0] >= 200)) //200-255 are messages for engine's use only
				{
					if ((long)bufptr[0] >= 253)
					{
						processreservedmessage(submessleng,bufptr);
						if (((long)bufptr[0] == 253) || ((long)bufptr[0] == 254)) return(0);
					}
					return(submessleng);
				}
			}
			if (*otherconnectindex == myconnectindex) return(0);
			return(submessleng);   //Got good packet
		}

		syncstate++;   //DON'T WANT TO GET HERE!!!
			//Increment inbufplc to make it not continuously screw up!
		*netinbufplc = (((*netinbufplc)+messleng+2)&(COMBUFSIZ-1));
	}
	return(0);
}
