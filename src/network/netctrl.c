// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// See ../engine/BUILDLIC.TXT. Adapted from MULTI.C processreservedmessage.
/* Included in netinitconnection's translation unit for common-return reuse.
 * Buffers hold at least 225 bytes; type 254 IPX lists contain complete 14-byte
 * records. Player chains/indices are valid, and removal leaves the local peer.
 * Peer IDs use Watcom's signed 32-bit bit-pattern conversion: only the high
 * byte is shifted unsigned, so every signed addition remains representable.
 * These callees preserve GS as verified in the pinned code. */
#pragma aux netinitconnection modify exact [eax edx];
extern void sendpacket(short, char *, short);
#pragma aux sendpacket modify exact [eax ebx edx];
extern int netuninitconnection(short);
#pragma aux netuninitconnection modify exact [eax];
void processreservedmessage(short tempbufleng, char *datempbuf)
{
	long i, j, k, daotherconnectnum, templong;

	switch(datempbuf[0])
	{
		//[253] (login, if myconnectnum's lowest, then respond with packet type 254)
		case 253:
			if ((long)multioption < 5)
			{
				otherconnectnum = ((long)datempbuf[1])+(((long)datempbuf[2])<<8)+(((long)datempbuf[3])<<16)+((long)(((unsigned long)datempbuf[4])<<24));

				datempbuf[0] = 254;
				sendpacket(-1,datempbuf,1);

				myconnectindex = 0;
				connecthead = 0; connectpoint2[0] = 1; connectpoint2[1] = -1;
				numplayers = 2;
			}
			else if ((long)multioption >= 5)
			{
				daotherconnectnum = ((long)datempbuf[1])+((long)(datempbuf[2]<<8))+((long)(datempbuf[3]<<16))+((long)(((unsigned long)datempbuf[4])<<24));
				if (daotherconnectnum != myconnectnum)
				{
					netinitconnection(daotherconnectnum,&datempbuf[5]);

					if ((myconnectindex == connecthead) || ((connectnum[connecthead] == daotherconnectnum) && (myconnectindex == connectpoint2[connecthead])))
					{
						datempbuf[0] = 254;
						j = 1;
						for(i=0;i<MAXPLAYERS;i++)
							if ((connectnum[i] != 0x7fffffff) && (connectnum[i] != daotherconnectnum))
							{
								datempbuf[j++] = (connectnum[i]&255);
								datempbuf[j++] = ((connectnum[i]>>8)&255);
								datempbuf[j++] = ((connectnum[i]>>16)&255);
								datempbuf[j++] = ((connectnum[i]>>24)&255);

								for(k=0;k<10;k++)
									datempbuf[j++] = compaddr[i][k];
							}

							//While this doesn't have to be a broadcast, sending
							//this info again makes good error correction
						sendpacket(-1,datempbuf,j);

						for(i=0;i<MAXPLAYERS;i++)
							if (connectnum[i] == daotherconnectnum)
							{
								sendpacket((short)i,datempbuf,j);
								break;
							}
					}
				}
			}
			break;
		case 254:  //[254][connectnum][connectnum]...(Packet type 253 response)
			if ((long)multioption < 5)
			{
				myconnectindex = 1;
				connecthead = 0; connectpoint2[0] = 1; connectpoint2[1] = -1;
				numplayers = 2;
			}
			else if ((long)multioption >= 5)
			{
				j = 1;
				while (j < tempbufleng)
				{
					templong = ((long)datempbuf[j])+((long)(datempbuf[j+1]<<8))+((long)(datempbuf[j+2]<<16))+((long)(((unsigned long)datempbuf[j+3])<<24));
					netinitconnection(templong,&datempbuf[j+4]);
					j += 14;
				}
			}
			break;
		case 255:
			if ((long)multioption >= 5)
				netuninitconnection(datempbuf[1]);
			break;
	}
}
