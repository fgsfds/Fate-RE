/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
/* Each destination names an operand in the reverse span renderer. */
extern volatile unsigned long reverse_fraction_step;
extern volatile unsigned long reverse_texel_step;
extern volatile unsigned long reverse_second_sample_0, reverse_second_sample_1;
extern volatile unsigned long reverse_pair_fraction_0, reverse_pair_fraction_1;
extern volatile unsigned long reverse_pair_texel_0, reverse_pair_texel_1;
extern const unsigned char * volatile reverse_palette_0, * volatile reverse_palette_1;
extern const unsigned char * volatile reverse_palette_2, * volatile reverse_palette_3;
extern const unsigned char * volatile reverse_palette_single;

/* ECX still holds the texel step. Use the original XOR/SUB encodings
 * to return the negative offset in EDI for the second sample of each pair.
 */
extern unsigned long reverse_negated_step(void);
#pragma aux reverse_negated_step = 0x33 0xff 0x2b 0xf9 parm [] value [edi] modify exact [edi];

/* Double the two-word step with ADD/ADC. Read its high word back from ECX. */
extern unsigned long reverse_double_fraction(unsigned long, unsigned long);
#pragma aux reverse_double_fraction = 0x03 0xdb 0x13 0xc9 parm [ebx] [ecx] value [ebx] modify exact [ebx ecx];
extern unsigned long reverse_doubled_texels(void);
#pragma aux reverse_doubled_texels = parm [] value [ecx] modify exact [];

#pragma aux setup_sprite_horizontal_reverse parm [ebx] [ecx] [edx] modify exact [ebx ecx edi];
void setup_sprite_horizontal_reverse(unsigned long fraction, unsigned long texels,
                                     const unsigned char *palette)
{
    unsigned long second_sample;

    reverse_fraction_step = fraction;
    reverse_texel_step = texels;
    second_sample = reverse_negated_step();
    reverse_second_sample_0 = second_sample;
    reverse_second_sample_1 = second_sample;
    fraction = reverse_double_fraction(fraction, texels);
    texels = reverse_doubled_texels();
    reverse_pair_fraction_0 = fraction;
    reverse_pair_fraction_1 = fraction;
    reverse_pair_texel_0 = texels;
    reverse_pair_texel_1 = texels;
    reverse_palette_0 = palette;
    reverse_palette_1 = palette;
    reverse_palette_2 = palette;
    reverse_palette_3 = palette;
    reverse_palette_single = palette;
}
