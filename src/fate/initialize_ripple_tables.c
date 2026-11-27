extern int radial_sample_count[];
extern unsigned int radial_x_offsets[32 * 128], radial_y_offsets[32 * 128];
extern int ripple_speed[];
extern unsigned char ripple_wave[];
extern int ripple_count, ripple_frame;
extern int ripple_sqrt(int);
#pragma aux ripple_sqrt "ksqrt_" modify exact [eax];

extern int keep_radius_offset(int);
#pragma aux keep_radius_offset = "" parm [ebx] value [ebx] modify exact [];
extern int keep_sample_count(int);
#pragma aux keep_sample_count = "" parm [esi] value [esi] modify exact [];
extern int keep_ripple_zero(int);
#pragma aux keep_ripple_zero = "" parm [ecx] value [ecx] modify exact [];

/* klabs from Build Engine & Tools, Copyright (c) 1993-1997 Ken Silverman.
   Used under the Build source code license. */
extern long klabs(long);
#pragma aux klabs = "test eax,eax" "jns skipnegate" "neg eax" "skipnegate:" parm nomemory [eax] value [eax] modify exact [eax];

extern int hold_wave_amplitude(int);
#pragma aux hold_wave_amplitude = "" parm [eax] value [eax] modify exact [];

extern int keep_ripple_x(int);
#pragma aux keep_ripple_x = "" parm [ecx] value [ecx] modify exact [];
extern int keep_ripple_y(int);
#pragma aux keep_ripple_y = "" parm [edx] value [edx] modify exact [];

/* Preserve the original indexed stores and return each coordinate unchanged.
   The EDI annotations keep Watcom from choosing EDI as an index. The stores
   preserve EDI and the executable comparison enforces the original ABI. */
extern int write_x_offset(int, int, int);
#pragma aux write_x_offset = "mov dword ptr [ebx+esi*4+radial_x_offsets],ecx" parm [ebx] [esi] [ecx] value [ecx] modify exact [edi];
extern int write_y_offset(int, int, int);
#pragma aux write_y_offset = "mov dword ptr [ebx+esi*4+radial_y_offsets],edx" parm [ebx] [esi] [edx] value [edx] modify exact [edi];

extern int hold_radius(int);
#pragma aux hold_radius = "" parm [eax] value [eax] modify exact [];

void initialize_ripple_tables(void);
#pragma aux initialize_ripple_tables modify exact [eax edi];

void initialize_ripple_tables(void)
{
    int x, y, index;

    x = keep_ripple_x(-16);
    goto test_x;
    do {
        y = keep_ripple_y(-16);
        goto test_y;
        do {
            int radius = ripple_sqrt(x * x + y * y);
            int offset = keep_radius_offset(radius);
            int sample = keep_sample_count(radial_sample_count[radius]);
            int next;
            offset = keep_radius_offset(offset * 512);
            x = write_x_offset(offset, sample, x);
            y = write_y_offset(offset, sample, y);
            next = keep_radius_offset(sample + 1);
            ++y;
            radial_sample_count[hold_radius(radius)] = next;
        test_y:
            ;
        } while (y <= 16);
        ++x;
    test_x:
        ;
    } while (x <= 16);

    index = 0;
    goto test_speed;
    do {
        int speed = 8 / (ripple_sqrt(index) + 1);
        ++index;
        ripple_speed[index - 1] = speed;
    test_speed:
        ;
    } while (index < 16);

    index = 0;
    goto test_wave;
    do {
        int amplitude = (((index ^ 17) >> 4) & 7) - 4;
        ++index;
        amplitude = klabs(amplitude);
        ripple_wave[index - 1] = hold_wave_amplitude(amplitude) + 12;
    test_wave:
        ;
    } while (index < 128);

    ripple_frame = ripple_count = keep_ripple_zero(0);
}
