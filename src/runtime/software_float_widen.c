/* The runtime entry takes EAX and returns the two words in EDX:EAX. */
/* Zero and infinity jump to the shared return with their result in place. */
extern void route_zero(unsigned long);
#pragma aux route_zero = "mov edx,eax" "and edx,7fffffffh" "jne short nonzero" "db 0ebh, 49h" /* marker-rel8 +4,+5 */ "nonzero:" parm [eax] modify exact [edx];
extern void pack_infinity(void);
#pragma aux pack_infinity = "mov edx,eax" "or edx,7ff00000h" "sub eax,eax" "db 0ebh, 35h" /* marker-rel8 +3,+4 */ aborts modify exact [eax edx];

extern unsigned long magnitude(void);
#pragma aux magnitude = value [edx] modify exact [];
extern void in_edx(unsigned long);
#pragma aux in_edx = parm [edx] modify exact [];
extern void begin_subnormal(void);
#pragma aux begin_subnormal = "xor eax,edx" "push ecx" "sub ecx,ecx" modify exact [eax ecx];
extern unsigned long exponent_adjustment(void);
#pragma aux exponent_adjustment = value [ecx] modify exact [];
extern void in_ecx(unsigned long);
#pragma aux in_ecx = parm [ecx] modify exact [];
extern void finish_subnormal(void);
#pragma aux finish_subnormal = "or eax,edx" "sub edx,ecx" "pop ecx" modify exact [eax edx];
/* Carry moves the sign bit from the low word into the high word. */
extern void pack_significand(void);
#pragma aux pack_significand = "sar edx,2" "add eax,eax" "rcr edx,1" "and eax,0eh" "ror eax,4" modify exact [eax edx];

void float_to_double(unsigned long);
#pragma aux float_to_double parm [eax] modify exact [eax ecx edx];
void float_to_double(unsigned long bits)
{
    route_zero(bits);
    if (magnitude() == 0x7f800000UL)
        pack_infinity();
    if (!(magnitude() & 0x7f800000UL)) {
        begin_subnormal();
        do {
            in_ecx(exponent_adjustment() + 0x00800000UL);
            in_edx(magnitude() + magnitude());
        } while (!(magnitude() & 0x00800000UL));
        finish_subnormal();
    }
    pack_significand();
    in_edx(magnitude() + 0x38000000UL);
}
