/* Unlinked historical MULTI.C compilation context. Only serialin.c's serial
 * initializer is selected by bind_serial_init.py. This real adjacent routine
 * lets Watcom share its five-pop return; it is NOT an accepted IPX restoration.
 * Keep the segment-preserving discovery wrapper out of the production image.
 */
// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// See ../engine/BUILDLIC.TXT. Modified from the pinned historical MULTI.C.
// Included before initialize_serial_network for compiler tail sharing.
#define NETCODEBYTES 384
#define COMBUFSIZ 16384
#define MAXPLAYERS 16
#define NETBACKPACKETS 4
#define MAXIPXSIZ 546
extern short socket;
extern long rmoffset32, rmsegment16, mypriority, myconnectnum;
extern char mycompaddr[12], rmnetbuffer[NETCODEBYTES], ipx_allocation_error[];
extern char *ecbget, *ecbput, *ipxin, *ipxout, *messin, *messout;
extern char *tempinbuf, *tempoutbuf, *rmnethandler, *netinbuf;
extern short *netinbufplc, *netinbufend;
extern char netincnt[MAXPLAYERS], netoutcnt_backing[MAXPLAYERS+1];
#define netoutcnt (netoutcnt_backing+1)
extern short omessnum_backing[MAXPLAYERS+1];
#define omessnum (omessnum_backing+1)
extern short omessleng_backing[MAXPLAYERS+1][NETBACKPACKETS];
#define omessleng (omessleng_backing+1)
extern short omessconnectindex_backing[MAXPLAYERS+1][NETBACKPACKETS];
#define omessconnectindex (omessconnectindex_backing+1)
extern long convalloc32(long);
#pragma aux convalloc32 modify exact [eax];
extern void *memcpy(void *, const void *, unsigned);
#pragma aux memcpy modify exact [eax ebx edx];
extern int printf(const char *, ...);
#pragma aux printf parm caller [] modify exact [eax];
extern int netinitconnection(long, char *);
#pragma aux netinitconnection modify exact [eax edx];
extern int simulate_network_interrupt(char, long, long, long, long, long, long);
#pragma aux simulate_network_interrupt modify exact [eax ebx ecx edx];

/* This unlinked context preserves ES around discovery for the flat model. */
extern long ipx_detect(long, long, long, long);
#pragma aux ipx_detect = "push es" "int 2fh" "pop es" parm [eax] [ebx] [ecx] [edx] value [eax] modify exact [eax edi];
extern long ipx_socket(long, long, long, long);
#pragma aux ipx_socket = "int 7ah" parm [eax] [ebx] [ecx] [edx] value [eax] modify exact [eax ebx ecx edx];
int ipx_compilation_context(void);
/* EDI is a real interrupt output. This function is never linked. */
#pragma aux ipx_compilation_context modify exact [eax edi];
int ipx_compilation_context(void)
{
    long i, j;

    if (*(unsigned long *)0x1e8UL == 0) return(-1);
    if ((ipx_detect(0x7a00L,0L,0L,0L)&255) != 255) return(-1);

    if ((rmoffset32 = convalloc32(1380L+NETCODEBYTES+COMBUFSIZ)) == 0)
        printf(ipx_allocation_error);
    rmsegment16 = (rmoffset32>>4);

    i = rmoffset32;
    ecbget = (char *)i; i += 48;
    ecbput = (char *)i; i += 48;
    ipxin = (char *)i; i += 32;
    ipxout = (char *)i; i += 32;
    messin = (char *)i; i += 560;
    messout = (char *)i; i += 560;
    tempinbuf = (char *)i; i += 16;
    tempoutbuf = (char *)i; i += 80;
    rmnethandler = (char *)i; i += NETCODEBYTES;
    netinbufplc = (short *)i; i += 2;
    netinbufend = (short *)i; i += 2;
    netinbuf = (char *)i; i += COMBUFSIZ;
    memcpy(rmnethandler,rmnetbuffer,NETCODEBYTES);

    ipx_socket(0L,1L,0L,(long)socket);
    if ((ipx_socket(0xffL,0L,0L,(long)socket)&255) != 0) return(-2);

    simulate_network_interrupt(0x7a,0L,9L,0L,0L,(long)tempoutbuf,0L);
    memcpy(mycompaddr,tempoutbuf,10);
    mycompaddr[10] = (socket&255);
    mycompaddr[11] = (socket>>8);
    myconnectnum = ((long)tempoutbuf[6])+(((long)tempoutbuf[7])<<8)
        +(((long)(tempoutbuf[8]^tempoutbuf[9]))<<16)
        +(long)((unsigned long)mypriority<<24);
    netinitconnection(myconnectnum,mycompaddr);

    ecbget[8] = 1; ecbput[8] = 0;
    *netinbufplc = 0; *netinbufend = 0;
    for(i=MAXPLAYERS-1;i>=0;i--) netincnt[i] = 0, netoutcnt[i] = 0;
    for(i=0;i<MAXPLAYERS;i++)
    {
        omessnum[i] = 0;
        for(j=NETBACKPACKETS-1;j>=0;j--)
        {
            omessleng[i][j] = 0;
            omessconnectindex[i][j] = 0;
        }
    }
    for(i=0;i<30;i++) ipxin[i] = 0;
    for(i=0;i<48;i++) ecbget[i] = 0;
    ecbget[4] = (char)(((long)((unsigned long)rmnethandler-(unsigned long)rmoffset32))&255);
    ecbget[5] = (char)(((long)((unsigned long)rmnethandler-(unsigned long)rmoffset32))>>8);
    ecbget[6] = (char)(rmsegment16&255); ecbget[7] = (char)(rmsegment16>>8);
    ecbget[10] = (socket&255); ecbget[11] = (socket>>8);
    ecbget[34] = 2; ecbget[35] = 0;
    ecbget[36] = (char)(((long)((unsigned long)ipxin-(unsigned long)rmoffset32))&255);
    ecbget[37] = (char)(((long)((unsigned long)ipxin-(unsigned long)rmoffset32))>>8);
    ecbget[38] = (char)(rmsegment16&255); ecbget[39] = (char)(rmsegment16>>8);
    ecbget[40] = 30; ecbget[41] = 0;
    ecbget[42] = (char)(((long)((unsigned long)messin-(unsigned long)rmoffset32))&255);
    ecbget[43] = (char)(((long)((unsigned long)messin-(unsigned long)rmoffset32))>>8);
    ecbget[44] = (char)(rmsegment16&255); ecbget[45] = (char)(rmsegment16>>8);
    ecbget[46] = (MAXIPXSIZ&255); ecbget[47] = (MAXIPXSIZ>>8);
    simulate_network_interrupt(0x7a,0L,4L,0L,0L,(long)ecbget,0L);
    return(0);
}

