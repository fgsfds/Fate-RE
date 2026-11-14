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

extern long comtemp, comi;
extern volatile unsigned char *comtype, *inbuf;
extern volatile short *inbufend;

void interrupt far comhandler(void)
{
	do
	{
		comtemp = (kinp((*comport)+2)&7);
		if (comtemp == 2)
		{
			for(comi=(*comtype);comi>0;comi--)
			{
				if (*comresend != 0)
				{
					if ((long)*comresend == 2) koutp(*comport,ESC1);
					if ((long)*comresend == 1) koutp(*comport,ESC2);
					*comresend = (*comresend) - 1;
					continue;
				}
				if (*comerror != 0)
				{
					if ((long)*comerror == 2) koutp(*comport,ESC1);
					if ((long)*comerror == 1) koutp(*comport,*incnt);
					*comerror = (*comerror) - 1;
					continue;
				}
				if (*outbufplc != *outbufend)
				{
					koutp(*comport,(long)outbuf[*outbufplc]);
					*outbufplc = (((*outbufplc)+1)&(COMBUFSIZ-1));
					continue;
				}
				break;
			}
		}
		else if (comtemp == 4)
		{
			do
			{
				//comtemp = (rand()&255);
				//if (comtemp == 17)
				//   inbuf[*inbufend] = 17;
				//else
					inbuf[*inbufend] = (char)kinp(*comport);

				//if (comtemp != 11) *inbufend = (((*inbufend)+1)&(COMBUFSIZ-1));
				//if (comtemp == 24)
				//{
				//   inbuf[*inbufend] = 17;
					*inbufend = (((*inbufend)+1)&(COMBUFSIZ-1));
				//}
				//comtemp = 4;

			} while (((long)*comtype == 16) && ((kinp((*comport)+5)&1) > 0));
		}
	}
	while ((comtemp&1) == 0);
	koutp(0x20,0x20);
}
