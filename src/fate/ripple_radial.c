/* In-place frame ABI: EBP is slot at setup, Y at sample; ESP+8/+12 are amplitude/X. */
#define RADIAL_SIDE 128U
#define RADIAL_CAPACITY (32U * RADIAL_SIDE)

extern unsigned int radial_x_offsets[RADIAL_CAPACITY];
extern unsigned int radial_y_offsets[RADIAL_CAPACITY];

/* Retained radial setup initializes EBP from the current ring's Y
 * origin. No instruction on a sample back-edge changes EBP. */
extern unsigned int radial_y_from_ebp(void);
#pragma aux radial_y_from_ebp = "" parm [] value [ebp] modify exact [];

extern unsigned int radial_word_eax(unsigned int);
#pragma aux radial_word_eax = "" parm [eax] value [eax] modify exact [];
extern unsigned int radial_word_ebx(unsigned int);
#pragma aux radial_word_ebx = "" parm [ebx] value [ebx] modify exact [];
extern unsigned int radial_offset_ecx(unsigned int);
#pragma aux radial_offset_ecx = "" parm [ecx] value [ecx] modify exact [];
extern unsigned char *radial_pixel_ecx(unsigned char *);
#pragma aux radial_pixel_ecx = "" parm [ecx] value [ecx] modify exact [];
extern unsigned char radial_amplitude_al(unsigned char);
#pragma aux radial_amplitude_al = "" parm [al] value [al] modify exact [];

/* The standalone RET occupies the unused frame index slot in this
 * comparison context. The untouched output slot is the first stack
 * argument. Amplitude and X therefore use the original +8 and +12. */
unsigned char *ripple_radial_sample(unsigned int, unsigned int, unsigned char *,
                                    unsigned int, unsigned int, unsigned int);
#pragma aux ripple_radial_sample parm caller [edi] [esi] [edx] [] \
    value [ecx] modify exact [eax ebx ecx];

unsigned char *ripple_radial_sample(unsigned int radius, unsigned int sample,
                                    unsigned char *texture, unsigned int unused,
                                    unsigned int amplitude, unsigned int origin_x)
{
    unsigned int x = radial_word_eax(radius);
    unsigned int offset = radial_offset_ecx(sample);
    unsigned int y;
    unsigned char *pixel;

    x = radial_word_eax(x << 9);
    offset = radial_offset_ecx(offset << 2);
    offset = radial_offset_ecx(offset + x);
    origin_x = radial_word_ebx(origin_x);
    x = radial_word_eax(*(const unsigned int *)(
        (const unsigned char *)&radial_x_offsets + offset));
    x = radial_word_eax(x + origin_x);
    y = radial_word_ebx(*(const unsigned int *)(
        (const unsigned char *)&radial_y_offsets + offset));
    x = radial_word_eax(x & 127U);
    y = radial_word_ebx(y + radial_y_from_ebp());
    x = radial_word_eax(x << 7);
    y = radial_word_ebx(y & 127U);
    x = radial_word_eax(x + y);
    pixel = radial_pixel_ecx(texture + x);
    *pixel += radial_amplitude_al((unsigned char)amplitude);
    return pixel;
}

extern int ripple_radius[32], ripple_origin_x[32];
extern int ripple_speed[], radial_sample_count[];

/* The original predecessor assigns EBP from EAX at 0x2ebda.
 * The ABI context receives that slot in both registers. */
extern int radial_slot_from_ebp(void);
#pragma aux radial_slot_from_ebp = "" parm [] value [ebp] modify exact [];

extern unsigned int setup_word_eax(unsigned int);
#pragma aux setup_word_eax = "" parm [eax] value [eax] modify exact [];
extern int setup_index_eax(int);
#pragma aux setup_index_eax = "" parm [eax] value [eax] modify exact [];
extern unsigned int setup_sign_ebx(unsigned int);
#pragma aux setup_sign_ebx = "" parm [ebx] value [ebx] modify exact [];
extern int setup_radius_edi(int);
#pragma aux setup_radius_edi = "" parm [edi] value [edi] modify exact [];
extern int setup_sample_esi(int);
#pragma aux setup_sample_esi = "" parm [esi] value [esi] modify exact [];

/* Return the descending sample index in ESI and leave the X origin and
 * radius in EAX and EDI for the retained Y-origin load and sample test. */
extern int setup_handoff(int, unsigned int, int);
#pragma aux setup_handoff = "" parm [esi] [eax] [edi] value [esi] modify exact [];

int ripple_radial_setup(int, unsigned int, unsigned int, unsigned int);
#pragma aux ripple_radial_setup parm caller [eax] [] \
    value [esi] modify exact [eax ebx esi edi];

int ripple_radial_setup(int slot, unsigned int unused, volatile unsigned int amplitude_slot,
                        volatile unsigned int origin_x_slot)
{
    int saved_slot = radial_slot_from_ebp();
    unsigned int sign = setup_sign_ebx((unsigned int)saved_slot);
    int speed_radius, radius, sample;
    unsigned int amplitude, origin_x;

    sign = setup_sign_ebx(sign & 1U);
    speed_radius = setup_index_eax(*(const volatile int *)&ripple_radius[slot]);
    sign = setup_sign_ebx(sign + sign);
    amplitude = setup_word_eax((unsigned int)ripple_speed[speed_radius]);
    sign = setup_sign_ebx(sign - 1U);
    amplitude = setup_word_eax(amplitude * sign);
    radius = setup_radius_edi(*(const volatile int *)&ripple_radius[saved_slot]);
    sample = setup_sample_esi(radial_sample_count[radius]);
    amplitude_slot = amplitude;
    origin_x = setup_word_eax((unsigned int)ripple_origin_x[saved_slot]);
    sample = setup_sample_esi(sample - 1);
    origin_x_slot = origin_x;
    return setup_handoff(sample, origin_x, radius);
}
