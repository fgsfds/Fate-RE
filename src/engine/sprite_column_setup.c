/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
/* Volatile destinations are instruction operands in the sprite rasterizers.
 * Each entry receives x_increment in ESI and preserves ESI throughout.
 * The no-code retain helper pins that input for the two implicit ESI reads.
 * The copy and add helpers select the original x86 opcode direction.
 */
extern long copy_x_increment(void);
extern void retain_x_increment(long);
#pragma aux retain_x_increment = parm [esi] modify exact [];
#pragma aux copy_x_increment = 0x8b 0xc6 parm [] value [eax] modify exact [eax];
extern unsigned long add_texture_step(unsigned long, unsigned long);
#pragma aux add_texture_step = 0x03 0xc3 parm [eax] [ebx] value [eax] modify exact [eax];
extern unsigned long add_texture_carry(unsigned long, unsigned long);
#pragma aux add_texture_carry = 0x03 0xc2 parm [eax] [edx] value [eax] modify exact [eax];

extern unsigned char * volatile opaque_sprite_palette;
extern unsigned long volatile opaque_sprite_x_fraction_0;
extern unsigned long volatile opaque_sprite_x_fraction_1;
extern unsigned long volatile opaque_sprite_texture_step_0;
extern unsigned long volatile opaque_sprite_texture_step_1;
extern long volatile opaque_sprite_y_step;

#pragma aux setupspritevline parm [eax] [ebx] [edx] [ecx] [esi] value [eax] modify exact [eax];
long setupspritevline(unsigned char *palette, long step, long carry_step, long y_increment, long x_increment)
{
    unsigned long fraction;
    unsigned long texture_step;

    opaque_sprite_palette = palette;
    retain_x_increment(x_increment);
    fraction = (unsigned long)copy_x_increment() << 16;
    opaque_sprite_x_fraction_0 = fraction;
    opaque_sprite_x_fraction_1 = fraction;
    texture_step = add_texture_step(copy_x_increment() >> 16, step);
    opaque_sprite_texture_step_0 = texture_step;
    texture_step = add_texture_carry(texture_step, carry_step);
    opaque_sprite_texture_step_1 = texture_step;
    opaque_sprite_y_step = y_increment;
    return (long)texture_step;
}

extern unsigned char * volatile masked_sprite_palette;
extern unsigned long volatile masked_sprite_x_fraction_0;
extern unsigned long volatile masked_sprite_x_fraction_1;
extern unsigned long volatile masked_sprite_texture_step_0;
extern unsigned long volatile masked_sprite_texture_step_1;
extern long volatile masked_sprite_y_step;

#pragma aux msetupspritevline parm [eax] [ebx] [edx] [ecx] [esi] value [eax] modify exact [eax];
long msetupspritevline(unsigned char *palette, long step, long carry_step, long y_increment, long x_increment)
{
    unsigned long fraction;
    unsigned long texture_step;

    masked_sprite_palette = palette;
    retain_x_increment(x_increment);
    fraction = (unsigned long)copy_x_increment() << 16;
    masked_sprite_x_fraction_0 = fraction;
    masked_sprite_x_fraction_1 = fraction;
    texture_step = add_texture_step(copy_x_increment() >> 16, step);
    masked_sprite_texture_step_0 = texture_step;
    texture_step = add_texture_carry(texture_step, carry_step);
    masked_sprite_texture_step_1 = texture_step;
    masked_sprite_y_step = y_increment;
    return (long)texture_step;
}

extern unsigned char * volatile translucent_sprite_palette;
extern unsigned long volatile translucent_sprite_x_fraction_0;
extern unsigned long volatile translucent_sprite_x_fraction_1;
extern unsigned long volatile translucent_sprite_texture_step_0;
extern unsigned long volatile translucent_sprite_texture_step_1;
extern long volatile translucent_sprite_y_step;

#pragma aux tsetupspritevline parm [eax] [ebx] [edx] [ecx] [esi] value [eax] modify exact [eax];
long tsetupspritevline(unsigned char *palette, long step, long carry_step, long y_increment, long x_increment)
{
    unsigned long fraction;
    unsigned long texture_step;

    translucent_sprite_palette = palette;
    retain_x_increment(x_increment);
    fraction = (unsigned long)copy_x_increment() << 16;
    translucent_sprite_x_fraction_0 = fraction;
    translucent_sprite_x_fraction_1 = fraction;
    texture_step = add_texture_step(copy_x_increment() >> 16, step);
    translucent_sprite_texture_step_0 = texture_step;
    texture_step = add_texture_carry(texture_step, carry_step);
    translucent_sprite_texture_step_1 = texture_step;
    translucent_sprite_y_step = y_increment;
    return (long)texture_step;
}
