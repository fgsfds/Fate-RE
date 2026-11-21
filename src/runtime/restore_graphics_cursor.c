extern short cursor_restore_enabled;
/* Transfer directly to the cursor routine when restoration is enabled. */
extern void show_graphics_cursor(void);
#pragma aux show_graphics_cursor aborts modify exact [eax];
void restore_cursor_if_enabled(void)
{
    if (cursor_restore_enabled == 1)
        show_graphics_cursor();
}
