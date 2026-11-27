extern unsigned long u32_to_float(unsigned long);
#pragma aux u32_to_float modify exact [eax];

/* Preserve the original short tail transfer to the adjacent unsigned entry. */
extern unsigned long try_unsigned_entry(unsigned long);
#pragma aux try_unsigned_entry = "or eax,eax" "db 79h, 0d1h" parm [eax] value [eax] modify exact [];

unsigned long i32_to_float(long value)
{
    unsigned long bits = try_unsigned_entry((unsigned long)value);
    /* Unsigned negation also represents the magnitude of LONG_MIN. */
    return u32_to_float(0UL - bits) | 0x80000000UL;
}
