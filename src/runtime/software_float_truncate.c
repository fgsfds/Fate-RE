extern unsigned long truncate_magnitude(unsigned long);
#pragma aux truncate_magnitude parm [eax] modify exact [eax ecx];
/* Nonnegative inputs enter the adjacent magnitude code directly. */
extern unsigned long route_truncation(unsigned long);
#pragma aux route_truncation = "or eax,eax" "db 79h, 08h" parm [eax] value [eax] modify exact [];
unsigned long truncate_float(unsigned long bits);
#pragma aux truncate_float parm [eax] modify exact [eax ecx];
unsigned long truncate_float(unsigned long bits)
{
    return 0UL - truncate_magnitude(route_truncation(bits));
}

extern unsigned long eax_value(void);
#pragma aux eax_value = value [eax] modify exact [];
extern void in_eax(unsigned long);
#pragma aux in_eax = parm [eax] modify exact [];
extern unsigned char cl_value(void);
#pragma aux cl_value = value [cl] modify exact [];
extern unsigned char ch_value(void);
#pragma aux ch_value = value [ch] modify exact [];
extern void in_cl(unsigned char);
#pragma aux in_cl = parm [cl] modify exact [];
extern void in_ch(unsigned char);
#pragma aux in_ch = parm [ch] modify exact [];


/* The original entry stages use the processor's CL-count shifts. */
extern unsigned long shift_magnitude_right(void);
#pragma aux shift_magnitude_right = "shr eax,cl" value [eax] modify exact [eax];
extern unsigned long shift_magnitude_left(void);
#pragma aux shift_magnitude_left = "shl eax,cl" value [eax] modify exact [eax];
extern unsigned long shift_saturation_mask(void);
#pragma aux shift_saturation_mask = "shr eax,cl" value [eax] modify exact [eax];

extern void skip_empty_float(void);
#pragma aux skip_empty_float = "or eax,eax" "db 74h, 35h" modify exact [];
/* Recover the exponent and restore the implicit significand bit. */
extern void expose_exponent(void);
#pragma aux expose_exponent = "rol eax,8" "cmp al,7fh" "db 72h, 2ch" "mov ch,al" "stc" "rcr eax,1" modify exact [eax ecx];
extern void branch_overflow(void);
#pragma aux branch_overflow = "cmp ch,cl" "db 73h, 13h" modify exact [];
extern void branch_left_shift(void);
#pragma aux branch_left_shift = "db 73h, 07h" modify exact [];
extern void swap_shift_bytes(void);
#pragma aux swap_shift_bytes = "xchg ch,cl" modify exact [ecx];

#pragma aux truncate_magnitude parm [eax] modify exact [eax ecx];
unsigned long truncate_magnitude(unsigned long bits)
{
    (void)bits;
    skip_empty_float();
    in_eax(eax_value() + eax_value());
    expose_exponent();
    in_eax(eax_value() >> 8);
    branch_overflow();
    in_ch(ch_value() - 150);
    branch_left_shift();
    swap_shift_bytes();
    in_cl(-cl_value());
    return shift_magnitude_right();
}

extern void skip_zero_shift(void);
#pragma aux skip_zero_shift = "db 74h, 04h" /* marker-rel8 +1,+2 */ modify exact [];
unsigned long truncate_shift_left(void);
#pragma aux truncate_shift_left modify exact [eax ecx];
unsigned long truncate_shift_left(void)
{
    skip_zero_shift();
    in_cl(ch_value());
    return shift_magnitude_left();
}

unsigned long truncate_limit(void);
#pragma aux truncate_limit modify exact [eax ecx];
unsigned long truncate_limit(void)
{
    in_eax(0xffffffffUL);
    in_cl(cl_value() - 159);
    in_cl(-cl_value());
    return shift_saturation_mask();
}

/* Zero the result register: the original routine clears the value in EAX. */
extern void truncate_float_zero_body(void);
#pragma aux truncate_float_zero_body = 0x29 0xc0 modify exact [eax];
void truncate_float_zero(void);
#pragma aux truncate_float_zero modify exact [eax];
void truncate_float_zero(void)
{
    truncate_float_zero_body();
}
