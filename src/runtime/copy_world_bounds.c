struct graphics_bounds {
    float first_min, second_min, first_max, second_max;
};

extern struct graphics_bounds world_bounds;

/* Preserve ES while returning the structure through the caller's buffer. */
#pragma aux copy_world_bounds modify exact [eax esi];
struct graphics_bounds copy_world_bounds(void)
{
    return world_bounds;
}
