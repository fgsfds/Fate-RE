// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release.
/* Initialize video state and return the initial index for the existing palette
 * loop. The original EDI/EBP saves remain between the linked C slices. */
extern char setmode_vidoption, parallaxtype, showinvisibility, paletteloaded;
extern long xdim, ydim, parallaxyoffs, parallaxyscale;
extern long *horizlookup, *horizlookup2, horizycent, xyaspect;
extern short pskyoff[], pskybits_fate, searchx, searchit;

extern void initialize_video_backend(void);
extern void *engine_malloc(unsigned long);
extern int __cdecl print_diagnostic(const char *, ...);
extern void runtime_exit(int);
extern char out_of_memory_message[];

int setgamemode_init_context(char davidoption, long daxdim, long daydim)
{
    setmode_vidoption = davidoption; xdim = daxdim; ydim = daydim;
    initialize_video_backend();
    if ((horizlookup = (long *)engine_malloc(ydim*3*sizeof(long))) == 0)
        { print_diagnostic(out_of_memory_message); runtime_exit(0); }
    if ((horizlookup2 = (long *)engine_malloc(ydim*3*sizeof(long))) == 0)
        { print_diagnostic(out_of_memory_message); runtime_exit(0); }
    horizycent = ((ydim*3)>>1);
    xyaspect = -1;
    pskyoff[0] = 0; pskybits_fate = 0;
    parallaxtype = 2; parallaxyoffs = 0; parallaxyscale = 65536;
    showinvisibility = 0;
    paletteloaded = 0;
    searchit = 0; searchx = -1;
    return 0;
}
