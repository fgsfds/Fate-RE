/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern long clipx1[], clipx2[], clipy1[], clipy2[];

extern void finish_keepaway(void);
#pragma aux finish_keepaway aborts modify exact [];
extern long clip_direction(long value);
#pragma aux clip_direction = "add ebx,ebx" "sbb eax,eax" "cmp eax,ebx" "adc al,0" parm [ebx] value [eax] modify exact [eax ebx];
extern long clip_absolute(long value);
#pragma aux clip_absolute = "test eax,eax" "jns keepaway_absolute" "neg eax" "keepaway_absolute:" parm [eax] value [eax] modify exact [eax];

void keepaway(long *x, long *y, short line)
{
    long dx, dy, ox, oy, x1, y1;
    unsigned char first;

    /* Compute coordinate and cross-product bits modulo 2^32.
     * Watcom interprets those bits as signed for the side test. */
    x1 = clipx1[line];
    dx = (unsigned long)clipx2[line] - (unsigned long)x1;
    y1 = clipy1[line];
    dy = (unsigned long)clipy2[line] - (unsigned long)y1;
    ox = clip_direction(0UL - (unsigned long)dy);
    oy = clip_direction(dx);
    first = clip_absolute(dx) <= clip_absolute(dy);
    for (;;) {
        if ((long)((unsigned long)dx * ((unsigned long)*y - (unsigned long)y1)) >
            (long)(((unsigned long)*x - (unsigned long)x1) * (unsigned long)dy))
            finish_keepaway();
        if (first == 0)
            *x = (unsigned long)*x + (unsigned long)ox;
        else
            *y = (unsigned long)*y + (unsigned long)oy;
        first ^= 1;
    }
}
