extern const char *video_mode_names[];
extern short chain_mode_widths[], chain_mode_heights[];
extern short vesa_mode_widths[], vesa_mode_heights[];

extern int compare_video_mode(const char *, const char *);
#pragma aux compare_video_mode "stricmp_" modify exact [eax edx];

/* These identities preserve Watcom register allocation without emitting code. */
extern short *keep_width_pointer(short *);
#pragma aux keep_width_pointer = "" parm [ecx] value [ecx] modify exact [];
extern const char *keep_mode_name(const char *);
#pragma aux keep_mode_name = "" parm [edi] value [edi] modify exact [];
extern short keep_mode_limit(short);
#pragma aux keep_mode_limit = "" parm [di] value [di] modify exact [];
extern short keep_mode_height(short);
#pragma aux keep_mode_height = "" parm [cx] value [cx] modify exact [];
extern short keep_vesa_height(short);
#pragma aux keep_vesa_height = "" parm [dx] value [dx] modify exact [];

extern unsigned keep_chain_height_offset(unsigned);
#pragma aux keep_chain_height_offset = "" parm [edx] value [edx] modify exact [];
extern unsigned keep_vesa_height_offset(unsigned);
#pragma aux keep_vesa_height_offset = "" parm [ecx] value [ecx] modify exact [];
int parse_video_mode(const char *, short *, short *);
#pragma aux parse_video_mode modify exact [eax ebx edx];
int parse_video_mode(const char *name, short *width, short *height)
{
    int mode = 0;
    unsigned index;

    name = keep_mode_name(name);
    width = keep_width_pointer(width);
    do {
        if (!compare_video_mode(name, video_mode_names[mode]))
            break;
        ++mode;
    } while (mode < 6);

    switch (mode) {
    case 0:
        index = 0;
        goto test_chain_width;
        do {
            if (*width <= chain_mode_widths[index]) {
                *width = chain_mode_widths[index];
                break;
            }
            ++index;
        test_chain_width:
            ;
        } while (index < 3);

        index = 0;
        goto test_chain_height;
        do {
            unsigned offset = keep_chain_height_offset(index * sizeof(short));
            short current_height = keep_mode_height(*height);
            short limit = keep_mode_limit(*(short *)((char *)chain_mode_heights + offset));
            if (current_height <= limit) {
                *height = limit;
                break;
            }
            ++index;
        test_chain_height:
            ;
        } while (index < 3);
        break;

    case 1:
        index = 0;
        goto test_vesa_width;
        do {
            if (*width <= vesa_mode_widths[index]) {
                *width = vesa_mode_widths[index];
                break;
            }
            ++index;
        test_vesa_width:
            ;
        } while (index < 2);

        index = 0;
        goto test_vesa_height;
        do {
            unsigned offset = keep_vesa_height_offset(index * sizeof(short));
            short current_height = keep_vesa_height(*height);
            short limit = keep_mode_limit(*(short *)((char *)vesa_mode_heights + offset));
            if (current_height <= limit) {
                *height = limit;
                break;
            }
            ++index;
        test_vesa_height:
            ;
        } while (index < 2);
        break;

    case 2:
    case 3:
    case 4:
    case 5:
        *width = 320;
        *height = 200;
        break;

    default:
        return -1;
    }
    return mode;
}
