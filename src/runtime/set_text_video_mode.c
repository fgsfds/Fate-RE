extern short set_and_query_bios_mode(int);
#pragma aux set_and_query_bios_mode modify exact [eax];
extern void read_graphics_mode_state(void);
#pragma aux read_graphics_mode_state modify exact [eax];
extern int save_requested_mode(int);
#pragma aux save_requested_mode = parm [edx] value [edx] modify exact [];
extern int request_in_eax(int);
#pragma aux request_in_eax = parm [eax] value [eax] modify exact [];
int set_text_video_mode(int);
#pragma aux set_text_video_mode modify exact [eax];
int set_text_video_mode(int requested)
{
    int original = save_requested_mode(requested);
    short actual = set_and_query_bios_mode((short)request_in_eax(requested));
    if (actual == (short)original) {
        read_graphics_mode_state();
        return 1;
    }
    return 0;
}
