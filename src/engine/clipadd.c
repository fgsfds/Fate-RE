// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
extern short clipnum, clipobjectval[];
extern long clipx1[], clipy1[], clipx2[], clipy2[];
addclipline(long dax1, long day1, long dax2, long day2, short daoval)
{
    clipx1[clipnum] = dax1; clipy1[clipnum] = day1;
    clipx2[clipnum] = dax2; clipy2[clipnum] = day2;
    clipobjectval[clipnum] = daoval;
    clipnum++;
}
