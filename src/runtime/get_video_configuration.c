struct video_configuration {
    short pixel_width, pixel_height;
    short text_columns, text_rows;
    short palette_size, bits_per_pixel;
    short page_count, mode, adapter_class, monitor_class, memory_kib;
};
extern struct video_configuration pixel_width;
extern void initialize_graphics_once(void);
#pragma aux initialize_graphics_once modify exact [eax];

/* The small-model copy uses ES. Preserve the caller's selector. */
extern struct video_configuration *save_video_copy_segment(struct video_configuration *config);
#pragma aux save_video_copy_segment = "push es" parm [eax] value [eax] modify exact [];
extern void restore_video_copy_segment(void);
#pragma aux restore_video_copy_segment = "pop es" modify exact [];

struct video_configuration *get_video_configuration(struct video_configuration *config)
{
    config = save_video_copy_segment(config);
    initialize_graphics_once();
    *config = pixel_width;
    restore_video_copy_segment();
    return config;
}
