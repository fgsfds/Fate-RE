// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// See ../engine/BUILDLIC.TXT. Modified from the pinned historical MULTI.C.
#include "ipxctx.c"

/* The original returns through initialize_ipx's five-pop epilogue. The binder
 * validates Watcom's identical local epilogue and rebinds two displacements.
 * Port I/O remains the historical one-instruction hardware boundary. */
#define COMBUFSIZ 16384
extern char comrateoption;
extern long comnum, comvect, comspeed, comescape, comreset, syncbufleng, outcnt;
extern volatile unsigned char *comtype, *comerror, *comresend, *incnt;
extern volatile short *inbufplc, *inbufend, *outbufplc, *outbufend, *comport;
extern void installbicomhandlers(void), _disable(void), _enable(void);
extern int inp(unsigned);
extern int koutp(), kinp();
#pragma aux koutp = "out dx, al" parm [edx] [eax];
#pragma aux kinp = "in al, dx" parm [edx];
int initialize_serial_network(void)
{
	long divisor, cnt;
	short *ptr;

	if ((comnum < 1) || (comnum > 4)) return(-1);
	comvect = ((((long)comrateoption)>>4)+0x8+2);
	installbicomhandlers();

	*incnt = 0; outcnt = 0;
	*inbufplc = 0; *inbufend = 0; *outbufplc = 0; *outbufend = 0;

	ptr = (short *)(0x400L+(long)((comnum-1)<<1));
	*comport = *ptr;
	if (*comport == 0)
	{
		switch(comnum)
		{
			case 1: *comport = 0x3f8; break;
			case 2: *comport = 0x2f8; break;
			case 3: *comport = 0x3e8; break;
			case 4: *comport = 0x2e8; break;
		}
		if ((inp((*comport)+5)&0x60) != 0x60) { *comport = 0; return(-1); }
	}
	if ((comspeed <= 0) || (comspeed > 115200)) return(-1);

	  // Baud-Setting,?,?,Parity O/E,Parity Off/On, Stop-1/2,Bits-5/6/7/8
	  // The programmed value below selects no parity, one stop bit, eight bits.

	_disable();
	koutp((*comport)+3,0x80);                  //enable latch registers
	divisor = 115200 / comspeed;
	koutp((*comport)+0,divisor&255);           //# = 115200 / bps
	koutp((*comport)+1,divisor>>8);
	koutp((*comport)+3,0x03);                  //0x03 = n,8,1

	koutp((*comport)+2,0x87);   //check for a 16550   0=1,64=4,128=8,192=14
	if ((kinp((*comport)+2)&0xf8) == 0xc0)
	{
		*comtype = 16;
	}
	else
	{
		*comtype = 1;
		koutp((*comport)+2,0);
	}
	cnt = *comtype;                        //Clear any junk already in FIFO
	while (((kinp((*comport)+5)&0x1) > 0) && (cnt > 0))
		{ kinp(*comport); cnt--; }

	koutp((*comport)+4,0x0b);             //setup for interrupts (modem control)
	koutp((*comport)+1,0);                //com interrupt disable
	koutp(0x21,kinp(0x21)&(255-(1<<(comvect&7))));          //Unmask vector
	kinp((*comport)+6);
	kinp((*comport)+5);
	kinp((*comport)+0);
	kinp((*comport)+2);
	koutp((*comport)+1,0x03);             //com interrupt enable
	koutp(0x20,0x20);

	comescape = 0; comreset = 0;
	*comerror = 0; *comresend = 0;
	_enable();

	syncbufleng = 0;

	return(0);
}
