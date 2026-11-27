/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
/* These volatile symbols are instruction operands in the original rasterizer. */

extern unsigned char volatile translucent_column_shift;

void setuptvlineasm(unsigned char shift)
{
    translucent_column_shift = shift;
}

extern unsigned char volatile previous_column_shift;
extern unsigned char volatile opaque_column_shift;
extern unsigned char volatile opaque_group_shift_3;
extern unsigned char volatile opaque_group_shift_2;
extern unsigned char volatile opaque_group_shift_1;
extern unsigned char volatile opaque_group_shift_0;

void setupvlineasm(unsigned char shift)
{
    previous_column_shift = shift;
    opaque_column_shift = shift;
    opaque_group_shift_3 = shift;
    opaque_group_shift_2 = shift;
    opaque_group_shift_1 = shift;
    opaque_group_shift_0 = shift;
}

extern unsigned char volatile masked_column_shift;
extern unsigned char volatile masked_group_shift_3;
extern unsigned char volatile masked_group_shift_2;
extern unsigned char volatile masked_group_shift_1;
extern unsigned char volatile masked_group_shift_0;

void setupmvlineasm(unsigned char shift)
{
    masked_column_shift = shift;
    masked_group_shift_3 = shift;
    masked_group_shift_2 = shift;
    masked_group_shift_1 = shift;
    masked_group_shift_0 = shift;
}

extern unsigned char * volatile column_blend_table;
extern unsigned char * volatile span_blend_table_0;
extern unsigned char * volatile span_blend_table_1;
extern unsigned char * volatile span_blend_table_2;
extern unsigned char * volatile sprite_blend_table;
extern unsigned char * volatile paired_column_blend_table_0;
extern unsigned char * volatile paired_column_blend_table_1;
extern unsigned char * volatile paired_column_blend_table_2;
extern unsigned char * volatile paired_column_blend_table_3;

void fixtransluscence(unsigned char *table)
{
    column_blend_table = table;
    span_blend_table_0 = table;
    span_blend_table_1 = table;
    span_blend_table_2 = table;
    sprite_blend_table = table;
    paired_column_blend_table_0 = table;
    paired_column_blend_table_1 = table;
    paired_column_blend_table_2 = table;
    paired_column_blend_table_3 = table;
}

extern unsigned char * volatile opaque_span_palette_0;
extern unsigned char * volatile opaque_span_palette_1;
extern unsigned char * volatile opaque_span_palette_2;
extern unsigned char * volatile opaque_span_palette_3;
extern unsigned char * volatile opaque_span_palette_4;
extern unsigned char * volatile opaque_span_palette_5;
extern unsigned char * volatile opaque_span_palette_6;

void setpalookupaddress(unsigned char *palette)
{
    opaque_span_palette_0 = palette;
    opaque_span_palette_1 = palette;
    opaque_span_palette_2 = palette;
    opaque_span_palette_3 = palette;
    opaque_span_palette_4 = palette;
    opaque_span_palette_5 = palette;
    opaque_span_palette_6 = palette;
}

extern long volatile previous_column_pitch;
extern long volatile opaque_column_pitch;
extern long volatile masked_column_pitch;
extern long volatile translucent_column_pitch;
extern long volatile opaque_sprite_pitch;
extern long volatile masked_sprite_pitch;
extern long volatile translucent_sprite_pitch;
extern long volatile opaque_group_pitch;
extern long volatile masked_group_pitch_0;
extern long volatile masked_group_pitch_1;
extern long volatile paired_column_pitch_0;
extern long volatile paired_column_pitch_1;
extern long volatile paired_column_pitch_2;
extern long volatile paired_column_pitch_3;
extern long volatile paired_column_pitch_4;

void setvlinebpl(long pitch)
{
    previous_column_pitch = pitch;
    opaque_column_pitch = pitch;
    masked_column_pitch = pitch;
    translucent_column_pitch = pitch;
    opaque_sprite_pitch = pitch;
    masked_sprite_pitch = pitch;
    translucent_sprite_pitch = pitch;
    opaque_group_pitch = pitch;
    masked_group_pitch_0 = pitch;
    masked_group_pitch_1 = pitch;
    paired_column_pitch_0 = pitch;
    paired_column_pitch_1 = pitch;
    paired_column_pitch_2 = pitch;
    paired_column_pitch_3 = pitch;
    paired_column_pitch_4 = pitch;
}

extern unsigned char volatile paired_column_shift_0;
extern unsigned char volatile paired_column_shift_1;
extern unsigned char * volatile paired_column_left_palette_0;
extern unsigned char * volatile paired_column_right_palette_0;
extern unsigned char * volatile paired_column_left_palette_1;
extern unsigned char * volatile paired_column_right_palette_1;

#pragma aux setuptvlineasm2 parm [eax] [ebx] [ecx] modify exact [];
void setuptvlineasm2(unsigned char shift, unsigned char *left_palette, unsigned char *right_palette)
{
    paired_column_shift_0 = shift;
    paired_column_shift_1 = shift;
    paired_column_left_palette_0 = left_palette;
    paired_column_right_palette_0 = right_palette;
    paired_column_left_palette_1 = left_palette;
    paired_column_right_palette_1 = right_palette;
}

extern unsigned long volatile masked_span_u_step;
extern long volatile masked_span_texture_step;
extern unsigned char * volatile masked_span_palette;
extern long volatile masked_span_u_carry_step;
extern unsigned long volatile masked_span_v_step;

#pragma aux setup_sprite_horizontal_masked parm [eax] [ebx] [ecx] [edx] [esi] modify exact [];
void setup_sprite_horizontal_masked(unsigned long u_step, long texture_step, unsigned char *palette, long u_carry_step, unsigned long v_step)
{
    masked_span_u_step = u_step;
    masked_span_texture_step = texture_step;
    masked_span_palette = palette;
    masked_span_u_carry_step = u_carry_step;
    masked_span_v_step = v_step;
}

extern unsigned char volatile masked_span_x_shift_0;
extern unsigned char volatile masked_span_y_shift_0;
extern unsigned char volatile masked_span_x_shift_1;
extern unsigned char volatile masked_span_y_shift_1;
extern unsigned char volatile masked_span_x_shift_2;
extern unsigned char volatile masked_span_y_shift_2;

#pragma aux msethlineshift parm [eax] [ebx] modify exact [eax];
void msethlineshift(unsigned char x_shift, unsigned char y_shift)
{
    x_shift = -x_shift;
    masked_span_x_shift_0 = x_shift;
    masked_span_y_shift_0 = y_shift;
    masked_span_x_shift_1 = x_shift;
    masked_span_y_shift_1 = y_shift;
    masked_span_x_shift_2 = x_shift;
    masked_span_y_shift_2 = y_shift;
}

extern unsigned char volatile translucent_span_x_shift_0;
extern unsigned char volatile translucent_span_y_shift_0;
extern unsigned char volatile translucent_span_x_shift_1;
extern unsigned char volatile translucent_span_y_shift_1;
extern unsigned char volatile translucent_span_x_shift_2;
extern unsigned char volatile translucent_span_y_shift_2;

#pragma aux tsethlineshift parm [eax] [ebx] modify exact [eax];
void tsethlineshift(unsigned char x_shift, unsigned char y_shift)
{
    x_shift = -x_shift;
    translucent_span_x_shift_0 = x_shift;
    translucent_span_y_shift_0 = y_shift;
    translucent_span_x_shift_1 = x_shift;
    translucent_span_y_shift_1 = y_shift;
    translucent_span_x_shift_2 = x_shift;
    translucent_span_y_shift_2 = y_shift;
}

extern unsigned long volatile unrolled_span_u_step_0;
extern unsigned long volatile unrolled_span_u_step_1;
extern unsigned long volatile unrolled_span_u_step_2;
extern unsigned long volatile unrolled_span_u_step_3;
extern unsigned long volatile unrolled_span_u_step_4;
extern long volatile unrolled_span_texture_step_0;
extern long volatile unrolled_span_texture_step_1;
extern long volatile unrolled_span_texture_step_2;
extern long volatile unrolled_span_texture_step_3;
extern long volatile unrolled_span_texture_step_4;
extern unsigned char * volatile unrolled_span_palette_0;
extern unsigned char * volatile unrolled_span_palette_1;
extern unsigned char * volatile unrolled_span_palette_2;
extern unsigned char * volatile unrolled_span_palette_3;
extern unsigned char * volatile unrolled_span_palette_4;
extern long volatile unrolled_span_u_carry_step_0;
extern long volatile unrolled_span_u_carry_step_1;
extern long volatile unrolled_span_u_carry_step_2;
extern long volatile unrolled_span_u_carry_step_3;
extern long volatile unrolled_span_u_carry_step_4;
extern unsigned long volatile unrolled_span_v_step_0;
extern unsigned long volatile unrolled_span_v_step_1;
extern unsigned long volatile unrolled_span_v_step_2;
extern unsigned long volatile unrolled_span_v_step_3;
extern unsigned long volatile unrolled_span_v_step_4;

#pragma aux setup_sprite_horizontal_unrolled parm [eax] [ebx] [ecx] [edx] [esi] modify exact [];
void setup_sprite_horizontal_unrolled(unsigned long u_step, long texture_step, unsigned char *palette,
                                      long u_carry_step, unsigned long v_step)
{
    unrolled_span_u_step_0 = u_step;
    unrolled_span_u_step_1 = u_step;
    unrolled_span_u_step_2 = u_step;
    unrolled_span_u_step_3 = u_step;
    unrolled_span_u_step_4 = u_step;
    unrolled_span_texture_step_0 = texture_step;
    unrolled_span_texture_step_1 = texture_step;
    unrolled_span_texture_step_2 = texture_step;
    unrolled_span_texture_step_3 = texture_step;
    unrolled_span_texture_step_4 = texture_step;
    unrolled_span_palette_0 = palette;
    unrolled_span_palette_1 = palette;
    unrolled_span_palette_2 = palette;
    unrolled_span_palette_3 = palette;
    unrolled_span_palette_4 = palette;
    unrolled_span_u_carry_step_0 = u_carry_step;
    unrolled_span_u_carry_step_1 = u_carry_step;
    unrolled_span_u_carry_step_2 = u_carry_step;
    unrolled_span_u_carry_step_3 = u_carry_step;
    unrolled_span_u_carry_step_4 = u_carry_step;
    unrolled_span_v_step_0 = v_step;
    unrolled_span_v_step_1 = v_step;
    unrolled_span_v_step_2 = v_step;
    unrolled_span_v_step_3 = v_step;
    unrolled_span_v_step_4 = v_step;
}
