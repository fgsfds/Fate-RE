extern float world_first_min, world_first_max, world_second_min, world_second_max;
extern float first_pixel_scale, second_pixel_scale, first_extent_scale, second_extent_scale;
extern short pixel_first_min, pixel_first_max, pixel_second_min, pixel_second_max;
extern short first_extent, second_extent;
extern short reverse_second_axis;

long map_first_coordinate(double x)
{
    float offset = (float)x - world_first_min;
    short displacement = (long)(offset * first_pixel_scale);
    return (long)displacement + pixel_first_min;
}

short map_second_coordinate(double y)
{
    float offset;
    short displacement;
    if (reverse_second_axis)
        offset = world_second_max - (float)y;
    else
        offset = (float)y - world_second_max;
    displacement = (long)(offset * second_pixel_scale);
    return displacement + pixel_second_min;
}

long map_first_extent(double x)
{
    float scaled = ((float)first_extent * (float)x) * first_extent_scale;
    return (long)scaled;
}


long map_second_extent(double y)
{
    float scaled = ((float)second_extent * (float)y) * second_extent_scale;
    return (long)scaled;
}

void recalculate_coordinate_scales(void)
{
    float first_delta, second_delta;
    first_delta = world_first_max - world_first_min;
    first_pixel_scale = (float)(pixel_first_max - pixel_first_min) / first_delta;
    first_extent_scale = 1.0f / first_delta;
    second_delta = reverse_second_axis ? world_second_max - world_second_min
                                       : world_second_min - world_second_max;
    second_pixel_scale = (float)(pixel_second_max - pixel_second_min) / second_delta;
    second_extent_scale = 1.0f / second_delta;
}
