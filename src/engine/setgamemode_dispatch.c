// "Build Engine & Tools" Copyright (c) 1993-1997 Ken Silverman
// Ken Silverman's official web site: "http://www.advsys.net/ken"
// See the included license file "BUILDLIC.TXT" for license info.
// This file has been modified from Ken Silverman's original release.
/* The mode guard is linked separately. These checked phases keep a zero-
 * extended backend index in EDX and the wrapping pixel product in EAX.
 * Only the generated table and dispatch slices link from this context. */
extern char video_backend, chainstat;
extern long xdim, ydim, image_size, numpages_fate, chainplace, frameplace;
extern char *screen;
extern long stereomode_fate, stereopixelwidth, stereowidth, page_flip_enabled;
extern void finish_video_mode_setup(void);
extern void *engine_malloc(unsigned long);
extern int __cdecl print_diagnostic(const char *, ...);
extern void runtime_exit(int);
extern char screen_allocation_message_0[], screen_allocation_message_1[];
extern char screen_allocation_message_2[], screen_allocation_message_6[];
extern char screen_allocation_message_7[];

extern unsigned long in_eax(unsigned long), in_ebx(unsigned long), in_edx(unsigned long);
#pragma aux in_eax = "" parm [eax] value [eax] modify exact [];
#pragma aux in_ebx = "" parm [ebx] value [ebx] modify exact [];
#pragma aux in_edx = "" parm [edx] value [edx] modify exact [];

union video_key {
    unsigned long word;
    unsigned char byte[4];
};

#pragma aux setgamemode_dispatch_context parm [eax];
void setgamemode_dispatch_context(unsigned long mode)
{
    union video_key key;
    unsigned long height, pixels;
    key.word = in_edx(0);
    height = in_ebx((unsigned long)ydim);
    key.byte[0] = (unsigned char)mode;
    pixels = in_eax(in_eax((unsigned long)xdim) * height);
    switch (in_edx(key.word)) {
    case 0:
        image_size = ((((long)pixels)>>2)+255)&0xffffff00;
        numpages_fate = 65536/image_size;
        chainplace = 0xa0000;
        if (numpages_fate >= 2) chainstat = 1;
        if (numpages_fate == 1) {
            if ((screen = engine_malloc((unsigned long)xdim*(unsigned long)ydim)) == 0)
                { print_diagnostic(screen_allocation_message_0); runtime_exit(0); }
            frameplace = (long)screen;
        }
        break;
    case 1:
        if ((screen = engine_malloc(((unsigned long)xdim+8)*height)) == 0)
            { print_diagnostic(screen_allocation_message_1); runtime_exit(0); }
        frameplace = (long)screen;
        break;
    case 2:
        if ((screen = engine_malloc(pixels)) == 0)
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
        stereomode_fate = video_backend; video_backend = 2;
        stereowidth = 32768; stereopixelwidth = 32;
        page_flip_enabled = 1;
        break;
    case 7:
        if ((screen = engine_malloc(131072)) == 0)
            { print_diagnostic(screen_allocation_message_7); runtime_exit(0); }
        frameplace = (long)screen;
        stereowidth = 32768; stereopixelwidth = 32;
        stereomode_fate = video_backend; video_backend = 2;
        page_flip_enabled = 1;
        break;
    }
    finish_video_mode_setup();
}

