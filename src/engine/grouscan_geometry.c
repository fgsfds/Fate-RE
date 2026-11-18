/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern long wall[], view_width_reciprocal, view_ray_x, view_ray_y;
extern long slope_view_axis_x, slope_view_axis_y;
extern union {
    long integer;
    float real;
    unsigned char bytes[4];
} sqrt_float_bits;
extern long reciptable[];
extern unsigned short sqrtable[];

#define AT_BYTE_OFFSET(values, offset) (*(long *)((char *)(values) + (offset)))

extern long from_ax(void);
#pragma aux from_ax = value [eax] modify exact [];
extern void in_ax(long value);
#pragma aux in_ax = "" parm [eax] modify exact [];
extern long from_bx(void);
#pragma aux from_bx = value [ebx] modify exact [];
extern void in_bx(long value);
#pragma aux in_bx = "" parm [ebx] modify exact [];
extern long from_cx(void);
#pragma aux from_cx = value [ecx] modify exact [];
extern void in_cx(long value);
#pragma aux in_cx = "" parm [ecx] modify exact [];
extern long from_dx(void);
#pragma aux from_dx = value [edx] modify exact [];
extern void in_dx(long value);
#pragma aux in_dx = "" parm [edx] modify exact [];
extern long from_si(void);
#pragma aux from_si = value [esi] modify exact [];
extern void in_si(long value);
#pragma aux in_si = "" parm [esi] modify exact [];
extern long from_di(void);
#pragma aux from_di = value [edi] modify exact [];
extern void in_di(long value);
#pragma aux in_di = "" parm [edi] modify exact [];
extern long from_bp(void);
#pragma aux from_bp = value [ebp] modify exact [];

extern void store_wall_pointer(void);
#pragma aux store_wall_pointer = "mov dword ptr [esp + 0x30], edx" modify exact [];
extern long read_wall_pointer(void);
#pragma aux read_wall_pointer = "mov ebx, dword ptr [esp + 0x30]" value [ebx] modify exact [ebx];
extern void save_wall_delta_x(void);
#pragma aux save_wall_delta_x = "mov dword ptr [esp + 0x2c], edx" modify exact [edx];
extern void save_wall_delta_y(void);
#pragma aux save_wall_delta_y = "mov dword ptr [esp + 0x24], eax" modify exact [eax];

void grouscan_wall_vector(void);
#pragma aux grouscan_wall_vector aborts;

void grouscan_wall_vector(void)
{
    /* Save the first wall pointer and vector, then form the squared length. */
    in_ax(*(const short *)from_bp());
    in_dx((long)wall);
    in_ax(from_ax() << 5);
    in_dx(from_dx() + from_ax());
    in_ax(*(const short *)(from_dx() + 8));
    store_wall_pointer();
    in_ax(from_ax() << 5);
    in_bx(read_wall_pointer());
    in_dx(AT_BYTE_OFFSET(wall, from_ax()));
    in_si(*(const long *)from_bx());
    in_dx(from_dx() - from_si());
    save_wall_delta_x();
    in_dx(from_dx() * from_dx());
    in_di(*(const long *)(from_bx() + 4));
    in_ax(AT_BYTE_OFFSET(wall, from_ax() + 4));
    in_ax(from_ax() - from_di());
    save_wall_delta_y();
    in_ax(from_ax() * from_ax());
    in_ax(from_ax() + from_dx());
    sqrt_float_bits.integer = from_ax();
}

extern unsigned char from_bl(void);
#pragma aux from_bl = value [bl] modify exact [];
extern void in_cl(unsigned char value);
#pragma aux in_cl = parm [cl] modify exact [];
extern void in_bl(unsigned char value);
#pragma aux in_bl = "" parm [bl] modify exact [];
extern void in_bx_word(unsigned short value);
#pragma aux in_bx_word = "" parm [bx] modify exact [];
extern void check_wall_length_exponent(void);
#pragma aux check_wall_length_exponent = "sub bl, 0x44" "db 7dh, 0ch" /* marker-rel8 +2,+2 */ modify exact [ebx];
extern void skip_scaled_wall_length(void);
#pragma aux skip_scaled_wall_length = "db 0ebh, 17h" /* marker-rel8 +2,+3 */ modify exact [];
extern void use_scaled_sqrt_index(void);
#pragma aux use_scaled_sqrt_index = "db 08dh, 0ch, 05dh, 00h, 00h, 00h, 00h" \
    "shr eax, cl" modify exact [eax ecx];
extern void shift_scaled_wall_root(void);
#pragma aux shift_scaled_wall_root = "shl ebx, cl" modify exact [ebx];

void grouscan_wall_length(void);
#pragma aux grouscan_wall_length aborts;

void grouscan_wall_length(void)
{
    /* Read the floating-point exponent to normalize large square-table inputs. */
    sqrt_float_bits.real = (float)sqrt_float_bits.integer;
    in_bl(sqrt_float_bits.bytes[3]);
    check_wall_length_exponent();
    in_bx(0);
    in_bx_word(sqrtable[from_ax()]);
    skip_scaled_wall_length();
    use_scaled_sqrt_index();
    /* Reuse the undoubled exponent to scale the table result. */
    in_cl(from_bl());
    in_bx(0);
    in_bx_word(sqrtable[from_ax()]);
    shift_scaled_wall_root();
    in_bx((unsigned long)from_bx() >> 10);
}

extern void begin_reciprocal_table_index(void);
#pragma aux begin_reciprocal_table_index = "fild dword ptr [sqrt_float_bits]" modify exact [eax];
extern void finish_reciprocal_table_index(void);
#pragma aux finish_reciprocal_table_index = "fstp dword ptr [sqrt_float_bits]" "sbb ebx, ebx" modify exact [eax ebx];

extern signed char from_cl(void);
#pragma aux from_cl = value [cl] modify exact [];

extern long shift_reciprocal_by_exponent(long value, signed char exponent);
#pragma aux shift_reciprocal_by_exponent = "sar eax, cl" parm [eax] [cl] value [eax] modify exact [eax];

/* Preserve the accumulator store before the reciprocal lookup. */
extern void keep_length_in_ax(void);
#pragma aux keep_length_in_ax = "" modify exact [ebx];

void grouscan_inverse_length(void);
#pragma aux grouscan_inverse_length aborts;

void grouscan_inverse_length(void)
{
    /* Decode the float exponent and lookup the fixed-point reciprocal. */
    in_ax(from_bx());
    keep_length_in_ax();
    sqrt_float_bits.integer = from_ax();
    begin_reciprocal_table_index();
    /* Doubling leaves the original sign in carry for the reciprocal sign mask. */
    in_ax((unsigned long)from_ax() + from_ax());
    finish_reciprocal_table_index();
    in_ax(sqrt_float_bits.integer);
    in_cx(from_ax());
    in_ax(from_ax() & 0x7ff000);
    in_ax((unsigned long)from_ax() >> 10);
    in_cx(from_cx() - 0x3f800000);
    in_cx((unsigned long)from_cx() >> 23);
    in_ax(AT_BYTE_OFFSET(reciptable, from_ax()));
    in_ax(shift_reciprocal_by_exponent(from_ax(), from_cl()));
    in_ax(from_ax() ^ from_bx());
    in_cx(from_ax());
    in_bx(from_ax());
}

extern void read_plane_slope(void);
#pragma aux read_plane_slope = "mov eax, dword ptr [esp + 0x1c]" modify exact [eax];
extern long read_wall_delta_x(void);
#pragma aux read_wall_delta_x = "mov edx, dword ptr [esp + 0x2c]" value [edx] modify exact [edx];
extern long read_wall_delta_y(void);
#pragma aux read_wall_delta_y = "mov edx, dword ptr [esp + 0x24]" value [edx] modify exact [edx];
extern void store_scaled_wall_delta_y(void);
#pragma aux store_scaled_wall_delta_y = "mov dword ptr [esp + 0x24], edx" modify exact [];
extern long scale21(long value, long factor);
#pragma aux scale21 = "imul ebx" "shrd eax, edx, 21" \
    parm nomemory [eax] [ebx] value [eax] modify exact [eax edx];
extern long scale19(long value, long factor);
#pragma aux scale19 = "imul ebx" "shrd eax, edx, 19" \
    parm nomemory [eax] [ebx] value [eax] modify exact [eax edx];

void grouscan_scale_wall_vector(void);
#pragma aux grouscan_scale_wall_vector aborts;

void grouscan_scale_wall_vector(void)
{
    /* Scale the wall vector by its slope and initialize the two view axes. */
    read_plane_slope();
    in_ax(scale21(from_ax(), from_bx()));
    in_dx(read_wall_delta_x() * from_ax());
    save_wall_delta_x();
    in_dx(read_wall_delta_y() * from_ax());
    in_bx(view_width_reciprocal);
    in_ax(view_ray_y);
    store_scaled_wall_delta_y();
    in_ax(scale19(from_ax(), from_bx()));
    in_bx(view_width_reciprocal);
    in_si(from_ax());
    slope_view_axis_x = from_ax();
    in_si(-from_si());
    in_ax(view_ray_x);
    slope_view_axis_x = from_si();
    in_ax(scale19(from_ax(), from_bx()));
    slope_view_axis_y = from_ax();
}
