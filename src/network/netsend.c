// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// See ../engine/BUILDLIC.TXT. Adapted from the pinned MULTI.C netsend.
/* Ordinary byte accesses retain Watcom's conservative alias reloads. */
extern char *ecbput, *ipxout, *messout;
extern char compaddr[][12];
extern short socket;
extern long rmoffset32, rmsegment16;
extern void *memcpy(void *, const void *, unsigned);
#pragma aux memcpy modify exact [eax];
extern int simulate_network_interrupt(char, long, long, long, long, long, long);
#pragma aux simulate_network_interrupt modify exact [eax ebx ecx edx];
void netsend(short, short);
#pragma aux netsend parm [eax] [edx] modify exact [eax edx];
void netsend (short otherconnectindex, short messleng)
{
	long i;

	i = 32767;
	while ((ecbput[8] != 0) && (i > 0)) i--;
	for(i=0;i<30;i++) ipxout[i] = 0;
	for(i=0;i<48;i++) ecbput[i] = 0;
	ipxout[5] = 4;
	if (otherconnectindex < 0)
	{
		memcpy((void *)&ipxout[6],(void *)&compaddr[0][0],4);
		ipxout[10] = 0xff, ipxout[11] = 0xff, ipxout[12] = 0xff;
		ipxout[13] = 0xff, ipxout[14] = 0xff, ipxout[15] = 0xff;
		ipxout[16] = (socket&255), ipxout[17] = (socket>>8);
	}
	else
	{
		memcpy((void *)&ipxout[6],(void *)&compaddr[otherconnectindex][0],12);
	}

	ecbput[10] = (socket&255), ecbput[11] = (socket>>8);
	if (otherconnectindex < 0)
	{
		ecbput[28] = 0xff, ecbput[29] = 0xff, ecbput[30] = 0xff;
		ecbput[31] = 0xff, ecbput[32] = 0xff, ecbput[33] = 0xff;
	}
	else
	{
		memcpy((void *)&ecbput[28],(void *)&compaddr[otherconnectindex][4],6);
	}

	/* Encode real-mode offsets modulo 32 bits, then select their low bytes.
         * Watcom's signed conversion/shift preserves the original SAR opcode. */
	ecbput[34] = 2, ecbput[35] = 0;
	ecbput[36] = (char)(((long)((unsigned long)ipxout-(unsigned long)rmoffset32))&255), ecbput[37] = (char)(((long)((unsigned long)ipxout-(unsigned long)rmoffset32))>>8);
	ecbput[38] = (char)(rmsegment16&255), ecbput[39] = (char)(rmsegment16>>8);
	ecbput[40] = 30, ecbput[41] = 0;
	ecbput[42] = (char)(((long)((unsigned long)messout-(unsigned long)rmoffset32))&255), ecbput[43] = (char)(((long)((unsigned long)messout-(unsigned long)rmoffset32))>>8);
	ecbput[44] = (char)(rmsegment16&255), ecbput[45] = (char)(rmsegment16>>8);
	ecbput[46] = (char)(messleng&255), ecbput[47] = (char)(messleng>>8);
	simulate_network_interrupt(0x7a,0L,(long)0x3,0L,0L,(long)ecbput,0L);               //Sendpacket
}
