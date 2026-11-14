/* Presentation keyboard scan and mouse-button edge handling. */
extern unsigned char presentation_keys[256];
extern short presentation_mouse_x, presentation_mouse_y;
extern short presentation_buttons;
extern long presentation_previous_buttons;
extern void readmousexy(short *, short *, short *);
extern void presentation_fill(void *, int, unsigned int);
#pragma aux presentation_fill "__STOSB" parm [eax] [edx] [ecx] modify [eax edx ecx];

void presentation_reset(void)
{
    presentation_fill(presentation_keys,0,256);
}

long presentation_input(void)
{
    long key;
    key=0;
    do {
        if (presentation_keys[key] && key!=170) {
            presentation_reset();
            return key;
        }
    } while (++key<256);
    readmousexy(&presentation_mouse_x,&presentation_mouse_y,&presentation_buttons);
    if (presentation_buttons && !presentation_previous_buttons) {
        presentation_previous_buttons=presentation_buttons;
        switch ((long)(short)(presentation_buttons&1)) { case 0: break; default: return 28; }
        switch ((long)(short)(presentation_buttons&2)) { case 0: break; default: return 1; }
        switch ((long)(short)(presentation_buttons&4)) { case 0: break; default: return 1; }
    }
    presentation_previous_buttons=presentation_buttons;
    return 0;
}
