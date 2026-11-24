/* A real two-argument context: count in DL, bit on the stack (RET 4).
 * The menu has at most 32 entries, so the shift count is 0..31. */
unsigned long menu_mask_shift(unsigned char, unsigned long);
#pragma aux menu_mask_shift parm [edx] value [edx] modify exact [edx];
unsigned long menu_mask_shift(unsigned char count, unsigned long bit)
{
    return bit << count;
}
