
/* These helpers return IEEE-754 single-precision bit patterns in EAX. */
unsigned long float_positive_zero(void)
{
    return 0UL;
}

unsigned long float_largest_finite(unsigned long sign_bits);
#pragma aux float_largest_finite parm [eax] value [eax] modify exact [eax];

unsigned long float_largest_finite(unsigned long sign_bits)
{
    return (sign_bits & 0x80000000UL) | 0x7f7fffffUL;
}
