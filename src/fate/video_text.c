/* In the DOS Watcom stack ABI, the variable arguments follow the format slot. */
typedef char *ArgumentList;

extern int video_vformat(char *, const char *, ArgumentList *);
#pragma aux video_vformat modify exact [eax ebx edx];
extern void output_video_string(const char *);
#pragma aux output_video_string modify exact [eax];
void print_video_text(const char *, ...);
#pragma aux print_video_text parm caller [] modify exact [eax];

void print_video_text(const char *format, ...)
{
    char buffer[80];
    ArgumentList args = (ArgumentList)(&format + 1);
    video_vformat(buffer, format, &args);
    args = 0;
    output_video_string(buffer);
}

extern unsigned long text_strlen(const char *);
#pragma aux text_strlen "strlen_" modify exact [eax];
extern void set_text_position(short, short);
#pragma aux set_text_position modify exact [eax edx];
void print_video_text_at(short column, short row, const char *format, ...);
#pragma aux print_video_text_at parm caller [] modify exact [eax];

void print_video_text_at(short column, short row, const char *format, ...)
{
    char buffer[80];
    ArgumentList args = (ArgumentList)(&format + 1);
    video_vformat(buffer, format, &args);
    args = 0;
    if (column == -1)
        column = 40 - (text_strlen(buffer) >> 1);
    set_text_position(row, column);
    print_video_text(buffer);
}

extern const char demo_version[], demo_name[], demo_title_format[];
extern void set_video_mode(short);
#pragma aux set_video_mode modify exact [eax];
extern void set_background_color(long);
#pragma aux set_background_color modify exact [eax];
extern void set_text_color(short);
#pragma aux set_text_color modify exact [eax];
extern void set_text_window(short, short, short, short);
#pragma aux set_text_window modify exact [eax edx ebx ecx];
extern void clear_screen(short);
#pragma aux clear_screen modify exact [eax];
void initialize_video_console(void)
{
    set_video_mode(3);
    set_background_color(7);
    set_text_color(15);
    set_text_window(1, 1, 2, 80);
    clear_screen(2);
    print_video_text_at(-1, 1, demo_title_format, demo_name, demo_version);
    set_background_color(0);
    set_text_window(2, 1, 25, 80);
    clear_screen(2);
}
