extern unsigned strlen(const char *text);
extern char *strupr(char *text);
extern unsigned char saved_text_mode;
extern int saved_text_width, saved_text_height;
extern void restore_engine_video_mode(int mode, int width, int height);
extern unsigned video_dos_buffer_size, video_dos_allocation;
extern unsigned char vesa_probe_attempted;

void trim_and_uppercase(char *text)
{
    int length = strlen(text);
    if (length > 0) {
        int index = length - 1;
        for (;;) {
            char *end = text + index;
            if ((int)(unsigned char)*end != ' ' || index <= 0)
                break;
            --index;
            *end = 0;
        }
        strupr(text);
    }
}

void restore_text_video_mode(void)
{
    restore_engine_video_mode(saved_text_mode, saved_text_width, saved_text_height);
}

void reset_vesa_state(void)
{
    video_dos_buffer_size = 1024;
    video_dos_allocation = 0;
    vesa_probe_attempted = 0;
}
