/* Preserve the original Watcom argument and result-buffer registers. */
extern short x_in_cx(short x);
#pragma aux x_in_cx = "" parm [cx] value [cx] modify exact [];
typedef struct { double x, y; } WorldPoint;
extern short viewport_origin_x, viewport_origin_y;
extern short pixel_first_min, pixel_first_max, pixel_second_min, pixel_second_max;
extern short reverse_second_axis;
extern float world_first_min, world_first_max, world_second_min, world_second_max;
extern short graphics_available(void);
/* Keep the incoming Y out of ESI across this call. */
#pragma aux graphics_available modify exact [eax esi];

#pragma aux unmap_coordinate_pair modify exact [eax esi edx];
WorldPoint unmap_coordinate_pair(short x, short y)
{
    WorldPoint point;
    float scaled_y;
    if (graphics_available()) {
        point.x = world_first_min
            + (world_first_max - world_first_min) * (float)(x_in_cx(x) + viewport_origin_x - pixel_first_min)
            / (float)(pixel_first_max - pixel_first_min);
        scaled_y = (float)(y + viewport_origin_y - pixel_second_min)
            / (float)(pixel_second_max - pixel_second_min);
        if (reverse_second_axis)
            point.y = world_second_max - scaled_y * (world_second_max - world_second_min);
        else
            point.y = scaled_y * (world_second_min - world_second_max) + world_second_max;
    } else {
        point.x = 0.0;
        point.y = 0.0;
    }
    return point;
}
