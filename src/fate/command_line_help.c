extern const char video_newline[], command_line_title[], command_line_format[];
extern const char *command_line_switches[], *command_line_descriptions[];
extern void print_video_text(const char *, ...);
#pragma aux print_video_text parm caller [] modify exact [eax];
extern void exit_runtime(int);
#pragma aux exit_runtime "exit_" modify exact [eax];

void print_command_line_help(void)
{
    short index;
    print_video_text(video_newline);
    print_video_text(command_line_title);
    print_video_text(video_newline);
    for (index = 0; (long)index < 3; ++index)
        print_video_text(command_line_format, command_line_switches[index], command_line_descriptions[index]);
    print_video_text(video_newline);
    exit_runtime(0);
}

extern const char video_mode_format[], video_size_format[], video_settings_instructions[];
extern const char *video_mode_names[];
extern int text_mode, text_width, text_height;
extern int set_cursor_enabled(int);
#pragma aux set_cursor_enabled modify exact [eax];
void print_video_settings_help(void)
{
    set_cursor_enabled(1);
    print_video_text(video_newline);
    print_video_text(video_mode_format, video_mode_names[text_mode]);
    print_video_text(video_size_format, text_width, text_height);
    print_video_text(video_newline);
    print_video_text(video_settings_instructions);
}
