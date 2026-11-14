// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
extern long rx1[], ry1[], rx2[], ry2[];

#pragma aux scale =\
	"imul ebx",\
	"idiv ecx",\
	parm nomemory [eax][ebx][ecx]\
	modify exact [eax edx]\

clippoly4(long cx1, long cy1, long cx2, long cy2)
{
	long n, nn, z, zz, x, x1, x2, y, y1, y2, t;

	nn = 0; z = 0;
	do
	{
		zz = ((z+1)&3);
		x1 = rx1[z]; x2 = rx1[zz]-x1;

		if ((cx1 <= x1) && (x1 <= cx2))
			rx2[nn] = x1, ry2[nn] = ry1[z], nn++;

		if (x2 <= 0) x = cx2; else x = cx1;
		t = x-x1;
		if (((t-x2)^t) < 0)
			rx2[nn] = x, ry2[nn] = ry1[z]+scale(t,ry1[zz]-ry1[z],x2), nn++;

		if (x2 <= 0) x = cx1; else x = cx2;
		t = x-x1;
		if (((t-x2)^t) < 0)
			rx2[nn] = x, ry2[nn] = ry1[z]+scale(t,ry1[zz]-ry1[z],x2), nn++;

		z = zz;
	} while (z != 0);
	if (nn < 3) return(0);

	n = 0; z = 0;
	do
	{
		zz = z+1; if (zz == nn) zz = 0;
		y1 = ry2[z]; y2 = ry2[zz]-y1;

		if ((cy1 <= y1) && (y1 <= cy2))
			ry1[n] = y1, rx1[n] = rx2[z], n++;

		if (y2 <= 0) y = cy2; else y = cy1;
		t = y-y1;
		if (((t-y2)^t) < 0)
			ry1[n] = y, rx1[n] = rx2[z]+scale(t,rx2[zz]-rx2[z],y2), n++;

		if (y2 <= 0) y = cy1; else y = cy2;
		t = y-y1;
		if (((t-y2)^t) < 0)
			ry1[n] = y, rx1[n] = rx2[z]+scale(t,rx2[zz]-rx2[z],y2), n++;

		z = zz;
	} while (z != 0);
	return(n);
}
