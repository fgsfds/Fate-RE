/* Approximate the signed square root using the original x87 rounding and table. */
extern volatile unsigned long sqrt_float_bits;
extern long sqrt_lookup[];

/* Capture the integer sign as a mask while the x87 writes binary32 bits. */
extern long capture_sqrt_bits(long);
#pragma aux capture_sqrt_bits = \
    "mov dword ptr sqrt_float_bits, eax" \
    "fild dword ptr sqrt_float_bits" \
    "add eax, eax" \
    "fstp dword ptr sqrt_float_bits" \
    "sbb ebx, ebx" \
    parm [eax] value [ebx] modify exact [eax ebx];

/* Keep the exponent in ECX and select the original subtract/shift sequence. */
extern unsigned long hold_exponent_bits(unsigned long);
#pragma aux hold_exponent_bits = parm [ecx] value [ecx] modify exact [];
extern unsigned long sqrt_exponent_shift(unsigned long);
#pragma aux sqrt_exponent_shift = \
    "sub ecx, 3f800000h" "shr ecx, 23" \
    parm [ecx] value [ecx] modify exact [ecx];

/* SAR uses the low five bits of the shift count for every input. */
extern long shift_sqrt_estimate(long, unsigned long);
#pragma aux shift_sqrt_estimate = "sar eax, cl" parm [eax] [ecx] value [eax] modify exact [eax];

long nsqrt(long number)
{
    long sign_mask = capture_sqrt_bits(number);
    unsigned long bits = sqrt_float_bits;
    unsigned long shift = hold_exponent_bits(bits);
    /* The fraction bits index four-byte table entries. */
    unsigned long byte_offset = (bits & 0x7ff000UL) >> 10;

    shift = sqrt_exponent_shift(shift);
    return shift_sqrt_estimate(*(const long *)((const char *)sqrt_lookup + byte_offset),
                               shift) ^ sign_mask;
}
