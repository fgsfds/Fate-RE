extern void draw_graphics_span(short, short, short);
#pragma aux draw_graphics_span modify exact [eax edx ebx];
extern short clip_left, clip_right, clip_top, clip_bottom, graphics_error;
extern short cursor_enabled;

short set_cursor_enabled(short enable)
{
    short previous = cursor_enabled;
    cursor_enabled = enable;
    return previous;
}

void draw_clipped_graphics_span(short left, short right, short row)
{
    short draw_y = row;
    if (row < clip_top || row > clip_bottom)
        return;
    if (left < clip_left)
        left = clip_left;
    if (right > clip_right)
        right = clip_right;
    draw_graphics_span(left, draw_y, right - left + 1);
}


unsigned char graphics_point_outcode(short x, short y)
{
    unsigned char bits = 0;
    if (x < clip_left)
        bits = 8;
    else if (x > clip_right)
        bits = 4;
    if (y < clip_top)
        bits |= 1;
    else if (y > clip_bottom)
        bits |= 2;
    if (bits)
        graphics_error = 2;
    return bits;
}

void clamp_point_edge(short *x, short *y, unsigned char bits)
{
    if (bits & 1)
        *y = clip_top;
    else if (bits & 2)
        *y = clip_bottom;
    else if (bits & 4)
        *x = clip_right;
    else if (bits & 8)
        *x = clip_left;
}

extern void begin_graphics_device(void);
#pragma aux begin_graphics_device modify exact [eax];
extern void end_graphics_device(void);
#pragma aux end_graphics_device modify exact [eax];
/* Keep y in EDX when calling the existing span routine from the row loop. */
#pragma aux draw_span_y_first "draw_graphics_span_" parm [edx] [eax] [ebx] modify exact [eax edx ebx];
extern void draw_span_y_first(short y, short x, short width);

void fill_graphics_rectangle(short x1, short y1, short x2, short y2)
{
    short width;
    short tmp;
    if (x1 > x2) {
        tmp = x1;
        x1 = x2;
        x2 = tmp;
    }
    if (y1 > y2) {
        tmp = y1;
        y1 = y2;
        y2 = tmp;
    }
    width = x2 - x1 + 1;
    begin_graphics_device();
    for (; y1 <= y2; ++y1)
        draw_span_y_first(y1, x1, width);
    end_graphics_device();
}

extern short drawing_color;
/* Arrange the endpoint pointers in the original instruction order. */
#pragma aux clip_line_last_y_first "clip_graphics_line_" parm [ecx] [ebx] [edx] [eax] modify exact [eax edx ebx ecx];
extern short clip_line_last_y_first(short *y2, short *x2, short *y1, short *x1);
extern void dispatch_device_line(short, short, short, short, short, unsigned short);
#pragma aux dispatch_device_line modify exact [eax edx ebx ecx];

void draw_clipped_solid_line(short x1, short y1, short x2, short y2)
{
    if (!clip_line_last_y_first(&y2, &x2, &y1, &x1))
        dispatch_device_line(x1, y1, x2, y2, drawing_color, 0xffff);
}

extern short cursor_visible;
extern unsigned char graphics_active;
extern void set_bios_cursor_visible(short visible);
#pragma aux set_bios_cursor_visible modify exact [eax];
extern void toggle_graphics_cursor_line(void);
#pragma aux toggle_graphics_cursor_line modify exact [eax];

void show_graphics_cursor(void)
{
    if (cursor_visible)
        return;
    if (!graphics_active)
        set_bios_cursor_visible(1);
    else
        toggle_graphics_cursor_line();
    cursor_visible = 1;
}

/* Preserve the original allocation of the saved drawing action in SI. */
extern short saved_action_in_si(short action);
#pragma aux saved_action_in_si = "" parm [si] value [si] modify exact [];
extern short set_clear_drawing_action(short action);
#pragma aux set_clear_drawing_action "set_drawing_action_" modify exact [eax];
extern unsigned char *get_fill_pattern(unsigned char *pattern);
#pragma aux get_fill_pattern modify exact [eax];
extern void set_fill_pattern(const unsigned char *pattern);
#pragma aux set_fill_pattern modify exact [eax];
extern short get_drawing_color(void);
#pragma aux get_drawing_color modify exact [eax];
extern short set_drawing_color(short color);
#pragma aux set_drawing_color modify exact [eax];
extern void fill_clear_rectangle(short x1, short y1, short x2, short y2);
#pragma aux fill_clear_rectangle "fill_graphics_rectangle_" modify exact [eax edx ebx ecx];

void clear_graphics_region(short x1, short y1, short x2, short y2)
{
    unsigned char fill[8];
    short previous_action, previous_color;

    previous_action = set_clear_drawing_action(3);
    get_fill_pattern(fill);
    set_fill_pattern(0);
    previous_color = get_drawing_color();
    set_drawing_color(0);
    fill_clear_rectangle(x1, y1, x2, y2);
    set_drawing_color(previous_color);
    set_fill_pattern(fill);
    set_clear_drawing_action(saved_action_in_si(previous_action));
}

extern short drawing_action;
extern short get_drawing_action(void);
#pragma aux get_drawing_action modify exact [eax];

short set_drawing_action(short action)
{
    short previous = get_drawing_action();
    switch (action) {
    case 4:
        drawing_action = 1;
        break;
    case 1:
        drawing_action = 2;
        break;
    case 0:
        drawing_action = 3;
        break;
    case 2:
    case 3:
    default:
        drawing_action = 0;
        break;
    }
    return previous;
}

extern unsigned char clipping_enabled;
extern short saved_clip_left, saved_clip_right, saved_clip_top, saved_clip_bottom;
extern short screen_width, screen_height;
extern void recalculate_coordinate_scales(void);
#pragma aux recalculate_coordinate_scales modify exact [eax];

short set_graphics_clipping(unsigned char enabled)
{
    short previous = clipping_enabled;
    short bottom;

    clipping_enabled = enabled;
    if (enabled) {
        clip_left = saved_clip_left;
        clip_right = saved_clip_right;
        clip_top = saved_clip_top;
        bottom = saved_clip_bottom;
    } else {
        clip_right = screen_width - 1;
        bottom = screen_height;
        /* Preserve Watcom's ordering of the edge stores around the decrement. */
        *(volatile short *)&clip_left = 0;
        --bottom;
        *(volatile short *)&clip_top = 0;
    }
    clip_bottom = bottom;
    recalculate_coordinate_scales();
    return previous;
}

extern int cursor_row_in_ebx(int row);
#pragma aux cursor_row_in_ebx = "" parm [ebx] value [ebx] modify exact [];
/* Carry the text-cell span in the original draw registers. */
extern int left_cursor_edge(int column, int width);
#pragma aux left_cursor_edge = "imul eax,ebx" "lea edx,[eax+ebx]" parm [eax] [ebx] value [eax] modify exact [eax edx];
extern int cursor_right_edge(void);
#pragma aux cursor_right_edge = value [edx] modify exact [];
extern int cursor_scanline_base(int row, int height);
#pragma aux cursor_scanline_base = "inc ebx" "imul ebx,ecx" parm [ebx] [ecx] value [ebx] modify exact [ebx];
extern void draw_cursor_scanline(int y2, int x2, int x1, int y1);
#pragma aux draw_cursor_scanline "draw_clipped_solid_line_" parm [ecx] [ebx] [eax] [edx] modify exact [eax edx ebx ecx];
extern short drawing_color, palette_size;
extern short pixel_width, pixel_height, text_columns, text_rows;
extern short text_cursor_column, text_cursor_row;
#pragma aux set_drawing_action modify exact [eax];
extern short set_drawing_color(short color);
#pragma aux set_drawing_color modify exact [eax];

extern short action_in_si(short action);
#pragma aux action_in_si = "" parm [si] value [si] modify exact [];
extern short cell_width_in_cx(short width);
#pragma aux cell_width_in_cx = "" parm [cx] value [cx] modify exact [];
extern short cell_height_in_di(short height);
#pragma aux cell_height_in_di = "" parm [di] value [di] modify exact [];
extern short mask_cursor_color(short color);
#pragma aux mask_cursor_color = "and al,0fh" "xor ah,ah" parm [ax] value [ax] modify exact [];
void toggle_graphics_cursor_line(void)
{
    short action, width, height;
    short color;
    int x1;
    short x2, y;

    action = action_in_si(set_drawing_action(4));
    color = drawing_color;
    drawing_color = mask_cursor_color(palette_size - 1);
    width = cell_width_in_cx(pixel_width / text_columns);
    height = cell_height_in_di(pixel_height / text_rows);
    x1 = left_cursor_edge(text_cursor_column, width);
    x2 = cursor_right_edge();
    y = cursor_scanline_base(cursor_row_in_ebx(text_cursor_row), height);
    --x2;
    --y;
    draw_cursor_scanline(y, x2, (short)x1, y);
    set_drawing_action(action);
    set_drawing_color(color);
}

/* Keep each endpoint and its outcode in the line clipper's Watcom registers. */
extern void load_second_axis_clip_point(int x, int y);
#pragma aux load_second_axis_clip_point = "" parm [eax] [edx] modify exact [];
extern unsigned char classify_current_axis_point(void);
#pragma aux classify_current_axis_point "graphics_point_outcode_" modify exact [eax];
extern void load_first_axis_clip_x(int x);
#pragma aux load_first_axis_clip_x = "" parm [eax] modify exact [];
extern unsigned char classify_first_axis_with_y(int y);
#pragma aux classify_first_axis_with_y "graphics_point_outcode_" parm [edx] modify exact [eax];
extern short *axis_x_in_eax(short *x);
#pragma aux axis_x_in_eax = "" parm [eax] value [eax] modify exact [];
extern void second_x_in_edi(short *pointer);
#pragma aux second_x_in_edi = "" parm [edi] modify exact [];
extern short *axis_second_pointer(void);
#pragma aux axis_second_pointer = value [edi] modify exact [];
extern unsigned int first_outcode_in_eax(unsigned int outcode);
#pragma aux first_outcode_in_eax = "" parm [eax] value [eax] modify exact [];
extern unsigned int second_outcode_in_ebx(unsigned int outcode);
#pragma aux second_outcode_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern unsigned char axis_first_outcode_in_al(void);
#pragma aux axis_first_outcode_in_al = value [al] modify exact [];
extern void prepare_axis_clip_result(unsigned short second, unsigned short first);
#pragma aux prepare_axis_clip_result = "" parm [dx] [ax] modify exact [];
extern unsigned char axis_first_outcode(int y, int x);
#pragma aux axis_first_outcode "graphics_point_outcode_" parm [edx] [eax] modify exact [eax];
extern void clamp_axis_first(short *y, unsigned int bits, short *x);
#pragma aux clamp_axis_first "clamp_point_edge_" parm [edx] [ebx] [eax] modify exact [eax];
extern void clamp_axis_second(short *x, short *y, unsigned int bits);
#pragma aux clamp_axis_second "clamp_point_edge_" parm [eax] [edx] [ebx] modify exact [eax];

/* Reuse the outcode intersection and register restore from the general clipper. */
extern unsigned short return_axis_clip_result(void);
#pragma aux return_axis_clip_result aborts modify exact [eax];

unsigned short clip_axis_aligned_line(short *first_x, short *first_y, short *second_x, short *second_y)
{
    volatile struct {
        unsigned int first_bits;
        unsigned char first, first_padding[3];
        unsigned char second, second_padding[3];
    } clip;
    unsigned int start_code, end_code;

    second_x_in_edi(second_x);

    clip.first = axis_first_outcode(*first_y, *first_x);
    load_second_axis_clip_point(*second_x, *second_y);
classify_second:
    clip.second = classify_current_axis_point();
compare_outcodes:
    start_code = first_outcode_in_eax(clip.first);
    end_code = second_outcode_in_ebx(clip.second);
    clip.first_bits = start_code;
    if ((end_code & start_code) || clip.first == clip.second)
        goto result;
    if (!axis_first_outcode_in_al()) {
        clamp_axis_second(axis_second_pointer(), second_y, end_code);
        load_second_axis_clip_point(*axis_second_pointer(), *second_y);
        goto classify_second;
    }
    clamp_axis_first(first_y, clip.first_bits, axis_x_in_eax(first_x));
    load_first_axis_clip_x(*first_x);
    clip.first = classify_first_axis_with_y(*first_y);
    goto compare_outcodes;
result:
    prepare_axis_clip_result(clip.second, clip.first);
    return return_axis_clip_result();
}

/* Keep the original endpoint pointers bound across the signed rounding calculation. */
extern void bind_clip_edge_point(short *x, short *y);
#pragma aux bind_clip_edge_point = "mov esi,eax" "mov edi,edx" parm [eax] [edx] modify exact [esi edi];
extern short *bound_clip_x(void);
#pragma aux bound_clip_x = value [esi] modify exact [];
extern short *bound_clip_y(void);
#pragma aux bound_clip_y = value [edi] modify exact [];
extern int clip_store_in_eax(int x);
#pragma aux clip_store_in_eax = "" parm [eax] value [eax] modify exact [];
extern int axis_distance_to_endpoint(int endpoint, short *position);
#pragma aux axis_distance_to_endpoint = "mov eax,ebx" "cwde" "movsx ebx,word ptr [esi]" "sub eax,ebx" "cdq" "xor eax,edx" "sub eax,edx" parm [ebx] [esi] value [eax] modify exact [eax ebx edx];
extern int intersection_y_in_edx(int pair);
#pragma aux intersection_y_in_edx = "" parm [edx] value [edx] modify exact [];
extern void retain_intersection_distance(int distance);
#pragma aux retain_intersection_distance = "mov ebx,eax" "mov ecx,eax" parm [eax] modify exact [ebx ecx];
extern unsigned long clip_rise_in_edx(unsigned long value);
#pragma aux clip_rise_in_edx = "" parm [edx] value [edx] modify exact [];
extern unsigned long clip_rise_in_eax(unsigned long value);
#pragma aux clip_rise_in_eax = "" parm [eax] value [eax] modify exact [];
extern int divisor_distance(void);
#pragma aux divisor_distance = value [ebx] modify exact [];
extern int divide_intersection_offset(int offset);
#pragma aux divide_intersection_offset = "cdq" "add ecx,ecx" "idiv ecx" parm [eax] value [eax] modify exact [eax ecx edx];
extern int intersection_result_in_ebx(int offset);
#pragma aux intersection_result_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern int abs(int);
#pragma intrinsic(abs);

void intersect_clip_edge(short *x, short *y, int other_x, int other_y, int edge)
{
    volatile struct {
        int original_x, doubled_rise, endpoint_y;
    } endpoint;
    int distance, y_target, rounded, result_y;

    bind_clip_edge_point(x, y);
    endpoint.endpoint_y = other_y;
    distance = axis_distance_to_endpoint(other_x, bound_clip_x());
    y_target = intersection_y_in_edx((short)endpoint.endpoint_y);
    retain_intersection_distance(distance);
    endpoint.doubled_rise = (int)clip_rise_in_eax(clip_rise_in_edx((unsigned long)y_target - (unsigned long)(int)*bound_clip_y()) * 2UL);
    endpoint.original_x = (int)*bound_clip_x();
    rounded = abs((short)edge - endpoint.original_x) * endpoint.doubled_rise;
    /* Bias by half the denominator before the signed division. */
    if (rounded > 0)
        rounded += divisor_distance();
    else
        rounded -= divisor_distance();
    rounded = intersection_result_in_ebx(divide_intersection_offset(rounded));
    result_y = *bound_clip_y() + rounded;
    *bound_clip_y() = (short)clip_store_in_eax(result_y);
    *bound_clip_x() = (short)clip_store_in_eax(edge);
}
