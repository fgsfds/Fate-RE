/* Encode one planar PCX palette byte and return the advanced buffer offset.
 * The existing loop owns branching and buffer flushing. The register-only
 * identities name the legacy byte registers and emit no instructions. */
extern unsigned char capture_buffer[];
extern unsigned char capture_palette16[];
extern unsigned char palette_component(unsigned char);
#pragma aux palette_component = "" parm [dl] value [dl] modify exact [];
extern unsigned char palette_padding(unsigned char);
#pragma aux palette_padding = "" parm [bl] value [bl] modify exact [];
#pragma aux capture_planar_palette parm [ecx] [edi] value [eax];
unsigned capture_planar_palette(int index, unsigned offset)
{
    unsigned next = offset + 1;
    if (index < 48)
        capture_buffer[offset] = palette_component(capture_palette16[index] << 2);
    else
        capture_buffer[offset] = palette_padding(0);
    return next;
}
