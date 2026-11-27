/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

extern long qsetmode, ydim16, pageoffset;
extern unsigned char pow2long[];

/* Preserve the register frame consumed by the shared graphics return. */
extern long pixel16_entry(long address);
#pragma aux pixel16_entry = "push ebx" "push ecx" "push edx" "push esi" "push edi" \
    "mov ebx,eax" parm [eax] value [eax] modify exact [ebx];
extern long planar_mask_slot(long index);
#pragma aux planar_mask_slot = "mov esi,eax" "shl esi,2" parm [eax] value [esi] modify exact [esi];
extern void load_planar_mode(long mode);
#pragma aux load_planar_mode = "" parm [edx] modify exact [];
extern long current_planar_mode(void);
#pragma aux current_planar_mode = value [edx] modify exact [];
extern void load_planar_mask(long mask);
#pragma aux load_planar_mask = "" parm [esi] modify exact [];
extern long planar_pixel_address(void);
#pragma aux planar_pixel_address = value [ebx] modify exact [];
extern long planar_address_in_ebx(long address);
#pragma aux planar_address_in_ebx = "" parm [ebx] value [ebx] modify exact [];
/* VGA read-map selection and byte reads at the planar aperture. */
extern long vga_select_read_map(long address);
#pragma aux vga_select_read_map = "mov eax,4" "mov edx,3ceh" "sar ebx,3" "out dx,al" \
    "mov edx,3cfh" parm [ebx] value [ebx] modify exact [eax ebx edx];
extern long vga_read_plane_zero(long address);
#pragma aux vga_read_plane_zero = "xor eax,eax" "lea edi,[ebx+0a0000h]" "out dx,al" \
    "mov al,[edi]" "and eax,esi" "test eax,eax" "setg al" "mov ecx,eax" \
    parm [ebx] value [ecx] modify exact [eax ecx edi];
extern long vga_read_plane(long plane, long address);
#pragma aux vga_read_plane = "lea edi,[ebx+0a0000h]" "out dx,al" "mov al,[edi]" "and eax,esi" \
    parm [eax] [ebx] value [eax] modify exact [eax edi];

extern long planar_active_bit(long sample);
#pragma aux planar_active_bit = "test eax,eax" "setg al" parm [eax] value [eax] modify exact [eax];
extern long planar_low_byte_in_ecx(long pixel);
#pragma aux planar_low_byte_in_ecx = "and ecx,0ffh" parm [ecx] value [ecx] modify exact [ecx];
extern void finish_planar_pixel(long pixel);
#pragma aux finish_planar_pixel aborts parm [eax] modify exact [];
#pragma aux readpixel16 modify exact [eax ebx ecx edx esi edi];

long readpixel16(long address)
{
    long index = (pixel16_entry(address) & 7) ^ 7;
    long slot = planar_mask_slot(index);
    long offset, pixel, sample;

    load_planar_mode(qsetmode);
    load_planar_mask(*(long *)(pow2long + slot));

    /* The split-screen area restarts at the aperture base. */
    if (current_planar_mode() == 480 && ydim16 <= 336 && planar_pixel_address() >= 0x34800L)
        offset = planar_address_in_ebx(planar_pixel_address() - 0x34800L);
    else
        offset = planar_address_in_ebx(planar_pixel_address() + pageoffset);
    offset = vga_select_read_map(offset);

    /* Each of the four VGA planes contributes one color bit. */
    pixel = vga_read_plane_zero(offset);
    sample = vga_read_plane(1, offset);
    pixel = planar_low_byte_in_ecx(pixel);
    pixel += 2 * (planar_active_bit(sample) & 255);
    sample = vga_read_plane(2, offset);
    pixel += 4 * (planar_active_bit(sample) & 255);
    sample = vga_read_plane(3, offset);
    pixel += 8 * (planar_active_bit(sample) & 255);
    finish_planar_pixel(pixel);
    return 0;
}
