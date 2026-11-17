extern volatile unsigned char graphics_active;
extern short graphics_error;

short graphics_available(void)
{
    graphics_error = 0;
    if (!graphics_active)
        graphics_error = -3;
    return graphics_active;
}

extern void hide_graphics_cursor(void);
#pragma aux hide_graphics_cursor modify exact [eax];

short check_graphics_and_hide_cursor(void)
{
    graphics_error = 0;
    if (!graphics_active)
        graphics_error = -3;
    else
        hide_graphics_cursor();
    return graphics_active;
}
