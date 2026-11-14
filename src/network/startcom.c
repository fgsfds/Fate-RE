// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "../engine/BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
#define COMBUFSIZ 16384
#define ESC1 0x83
#define ESC2 0x8f
extern volatile short *comport, *outbufplc, *outbufend;
extern volatile unsigned char *comresend, *comerror, *incnt, *outbuf;
#pragma aux koutp = "out dx, al", parm [edx][eax]
#pragma aux kinp = "in al, dx", parm [edx]

startcom()
{
	if ((kinp((*comport)+5)&0x40) == 0) return;

	if (*comresend != 0)
	{
		if ((long)*comresend == 2) koutp(*comport,ESC1);
		if ((long)*comresend == 1) koutp(*comport,ESC2);
		*comresend = (*comresend) - 1;
	}
	else if (*comerror != 0)
	{
		if ((long)*comerror == 2) koutp(*comport,ESC1);
		if ((long)*comerror == 1) koutp(*comport,*incnt);
		*comerror = (*comerror) - 1;
	}
	else if (*outbufplc != *outbufend)
	{
		koutp(*comport,(long)outbuf[*outbufplc]);
		*outbufplc = (((*outbufplc)+1)&(COMBUFSIZ-1));
	}
}
