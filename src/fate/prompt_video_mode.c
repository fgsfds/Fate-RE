/* Guarded context for the video-size prompt. The private full-register
 * brightness carrier is narrowed to the original signed word. Production
 * callers supply mode 0..5; unmatched frame/setup and invalid edges stay ASM. */
typedef struct VideoSizeIndex {
    short width;
    short height;
} VideoSizeIndex;

extern const VideoSizeIndex video_default_indices;
extern const short video_default_width, video_default_height;
extern const VideoSizeIndex first_mode_indices[], second_mode_indices[];
extern const short first_mode_widths[], first_mode_heights[];
extern const short second_mode_widths[], second_mode_heights[];
extern short video_size_selection, video_size_count;
extern long video_mode_selection, requested_video_width, requested_video_height;
extern const char *video_mode_names[];
extern const char video_size_heading[], video_size_empty_row[];
extern const char video_prompt_size_format[], video_size_footer[];

extern void set_background_color(long);
#pragma aux set_background_color modify exact [eax];
extern void set_text_color(short);
#pragma aux set_text_color modify exact [eax];
extern long get_text_color(void);
#pragma aux get_text_color modify exact [eax];
extern void print_video_text_at(short, short, const char *, ...);
#pragma aux print_video_text_at parm caller [] modify exact [eax];

/* The empty binding preserves the brightness in the original live register. */
extern long keep_brightness(long);
#pragma aux keep_brightness = "" parm [ecx] value [ecx] modify exact [];
extern long keep_in_eax(long);
#pragma aux keep_in_eax = "" parm [eax] value [eax] modify exact [];

void prompt_video_mode_context(unsigned short mode, long brightness);
#pragma aux prompt_video_mode_context parm [eax] [edx] modify exact [eax edx];

void prompt_video_mode_context(unsigned short mode, long brightness)
{
    VideoSizeIndex default_indices[1];
    const VideoSizeIndex *indices;
    const short *widths, *heights;
    short default_width[1], default_height[1];
    short width_index, height_index, width, height;
    short item, first_item, end_item, bright;

    bright = (short)keep_brightness(brightness);
    default_indices[0] = video_default_indices;
    default_width[0] = video_default_width;
    default_height[0] = video_default_height;

    switch (mode) {
    case 0:
        indices = first_mode_indices;
        widths = first_mode_widths;
        heights = first_mode_heights;
        video_size_count = 3;
        break;
    case 1:
        indices = second_mode_indices;
        widths = second_mode_widths;
        heights = second_mode_heights;
        video_size_count = 2;
        break;
    case 2:
    case 3:
    case 4:
    case 5:
        indices = default_indices;
        widths = default_width;
        heights = default_height;
        video_size_count = 1;
        break;
    default:
        return;
    }

    if (video_size_selection >= video_size_count)
        video_size_selection = (short)(video_size_count - 1);

    for (item = 0; item < video_size_count; ++item) {
        width_index = indices[item].width;
        height_index = indices[item].height;
        width = widths[width_index];
        height = heights[height_index];
        if (width == requested_video_width && height == requested_video_height)
            video_size_selection = item;
    }

    first_item = (short)(video_size_selection - 5);
    if (first_item < 0)
        first_item = 0;
    end_item = (short)(first_item + 11);

    set_background_color(bright ? 11 : 3);
    set_text_color(0);
    print_video_text_at(47, 5, video_size_heading, video_mode_names[video_mode_selection]);
    set_background_color(1);
    set_text_color(bright ? 11 : 3);

    for (item = first_item; item < end_item; ++item) {
        if (item >= video_size_count) {
            print_video_text_at(47, (short)(item + 6 - first_item), video_size_empty_row);
            continue;
        }
        if (item == video_size_selection) {
            set_background_color(bright ? 7 : 1);
            set_text_color(15);
        }
        width_index = indices[item].width;
        height_index = indices[item].height;
        print_video_text_at(47, (short)(item + 6 - first_item), video_prompt_size_format,
                            widths[width_index], heights[height_index]);
        if (keep_in_eax((short)get_text_color()) == 15) {
            set_background_color(1);
            set_text_color(bright ? 11 : 3);
        }
    }

    print_video_text_at(47, (short)(item + 6 - first_item), video_size_footer);
}

