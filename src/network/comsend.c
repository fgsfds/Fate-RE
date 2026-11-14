// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "../engine/BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
#define COMBUFSIZ 16384
#define ESC1 0x83
#define ESC2 0x8f
extern volatile unsigned char *outbuf;
extern volatile short *outbufend;

comsend(char ch)
{
	if ((long)ch == ESC1)
	{
		outbuf[*outbufend] = ESC1; *outbufend = (((*outbufend)+1)&(COMBUFSIZ-1));
		ch = 128;
	}
	else if ((long)ch == ESC2)
	{
		outbuf[*outbufend] = ESC1; *outbufend = (((*outbufend)+1)&(COMBUFSIZ-1));
		ch = 129;
	}
	outbuf[*outbufend] = ch; *outbufend = (((*outbufend)+1)&(COMBUFSIZ-1));
}
