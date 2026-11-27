/* Retain the incoming mode in SI until the startup-mode check. */
extern short request_in_si(short request);
#pragma aux request_in_si = "" parm [si] value [si] modify exact [];
struct graphics_device;

/* Each table entry contains a mode word and a 32-bit pointer. */
#pragma pack(push, 1)
struct video_mode_entry {
    short mode;
    const struct graphics_device *device;
};
#pragma pack(pop)

extern const struct video_mode_entry video_device_table[];
extern const struct graphics_device *graphics_device;
extern short graphics_error, video_mode, bitmap_bits_per_pixel;
extern short cursor_enabled, cursor_visible, initial_text_rows, text_rows;
extern unsigned char graphics_active;
extern void initialize_graphics_once(void);
#pragma aux initialize_graphics_once modify exact [eax];
extern short resolve_requested_video_mode(short mode);
#pragma aux resolve_requested_video_mode "resolve_video_mode_" modify exact [eax];
extern short initialize_graphics_device(short mode);
#pragma aux initialize_graphics_device modify exact [eax];
extern void shutdown_graphics_device(void);
#pragma aux shutdown_graphics_device modify exact [eax];
extern void set_text_rows(short rows);
#pragma aux set_text_rows modify exact [eax];
extern void reset_video_state(void);
#pragma aux reset_video_state modify exact [eax];

short set_video_mode(short request)
{
    short mode;
    short previous_mode;
    const struct graphics_device *previous_device, *next_device;
    const struct video_mode_entry *entry;
    graphics_error = 0;
    initialize_graphics_once();
    mode = resolve_requested_video_mode(request);
    if (mode == -1) {
        graphics_error = -1;
        return 0;
    }
    for (entry = video_device_table;; ++entry) {
        if (entry->mode == -1) {
            graphics_error = -4;
            return 0;
        }
        if (entry->mode == mode)
            break;
    }
    previous_device = graphics_device;
    previous_mode = video_mode;
    next_device = entry->device;
    if (previous_device)
        shutdown_graphics_device();
    graphics_device = next_device;
    if (!initialize_graphics_device(mode)) {
        graphics_device = previous_device;
        if (previous_device)
            initialize_graphics_device(previous_mode);
        graphics_error = -2;
        return 0;
    }
    graphics_active = bitmap_bits_per_pixel != 0;
    cursor_visible = cursor_enabled = !graphics_active;
    if (request_in_si(request) == -1)
        set_text_rows(initial_text_rows);
    reset_video_state();
    return text_rows;
}

extern short initial_video_mode;
extern short detect_display_adapters(void);
#pragma aux detect_display_adapters modify exact [eax];
/* The BIOS reports the EGA memory configuration in BX. */
extern short query_ega_memory(int query, int service, int reserved_d, int reserved_c);
#pragma aux query_ega_memory = "push bp" "int 10h" "pop bp" parm [ebx] [eax] [edx] [ecx] value [bx] modify exact [eax ebx ecx edx];

short resolve_video_mode(short request)
{
    unsigned short adapter;
    if (request == -3) {
        adapter = detect_display_adapters() & 0xff;
        switch (adapter) {
        case 2:
            return 6;
        case 3:
mode_10:
            return 0x10;
        case 4:
mode_0e:
            return 0x0e;
        case 5:
            return 0x0f;
        case 7:
        case 8:
        case 16:
        case 17:
            return 0x12;
        case 10:
        case 11:
        case 12:
            return 0x11;
        case 13:
        case 14:
        case 15:
            return 0x0b;
        default:
            return -1;
        }
    }
    if (request == -2) {
        adapter = detect_display_adapters() & 0xff;
        switch (adapter) {
        case 2:
            return 4;
        case 3:
            if (query_ega_memory(0x10, 0x1200, 0, 0))
                goto mode_10;
            goto mode_0e;
        case 4:
            return 0x0e;
        case 5:
            return 0x0f;
        case 7:
        case 8:
        case 10:
        case 11:
        case 12:
        case 16:
        case 17:
            return 0x13;
        case 13:
        case 14:
        case 15:
            return 0x0b;
        default:
            return -1;
        }
    }
    if (request == -1)
        return initial_video_mode;
    return request;
}

extern short probe_color_crtc(short index_port);
#pragma aux probe_color_crtc "probe_crtc_cursor_register_" modify exact [eax];

short detect_color_adapter(void)
{
    short adapter = probe_color_crtc(0x3d4);
    if (adapter)
        return 2;
    return 0;
}

extern int inp(unsigned port);
#pragma intrinsic(inp);
extern int outp(unsigned port, int value);
#pragma intrinsic(outp);
/* Preserve the hardware settling delay between the write and readback. */
extern void wait_crtc(void);
#pragma aux wait_crtc = "jmp short delay_one" "delay_one:" "jmp short delay_two" "delay_two:" "jmp short delay_end" "delay_end:" modify exact [];

short probe_crtc_cursor_register(short port)
{
    volatile short old_value;
    short updated;
    short data_port = port + 1;
    outp(port, 0xf);
    old_value = inp(data_port);
    outp(data_port, 0x5a);
    wait_crtc();
    updated = inp(data_port);
    outp(data_port, (unsigned char)old_value);
    return updated == 0x5a;
}

extern short text_font_bios(int service, int address, int screen, int control);
#pragma aux text_font_bios = "push bp" "int 10h" "pop bp" parm [eax] [edx] [ecx] [ebx] value [ax] modify exact [eax ebx ecx edx];
extern void restore_font_video_mode(short service, int address, int screen, int control);
#pragma aux restore_font_video_mode = "push bp" "int 10h" "pop bp" parm [ax] [edx] [ecx] [ebx] modify exact [eax ebx ecx edx];
/* The BIOS mode number is in the low seven bits of AL. */
extern short query_font_video_mode(int service, int address, int screen, int control);
#pragma aux query_font_video_mode = "push bp" "int 10h" "pop bp" "and al,7fh" "xor ah,ah" parm [eax] [edx] [ecx] [ebx] value [ax] modify exact [eax ebx ecx edx];

void configure_vga_text_font(int font_mode, int font_selector, int cursor_shape)
{
    short mode;
    text_font_bios(font_mode, 0, 0, 0x30);
    mode = query_font_video_mode(0xf00, 0, 0, 0);
    restore_font_video_mode(mode, 0, 0, 0);
    text_font_bios(0x500, 0, 0, 0);
    text_font_bios(font_selector, 0, 0, 0);
    text_font_bios(0x100, 0, cursor_shape, 0);
    cursor_visible = 1;
}

extern short set_mode_for_text_rows(short mode);
#pragma aux set_mode_for_text_rows "set_video_mode_" modify exact [eax];
/* Use the return instruction shared with the font setup routines. */
extern short return_after_font_setup(void);
#pragma aux return_after_font_setup aborts modify exact [eax];
extern short apply_requested_text_rows(short rows);
#pragma aux apply_requested_text_rows "set_text_rows_" aborts modify exact [eax];

short set_video_mode_and_text_rows(short mode, short rows)
{
    if (!set_mode_for_text_rows(mode))
        return return_after_font_setup();
    return apply_requested_text_rows(rows);
}

/* Set the graphics mode arguments in the original Watcom register order. */
extern void apply_legacy_graphics_mode(short width, short bits, short colors, short height,
            int pages, int selector, unsigned long offset, int stride, int flags);
#pragma aux apply_legacy_graphics_mode "apply_graphics_mode_state_" parm routine [eax] [ecx] [ebx] [edx] modify exact [eax edx ebx ecx];
extern unsigned long color_text_offset;
extern short color_text_selector;
extern short set_and_query_bios_mode(short mode);
#pragma aux set_and_query_bios_mode modify exact [eax];

short set_cga_graphics_mode(short mode)
{
    if (set_and_query_bios_mode(mode) == mode) {
        if (mode == 6)
            apply_legacy_graphics_mode(640, 1, 2, 200, 1, color_text_selector, color_text_offset, 0, 0);
        else
            apply_legacy_graphics_mode(320, 2, 4, 200, 1, color_text_selector, color_text_offset, 0, 0);
        return 1;
    }
    return 0;
}


extern unsigned long graphics_offset, mono_text_offset;
extern short graphics_selector, mono_text_selector;

/* Keep the two VGA return paths in their original order. */
extern short vga_result_in_ax(short success);
#pragma aux vga_result_in_ax = "" parm [ax] value [ax] modify exact [];

short set_vga_graphics_mode(short mode)
{
    if (set_and_query_bios_mode(mode) == mode) {
        if (mode == 0x11)
            apply_legacy_graphics_mode(640, 1, 2, 480, 1, graphics_selector, graphics_offset, 0, 0);
        else if (mode == 0x12)
            apply_legacy_graphics_mode(640, 4, 16, 480, 1, graphics_selector, graphics_offset, 0, 1);
        else
            apply_legacy_graphics_mode(320, 8, 256, 200, 1, graphics_selector, graphics_offset, 0, 0);
        return vga_result_in_ax(1);
    }
    return 0;
}

extern void program_hercules_graphics(void);
#pragma aux program_hercules_graphics modify exact [eax];
extern short primary_display_adapter(short adapters);
#pragma aux primary_display_adapter = "xor dh,dh" parm [dx] value [dx] modify exact [];

short set_hercules_mode(void)
{
    short adapters, primary, secondary;

    adapters = detect_display_adapters();
    primary = primary_display_adapter(adapters);
    secondary = adapters >> 8;
    if ((primary >= 13 && primary <= 15) ||
        (secondary >= 13 && secondary <= 15)) {
        program_hercules_graphics();
        apply_legacy_graphics_mode(720, 1, 2, 350, 1, mono_text_selector, mono_text_offset, 0, 2);
        return 1;
    }
    return 0;
}

extern short text_page_count, palette_size;
extern const unsigned char two_plane_device[];

extern void write_plane_mask(int mask, int port);
#pragma aux write_plane_mask = "out dx,ax" parm [eax] [edx] modify exact [];
extern short query_ega_memory_configuration(int feature, int service, int unused_dx, int unused_cx);
#pragma aux query_ega_memory_configuration = "push bp" "int 10h" "pop bp" parm [ebx] [eax] [edx] [ecx] value [bx] modify exact [eax ebx ecx edx];

short set_planar_graphics_mode(short mode)
{
    int pages;
    if (set_and_query_bios_mode(mode) == mode) {
        if (mode == 0xd)
            apply_legacy_graphics_mode(320, 4, 16, 200, 8, graphics_selector, graphics_offset, 0x200, 1);
        else if (mode == 0xe)
            apply_legacy_graphics_mode(640, 4, 16, 200, 4, graphics_selector, graphics_offset, 0x400, 1);
        else if (mode == 0xf)
            apply_legacy_graphics_mode(640, 2, 4, 350, 2, graphics_selector, graphics_offset, 0x800, 1);
        else
            apply_legacy_graphics_mode(640, 4, 16, 350, 2, graphics_selector, graphics_offset, 0x800, 1);

        if (!(query_ega_memory_configuration(0x10, 0x1200, 0, 0) & 0xff)) {
            pages = text_page_count / 4;
            if (pages < 1)
                pages = 1;
            text_page_count = pages;
            if (mode == 0xf || mode == 0x10) {
                graphics_device = (const struct graphics_device *)two_plane_device;
                palette_size = 4;
                bitmap_bits_per_pixel = 2;
            }
        }
        write_plane_mask(0xf02, 0x3c4);
        return 1;
    }
    return 0;
}

extern const unsigned long adapter_mode_masks[];
extern short save_mode_byte(short mode);
#pragma aux save_mode_byte = "mov edx,eax" "xor dh,ah" parm [ax] value [dx] modify exact [];
extern short adapter_pair_in_cx(short adapters);
#pragma aux adapter_pair_in_cx = "" parm [cx] value [cx] modify exact [];
/* The processor masks the shift count to five bits, including for high modes. */
extern unsigned long select_mode_bit(unsigned long bit, int mode);
#pragma aux select_mode_bit = "shl edx,cl" parm [edx] [ecx] value [edx] modify exact [];
extern short normalize_bios_mode(short mode);
#pragma aux normalize_bios_mode = "and dl,7fh" parm [dx] value [dx] modify exact [];

short bios_mode_supported(short mode)
{
    short pair, primary, secondary;
    unsigned long mask;

    mode = save_mode_byte(mode);
    pair = adapter_pair_in_cx(detect_display_adapters());
    mode = normalize_bios_mode(mode);
    secondary = pair >> 8;
    primary = pair & 0xff;
    mask = select_mode_bit(1, mode);
    if ((adapter_mode_masks[primary] & mask) || (adapter_mode_masks[secondary] & mask))
        return vga_result_in_ax(1);
    return 0;
}

extern short viewport_offset_x, viewport_offset_y, viewport_origin_x, viewport_origin_y;
extern float world_bounds[4];
extern short reverse_second_axis;
extern float world_first_min, world_second_min, world_first_max, world_second_max;
extern short pixel_width, pixel_height;
extern short saved_clip_left, saved_clip_right, saved_clip_top, saved_clip_bottom;
extern short set_graphics_clipping(unsigned char enabled);
#pragma aux set_graphics_clipping modify exact [eax];
extern short text_columns, text_cursor_row, text_cursor_column;
extern short text_window_bottom, text_window_top, text_window_left, text_window_right;
extern void reset_graphics_aspect_settings(void);
#pragma aux reset_graphics_aspect_settings modify exact [eax];

extern unsigned char fill_pattern[], default_fill_pattern[];
extern unsigned char fill_pattern_enabled, text_attribute;
extern short pattern_origin_x, pattern_origin_y, text_page_offset, active_text_page;
extern short line_pattern, line_pattern_phase, drawing_action, drawing_color;
extern short pattern_transparent, text_wrap_enabled;
extern unsigned long background_color, screen_offset, mode_buffer_offset;
extern short screen_stride, mode_buffer_stride;

/* Copy the eight-byte default pattern into the active fill pattern. */
extern void restore_default_pattern(int count, const unsigned char *source, unsigned char *destination);
#pragma aux restore_default_pattern = "push es" "push edi" "push ds" "pop es" "repne movsb" "pop edi" "pop es" parm [ecx] [esi] [edi] modify exact [esi ecx];
extern void reset_text_display(void);
#pragma aux reset_text_display modify exact [eax];

extern short video_default_color(short maximum);
#pragma aux video_default_color = "and al,0fh" "xor ah,ah" parm [ax] value [ax] modify exact [eax];

void reset_video_state(void)
{
    short color;
    viewport_offset_x = 0;
    viewport_offset_y = 0;
    viewport_origin_x = 0;
    viewport_origin_y = 0;
    world_bounds[0] = 0;
    world_bounds[1] = 0;
    world_bounds[2] = 0;
    world_bounds[3] = 0;
    reverse_second_axis = 1;
    world_first_min = 0;
    world_second_min = 0;
    world_first_max = 1;
    world_second_max = 1;
    saved_clip_right = pixel_width - 1;
    saved_clip_left = 0;
    saved_clip_bottom = pixel_height - 1;
    saved_clip_top = 0;
    set_graphics_clipping(1);
    text_cursor_row = 0;
    text_cursor_column = 0;
    text_window_bottom = text_rows - 1;
    text_window_top = 0;
    text_window_left = 0;
    text_window_right = text_columns - 1;
    if (graphics_active)
        reset_graphics_aspect_settings();

    restore_default_pattern(8, default_fill_pattern, fill_pattern);
    fill_pattern_enabled = 0;
    pattern_origin_x = 0;
    pattern_origin_y = 0;
    text_attribute = 7;
    background_color = 0;
    text_page_offset = 0;
    active_text_page = 0;
    color = palette_size;
    line_pattern = -1;
    --color;
    line_pattern_phase = 0;
    color = video_default_color(color);
    drawing_action = 0;
    drawing_color = color;
    pattern_transparent = 1;
    screen_stride = mode_buffer_stride;
    text_wrap_enabled = 1;
    screen_offset = mode_buffer_offset;
    reset_text_display();
}

extern short adapter_class;
extern const unsigned long legacy_rgb_palette[];
extern void write_reset_palette_entry(unsigned long color, int index);
#pragma aux write_reset_palette_entry "replace_palette_entry_" parm [edx] [eax] modify exact [eax edx];
extern void upload_legacy_palette(int count, const unsigned long *colors);
#pragma aux upload_legacy_palette "upload_palette_entries_" parm [edx] [eax] modify exact [eax edx];
/* Use the saved-register epilogue shared with set_video_mode. */
extern void finish_text_display_reset(void);
#pragma aux finish_text_display_reset aborts modify exact [eax];

extern void clear_text_dac_entry(void);
#pragma aux clear_text_dac_entry = "mov eax,1010h" "mov ebx,10h" "xor ecx,ecx" "xor edx,edx" "push bp" "int 10h" "pop bp" modify exact [eax ebx ecx edx];
/* Keep the BIOS palette index in ESI and its packed attribute in EDI. */
extern void initialize_text_attribute_mapping(void);
#pragma aux first_text_attribute = "xor esi,esi" "mov eax,1001h" "mov ebx,1000h" "xor ecx,ecx" "xor edx,edx" "mov edi,esi" "push bp" "int 10h" "pop bp" "shl edi,8" modify exact [eax ebx ecx edx esi edi];
extern int write_next_text_attribute_mapping(void);
#pragma aux write_next_text_attribute = "mov eax,1000h" "mov ebx,edi" "xor ecx,ecx" "xor edx,edx" "or ebx,esi" "push bp" "int 10h" "pop bp" "inc esi" "add edi,100h" value [esi] modify exact [eax ebx ecx edx esi edi];

void reset_text_display(void)
{
    int white;

    if (adapter_class < 4 || video_mode == 7 || video_mode == 0xf)
        goto done;

    clear_text_dac_entry();
    first_text_attribute();
    while (write_next_text_attribute() < 16) {
    }

    if (palette_size == 2) {
        write_reset_palette_entry(0, 0);
        white = 1;
white_entry:
        write_reset_palette_entry(0x3f3f3f, white);
        goto done;
    }
    if (palette_size == 4) {
        write_reset_palette_entry(0, 0);
        write_reset_palette_entry(0x3f3f15, 1);
        write_reset_palette_entry(0x3f153f, 2);
        white = 3;
        goto white_entry;
    }
    if (palette_size >= 16)
        upload_legacy_palette(16, legacy_rgb_palette);

done:
    finish_text_display_reset();
}
