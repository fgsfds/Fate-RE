/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman.
 * See BUILDLIC.TXT for license terms. */

extern unsigned long frame_count, totalclocklock;
extern volatile unsigned long totalclock;
extern const char frame_rate_format[];

extern void print_frame_diagnostic(const char *format, ...);
#pragma aux print_frame_diagnostic "printf_" parm caller [] modify exact [eax];

void reset_frame_timing(void)
{
    frame_count = 0;
    totalclock = 0;
    totalclocklock = 0;
}

void print_frame_rate(void)
{
    long rate;
    if (!totalclock)
        return;

    /* 120 ticks per second, with two fractional digits. Keep the
       original 32-bit wraparound before signed division. */
    rate = (long)(frame_count * 12000UL) / (long)totalclock;
    print_frame_diagnostic(frame_rate_format, (short)(rate / 100),
                           (short)((rate / 10) % 10), (short)(rate % 10));
}
