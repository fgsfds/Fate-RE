// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release
/* Build Engine collision routine, Ken Silverman.
 * Historical source reference: November 1996 ENGINE.C, clipinsideboxline.
 * See BUILDLIC.TXT; preserve original 32-bit signed arithmetic for Watcom.
 * C compiler probe: exactness is not established until object verification.
 */
int clipinsideboxline(long x, long y, long x1, long y1,
                     long x2, long y2, long walldist)
{
    long r;
    r = walldist << 1;
    x1 += walldist-x;
    x2 += walldist-x;
    if (x1 < 0 && x2 < 0) return 0;
    if (x1 >= r && x2 >= r) return 0;
    y1 += walldist-y;
    y2 += walldist-y;
    if (y1 < 0 && y2 < 0) return 0;
    if (y1 >= r && y2 >= r) return 0;
    x2 -= x1;
    y2 -= y1;
    if (x2*(walldist-y1) >= y2*(walldist-x1)) {
        if (x2 > 0) x2 *= -y1; else x2 *= r-y1;
        if (y2 > 0) y2 *= r-x1; else y2 *= -x1;
        return x2 < y2;
    }
    if (x2 > 0) x2 *= r-y1; else x2 *= -y1;
    if (y2 > 0) y2 *= -x1; else y2 *= r-x1;
    return (x2 >= y2) << 1;
}
