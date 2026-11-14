/* Dispatcher presentation helpers; tables and device interfaces stay external. */
typedef struct { short value[15]; } PresentationTable;
extern const PresentationTable presentation_durations, presentation_pictures;
extern volatile long totalclock;
extern long presentation_width, presentation_height;
extern long dispatch_ticks(long);
extern void presentation_reset(void);
extern long presentation_input(void), presentation_sound(long, long, long, long);
extern void presentation_stop_sound(long), clearview(long), nextpage(void);
extern void rotatesprite(long, long, long, short, short, signed char, unsigned char,
                         unsigned char, long, long, long, long);

long dispatch_prepare(void)
{
    long zoom = 256, last, deadline, handle, input;
    presentation_reset();
    last = totalclock;
    deadline = last + dispatch_ticks(4);
    handle = presentation_sound(0,0,0,0);
    while (!(input = presentation_input()) && deadline > totalclock) {
        if (zoom < 65536) {
            zoom += (totalclock-last) << 8;
            last = totalclock;
            if (zoom > 65536) zoom = 65536;
        }
        clearview(0);
        rotatesprite(160L<<16,100L<<16,zoom,0,2108,0,0,2,0,0,presentation_width-1,presentation_height-1);
        nextpage();
    }
    if (input) {
        if (handle >= 0) presentation_stop_sound(handle);
        return input;
    }
    return 0;
}

long dispatch_poll(void)
{
    PresentationTable durations = presentation_durations;
    PresentationTable pictures = presentation_pictures;
    long i, input, deadline;
    i = 0;
    do {
        clearview(0);
        presentation_reset();
        deadline = totalclock;
        deadline += dispatch_ticks(durations.value[i]);
        rotatesprite(160L<<16,100L<<16,65536,0,pictures.value[i],0,0,2,0,0,presentation_width-1,presentation_height-1);
        nextpage();
        presentation_sound(1,0,0,0);
        while (!(input = presentation_input()) && deadline > totalclock) ;
        if (input == 1) break;
    } while (++i < 15);
    return input;
}
