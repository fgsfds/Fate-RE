/* Stereo backend state from ordinary C. Empty identities bind byte and
 * constant lifetimes without instructions. The checked phases commute only
 * independent register operations and stores to distinct ordinary globals.
 * The original caller owns the saved-register frame and shared return. */
extern char *screen;
extern char video_backend;
extern long frameplace, stereopixelwidth, stereomode_fate;
extern long stereowidth, page_flip_enabled;

extern unsigned char in_ch(unsigned char);
#pragma aux in_ch = "" parm [ch] value [ch] modify exact [];
extern unsigned char in_cl(unsigned char);
#pragma aux in_cl = "" parm [cl] value [cl] modify exact [];
extern long in_eax(long), in_edx(long), in_esi(long), in_edi(long), in_ecx(long);
#pragma aux in_eax = "" parm [eax] value [eax] modify exact [];
#pragma aux in_edx = "" parm [edx] value [edx] modify exact [];
#pragma aux in_esi = "" parm [esi] value [esi] modify exact [];
#pragma aux in_edi = "" parm [edi] value [edi] modify exact [];
#pragma aux in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern long current_bx(void), current_si(void), current_di(void);
#pragma aux current_bx = "" value [ebx] modify exact [];
#pragma aux current_si = "" value [esi] modify exact [];
#pragma aux current_di = "" value [edi] modify exact [];
extern void preserve_unchanged(long, long, long);
#pragma aux preserve_unchanged = "" parm [ebx] [esi] [edi] modify exact [];
#pragma aux setgamemode_stereo_single_context modify exact [eax ecx edx];
#pragma aux setgamemode_stereo_double_context modify exact [eax ecx esi edi];


void setgamemode_stereo_single_context(void)
{
    long saved_bx = current_bx();
    long saved_si = current_si();
    long saved_di = current_di();
    unsigned char backend = in_ch(2);
    long flip = 1;
    long frame = in_eax((long)screen);
    long pixel_width = in_edx(32);
    unsigned long old_backend;

    frameplace = frame;
    old_backend = in_eax((unsigned char)video_backend);
    page_flip_enabled = flip;
    stereopixelwidth = pixel_width;
    stereomode_fate = old_backend;
    frame = in_eax(32768);
    video_backend = backend;
    stereowidth = frame;
    preserve_unchanged(saved_bx, saved_si, saved_di);
}

void setgamemode_stereo_double_context(void)
{
    unsigned char backend = in_cl(2);
    long width = in_esi(32768);
    long frame = in_eax((long)screen);
    long pixel_width = in_edi(32);
    unsigned long old_backend;
    long flip;

    frameplace = frame;
    stereowidth = width;
    old_backend = in_eax((unsigned char)video_backend);
    stereopixelwidth = pixel_width;
    video_backend = backend;
    flip = in_ecx(1);
    stereomode_fate = old_backend;
    page_flip_enabled = flip;
}
