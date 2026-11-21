// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release.
/* Historical context for the display-buffer and automap reset. Only that
 * checked slice links. The remaining assembly uses its original switch. */
#define MAXTILES 4096
#define MAXPALOOKUPS 256

extern char vidoption, parallaxtype, showinvisibility;
extern long xdim, ydim, parallaxyoffs, parallaxyscale, waloff[];
extern short pskyoff[];
extern char *palookup[];
extern char show2dsector[], show2dsprite[], show2dwall[];
extern void clearbuf(long, long, long);
#pragma aux clearbuf = "rep stosd" parm [edi][ecx][eax] modify exact [edi ecx]

extern long *horizlookup, *horizlookup2, horizycent, xyaspect;
extern short searchx, searchit, pskybits_fate, validmodecnt_fate;
extern short highlightcnt, pointhighlight, linehighlight;
extern char paletteloaded, automapping, chainstat;
extern long numpages_fate, chainplace, image_size, frameplace;
extern char *screen;
extern long visibility_fate, parallaxvisibility_fate;
extern long stereomode_fate, stereopixelwidth, stereowidth, page_flip_enabled;
extern char stereo_video_mode;

extern void initialize_video_backend(void);
extern void finish_video_mode_setup(void);
extern void loadpalette(void);
extern void *engine_malloc(unsigned long);
extern int __cdecl print_diagnostic(const char *, ...);
extern void runtime_exit(int);
extern char out_of_memory_message[];
extern char screen_allocation_message_0[], screen_allocation_message_1[];
extern char screen_allocation_message_2[], screen_allocation_message_6[];
extern char screen_allocation_message_7[];

void setgamemode_display_context(char davidoption, long daxdim, long daydim)
{
    long i;
    vidoption = davidoption; xdim = daxdim; ydim = daydim;
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
    for (i=0; i<MAXPALOOKUPS; i++) palookup[i] = 0;
    clearbuf((long)&waloff[0], (long)MAXTILES, 0L);
    clearbuf((long)&show2dsector[0], 32L, 0L);
    clearbuf((long)&show2dsprite[0], 128L, 0L);
    clearbuf((long)&show2dwall[0], 256L, 0L);
    automapping = 0;
    pointhighlight = -1;
    linehighlight = -1;
    highlightcnt = 0;
    loadpalette();
    visibility_fate = 512;
    parallaxvisibility_fate = 512;
    numpages_fate = 0;
    chainstat = 0;
    switch (vidoption) {
    case 0:
        image_size = (((xdim*ydim)>>2)+255)&0xffffff00;
        numpages_fate = 65536/image_size;
        chainplace = 0xa0000;
        if (numpages_fate >= 2) chainstat = 1;
        if (numpages_fate == 1) {
            if ((screen = engine_malloc(xdim*ydim)) == 0)
                { print_diagnostic(screen_allocation_message_0); runtime_exit(0); }
            frameplace = (long)screen;
        }
        break;
    case 1:
        if ((screen = engine_malloc((xdim+8)*ydim)) == 0)
            { print_diagnostic(screen_allocation_message_1); runtime_exit(0); }
        frameplace = (long)screen;
        break;
    case 2:
        if ((screen = engine_malloc(xdim*ydim)) == 0)
            { print_diagnostic(screen_allocation_message_2); runtime_exit(0); }
        frameplace = (long)screen;
        break;
    case 3: case 4: case 5:
        frameplace = 0xa0000;
        break;
    case 6:
        if ((screen = engine_malloc(65536)) == 0)
            { print_diagnostic(screen_allocation_message_6); runtime_exit(0); }
        frameplace = (long)screen;
        stereomode_fate = vidoption; vidoption = 2;
        stereowidth = 32768; stereopixelwidth = 32;
        page_flip_enabled = 1;
        break;
    case 7:
        if ((screen = engine_malloc(131072)) == 0)
            { print_diagnostic(screen_allocation_message_7); runtime_exit(0); }
        frameplace = (long)screen;
        stereowidth = 32768; stereopixelwidth = 32;
        stereomode_fate = vidoption; vidoption = 2;
        page_flip_enabled = 1;
        break;
    }
    finish_video_mode_setup();
}
