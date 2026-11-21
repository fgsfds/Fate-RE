/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
/* These x86 operand bytes select the order of source and destination in the blend-table index. */
extern volatile unsigned char column_framebuffer_operand;
extern volatile unsigned char column_palette_operand;
extern volatile unsigned char sprite_framebuffer_operand;
extern volatile unsigned char sprite_palette_operand;
extern volatile unsigned char span_first_palette_operand;
extern volatile unsigned char span_first_blend_operand;
extern volatile unsigned char span_left_palette_operand;
extern volatile unsigned char span_left_blend_operand;
extern volatile unsigned char span_right_palette_operand;
extern volatile unsigned char span_right_blend_operand;
extern volatile unsigned char pair_tail_framebuffer_operand;
extern volatile unsigned char pair_tail_palette_operand;
extern volatile unsigned char pair_framebuffer_operand;
extern volatile unsigned char pair_pixel_registers;
extern volatile unsigned char pair_left_palette_operand;
extern volatile unsigned char pair_right_palette_operand;
extern volatile unsigned char pair_second_framebuffer_operand;
extern volatile unsigned char pair_second_palette_operand;

void settransnormal(void)
{
    column_framebuffer_operand = 0x83;
    column_palette_operand = 0x27;
    sprite_framebuffer_operand = 0x3f;
    sprite_palette_operand = 0x98;
    span_first_palette_operand = 0x90;
    span_first_blend_operand = 0x37;
    span_left_palette_operand = 0x90;
    span_left_blend_operand = 0xf3;
    span_right_palette_operand = 0x90;
    span_right_blend_operand = 0xf7;
    pair_tail_framebuffer_operand = 0xa7;
    pair_tail_palette_operand = 0x81;
    pair_framebuffer_operand = 0x9f;
    pair_pixel_registers = 0xe3;
    pair_left_palette_operand = 0x81;
    pair_right_palette_operand = 0x9a;
    pair_second_framebuffer_operand = 0xa7;
    pair_second_palette_operand = 0x82;
}

void settransreverse(void)
{
    column_framebuffer_operand = 0xa3;
    column_palette_operand = 0x07;
    sprite_framebuffer_operand = 0x1f;
    sprite_palette_operand = 0xb8;
    span_first_palette_operand = 0xb0;
    span_first_blend_operand = 0x17;
    span_left_palette_operand = 0xb0;
    span_left_blend_operand = 0xd3;
    span_right_palette_operand = 0xb0;
    span_right_blend_operand = 0xd7;
    pair_tail_framebuffer_operand = 0x87;
    pair_tail_palette_operand = 0xa1;
    pair_framebuffer_operand = 0x87;
    pair_pixel_registers = 0xdc;
    pair_left_palette_operand = 0xa1;
    pair_right_palette_operand = 0xba;
    pair_second_framebuffer_operand = 0x87;
    pair_second_palette_operand = 0xa2;
}
