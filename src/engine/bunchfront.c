/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
/* Adapted from vanilla_duke3D SRC/ENGINE.C:766-782, revision
 * 05ba48edb2da5b3256736039b03a853e1ea0ceef. ABI-only pragma, no inline code. */
extern short bunchfirst[], bunchlast[], p2[];
extern long xb1[], xb2[];
extern int wallfront(long, long);
#pragma aux wallfront modify exact [eax edx];

int bunchfront(long b1, long b2)
{
    long x1b1, x2b1, x1b2, x2b2, b1f, b2f, i;

    b1f = bunchfirst[b1]; x1b1 = xb1[b1f]; x2b2 = xb2[bunchlast[b2]] + 1;
    if (x1b1 >= x2b2)
        return -1;
    b2f = bunchfirst[b2]; x1b2 = xb1[b2f]; x2b1 = xb2[bunchlast[b1]] + 1;
    if (x1b2 >= x2b1)
        return -1;

    if (x1b1 >= x1b2) {
        for (i = b2f; xb2[i] < x1b1; i = p2[i])
            ;
        return wallfront(b1f, i);
    }
    for (i = b1f; xb2[i] < x1b2; i = p2[i])
        ;
    return wallfront(i, b2f);
}
