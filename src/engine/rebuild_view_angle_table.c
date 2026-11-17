/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern short radarang[], column_angles[];
extern long view_width_reciprocal;
extern long mulscale16(long, long);
#pragma aux mulscale16 = "imul ebx" "shrd eax, edx, 16" parm nomemory [eax] [ebx] modify exact [eax edx];

/* Drop the two local slots and use the original register restore. */
extern void shared_graphics_epilogue(void);
#pragma aux shared_graphics_epilogue aborts modify exact [];
extern void leave_angle_frame(void);
#pragma aux leave_angle_frame = "add esp, 8" modify exact [];

extern long step_in_ebx(long);
#pragma aux step_in_ebx = parm [ebx] value [ebx] modify exact [];

/* Keep the C phase initializer in the original accumulator register. */
extern unsigned long phase_in_esi(unsigned long);
#pragma aux phase_in_esi = parm [esi] value [esi] modify exact [];

void rebuild_view_angle_table(volatile long columns)
{
    /* The volatile count and step retain the original two stack slots. */
    volatile long step;
    long computed = mulscale16(320, view_width_reciprocal);
    unsigned long phase = phase_in_esi(0);
    long col = 0;
    step = computed;
    goto check;
    do {
        long advance = step_in_ebx(step);
        long fraction = phase & 0xffffUL;
        long angle = (long)phase >> 16;
        phase += advance;
        if (fraction)
            fraction = mulscale16(radarang[angle + 1] - radarang[angle], fraction);
        column_angles[col++] = (radarang[angle] + fraction) >> 6;
check:
        ;
    } while (col < columns);
    leave_angle_frame();
    shared_graphics_epilogue();
}
