/* Convert to a single-precision bit pattern without rounding. */
extern void save_scan_register(void);
#pragma aux save_scan_register = "push ecx" modify exact [];
extern void restore_scan_register(void);
#pragma aux restore_scan_register = "pop ecx" modify exact [];
extern void scan_high_bit(void);
#pragma aux scan_high_bit = "bsr ecx,eax" "mov ch,cl" modify exact [ecx];
extern unsigned long eax_value(void);
#pragma aux eax_value = value [eax] modify exact [];
extern void in_eax(unsigned long);
#pragma aux in_eax = parm [eax] modify exact [];
extern unsigned long ecx_value(void);
#pragma aux ecx_value = value [ecx] modify exact [];
extern void in_ecx(unsigned long);
#pragma aux in_ecx = parm [ecx] modify exact [];
extern unsigned char cl_value(void);
#pragma aux cl_value = value [cl] modify exact [];
extern unsigned char ch_value(void);
#pragma aux ch_value = value [ch] modify exact [];
extern void in_cl(unsigned char);
#pragma aux in_cl = parm [cl] modify exact [];
extern unsigned long rotate_left(unsigned long, unsigned char);
#pragma aux rotate_left = "rol eax,cl" parm [eax] [cl] value [eax] modify exact [eax];
extern void skip_zero_float(void);
#pragma aux skip_zero_float = "or eax,eax" "db 74h, 26h" /* marker-rel8 +4,+5 */ modify exact [];

unsigned long u32_to_float(unsigned long);
#pragma aux u32_to_float modify exact [eax ecx];
unsigned long u32_to_float(unsigned long value)
{
    (void)value;
    skip_zero_float();
    save_scan_register();
    scan_high_bit();
    /* Align the highest set bit with the implicit leading mantissa bit. */
    in_cl(-cl_value());
    in_cl(cl_value() + 23);
    in_cl(cl_value() & 31);
    in_eax(rotate_left(eax_value(), cl_value()) & 0x7fffffUL);
    /* Recover the highest set bit and pack the biased exponent. */
    in_cl(ch_value());
    in_cl(cl_value() + 127);
    in_ecx(ecx_value() & 255UL);
    in_ecx(ecx_value() << 23);
    in_eax(eax_value() | ecx_value());
    restore_scan_register();
    return eax_value();
}
