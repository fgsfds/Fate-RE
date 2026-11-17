/* VGA controller register number in AL and value in AH. */
extern void write_graphics_controller(int value, short port);
#pragma aux write_graphics_controller = "out dx,ax" parm [eax] [edx] modify exact [];

extern short drawing_action;
extern const unsigned char planar_action_bits[];

#define VGA_GRAPHICS_CONTROLLER_PORT 0x3ce

/* Watcom shares the controller writes after the mode is selected. */
#define DEFINE_BEGIN_PLANAR_DRAWING(name, mode)                                     \
void name(void)                                                                     \
{                                                                                   \
    write_graphics_controller(mode, VGA_GRAPHICS_CONTROLLER_PORT);                  \
    write_graphics_controller(((unsigned)planar_action_bits[drawing_action] << 8) + 3, \
                              VGA_GRAPHICS_CONTROLLER_PORT);                        \
}

DEFINE_BEGIN_PLANAR_DRAWING(begin_planar_drawing, 0x0205)
DEFINE_BEGIN_PLANAR_DRAWING(begin_interleaved_planar_drawing, 0x1205)

#undef DEFINE_BEGIN_PLANAR_DRAWING

#define DEFINE_END_PLANAR_DRAWING(name, mode)                                       \
void name(void)                                                                     \
{                                                                                   \
    write_graphics_controller(mode, VGA_GRAPHICS_CONTROLLER_PORT);                  \
    write_graphics_controller(0xff08, VGA_GRAPHICS_CONTROLLER_PORT);                \
    write_graphics_controller(0x0f07, VGA_GRAPHICS_CONTROLLER_PORT);                \
    write_graphics_controller(0x0003, VGA_GRAPHICS_CONTROLLER_PORT);                \
}

DEFINE_END_PLANAR_DRAWING(end_planar_drawing, 0x0005)
DEFINE_END_PLANAR_DRAWING(end_interleaved_planar_drawing, 0x1005)

#undef DEFINE_END_PLANAR_DRAWING
