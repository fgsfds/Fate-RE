extern unsigned strlen(const char *text);
#pragma intrinsic(strlen);
extern void initialize_graphics_once(void);
#pragma aux initialize_graphics_once modify exact [eax];
extern void hide_graphics_cursor(void);
#pragma aux hide_graphics_cursor modify exact [eax];
/* Match the parameter setup order of the Watcom text writer call. */
#pragma aux write_text_window_length_first "write_text_window_" parm [edx] [eax] [ebx] modify exact [eax edx ebx];
extern void write_text_window_length_first(short length, const char *text, short translate_controls);
extern void restore_cursor_if_enabled(void);
#pragma aux restore_cursor_if_enabled modify exact [eax];

void output_text_string(const char *text)
{
    initialize_graphics_once();
    hide_graphics_cursor();
    write_text_window_length_first(strlen(text), text, 1);
    restore_cursor_if_enabled();
}
