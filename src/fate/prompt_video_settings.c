extern const char video_settings_border[], video_settings_mode_format[], video_settings_separator[];
extern const char *video_mode_names[];
extern long text_mode;
extern void set_background_color(long);
#pragma aux set_background_color modify exact [eax];
extern void set_text_color(short);
#pragma aux set_text_color modify exact [eax];
/* The color occupies the low 16 bits of the return register. */
extern long get_text_color(void);
#pragma aux get_text_color modify exact [eax];
extern void prompt_video_mode(short, short);
#pragma aux prompt_video_mode modify exact [eax edx];
extern void print_video_text_at(short, short, const char *, ...);
#pragma aux print_video_text_at parm caller [] modify exact [eax];
/* Keep the signed 16-bit values widened in EAX for the original comparisons. */
extern long keep_in_eax(long);
#pragma aux keep_in_eax = "" parm [eax] value [eax] modify exact [];

void prompt_video_settings(short active)
{
    short mode;
    long current_mode;

    set_background_color(1);
    set_text_color(active ? 11 : 3);
    print_video_text_at(16, 5, video_settings_border);
    mode = 0;
    goto check_mode;
    while (1) {
        if (current_mode == text_mode) {
            set_background_color(active ? 7 : 1);
            set_text_color(15);
        }
        print_video_text_at(16, (short)(6 + 2 * mode), video_settings_mode_format, video_mode_names[mode]);
        if (keep_in_eax((short)get_text_color()) == 15) {
            prompt_video_mode(mode, (short)keep_in_eax(!active));
            set_background_color(1);
            set_text_color(active ? 11 : 3);
        }
        print_video_text_at(16, (short)(7 + 2 * mode), video_settings_separator);
        ++mode;
    check_mode:
        current_mode = keep_in_eax(mode);
        if (current_mode >= 6)
            break;
    }
    print_video_text_at(16, (short)(5 + 2 * mode), video_settings_border);
}
