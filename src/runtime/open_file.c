extern int sopen(const char *, int, int, ...);
#pragma aux sopen parm caller [] modify exact [eax ebx edx];
extern const int *mode_cursor_in_eax(const int *);
#pragma aux mode_cursor_in_eax = parm [eax] value [eax] modify exact [];
extern int open_flags_in_edx(int);
#pragma aux open_flags_in_edx = parm [edx] value [edx] modify exact [];
extern const char *open_path_in_ebx(const char *);
#pragma aux open_path_in_ebx = parm [ebx] value [ebx] modify exact [];

extern int open_mode_in_eax(int);
#pragma aux open_mode_in_eax = parm [eax] value [eax] modify exact [];

int open(const char *, int, ...);
#pragma aux open parm caller [] modify exact [eax];
int open(const char *path, int flags, ...)
{
    /* Forward the Watcom stack slot. sopen uses the mode only for creation. */
    const int *cursor = mode_cursor_in_eax(&flags + 1);
    cursor = mode_cursor_in_eax(cursor + 1);
    return sopen(open_path_in_ebx(path), open_flags_in_edx(flags), 0, open_mode_in_eax(cursor[-1]));
}
