/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
/* Adapted from vanilla_duke3D SRC/ENGINE.C, revision
 * 05ba48edb2da5b3256736039b03a853e1ea0ceef, lines 2793-2828.
 * All pragmas below describe ABI only; this routine has no inline instructions.
 */
extern short tilesizx[], tilesizy[];
extern long waloff[];
extern void loadtile(short);
#pragma aux loadtile parm [eax] modify exact [eax];

void copytilepiece(long, long, long, long, long, long, long, long);
#pragma aux copytilepiece parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];

void copytilepiece(long tilenume1, long sx1, long sy1, long xsiz, long ysiz,
                  long tilenume2, long sx2, long sy2)
{
    char *ptr1, *ptr2, dat;
    long xsiz1, ysiz1, xsiz2, ysiz2, i, j, x1, y1, x2, y2;

    xsiz1 = tilesizx[tilenume1]; ysiz1 = tilesizy[tilenume1];
    xsiz2 = tilesizx[tilenume2]; ysiz2 = tilesizy[tilenume2];
    if ((xsiz1 > 0) && (ysiz1 > 0) && (xsiz2 > 0) && (ysiz2 > 0)) {
        if (waloff[tilenume1] == 0)
            loadtile(tilenume1);
        if (waloff[tilenume2] == 0)
            loadtile(tilenume2);

        x1 = sx1;
        for (i = 0; i < xsiz; i++) {
            y1 = sy1;
            for (j = 0; j < ysiz; j++) {
                x2 = sx2 + i;
                y2 = sy2 + j;
                if ((x2 >= 0) && (y2 >= 0) && (x2 < xsiz2) && (y2 < ysiz2)) {
                    ptr1 = (char *)(waloff[tilenume1] + x1 * ysiz1 + y1);
                    ptr2 = (char *)(waloff[tilenume2] + x2 * ysiz2 + y2);
                    dat = *ptr1;
                    /* Keep byte storage but force unsigned, full-width compare.
                     * A byte-only compare changes both code size and branches. */
                    if ((unsigned long)(unsigned char)dat != 255)
                        *ptr2 = *ptr1;
                }
                y1++;
                if (y1 >= ysiz1)
                    y1 = 0;
            }
            x1++;
            if (x1 >= xsiz1)
                x1 = 0;
        }
    }
}
