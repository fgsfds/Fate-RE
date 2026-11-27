/* Private C witness for the encounter RNG byte conversions and low-bit masks.
 * Each projection returns a real register lane; join combines disjoint lanes.
 * The high-byte XOR clears the copied high byte without changing the raw EAX.
 * Only pure conversion/mask slices are placed. Original RNG calls and the
 * 184-byte encounter frame remain owned by their existing production spans.
 * Private spills, reloads, sum and return are guarded but never linked.
 */
extern int random_value(void);
#pragma aux random_value value [eax] modify exact [eax];

/* Each instruction-free auxiliary returns an input unchanged or one of its bytes. */
extern unsigned in_edx(unsigned);
#pragma aux in_edx = "" parm [edx] value [edx] modify exact [];
extern unsigned in_ebx(unsigned);
#pragma aux in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern unsigned char high_ah(unsigned);
#pragma aux high_ah = "" parm [eax] value [ah] modify exact [];
extern unsigned char low_dl(unsigned);
#pragma aux low_dl = "" parm [edx] value [dl] modify exact [];
extern unsigned char high_dh(unsigned);
#pragma aux high_dh = "" parm [edx] value [dh] modify exact [];
extern unsigned char low_bl(unsigned);
#pragma aux low_bl = "" parm [ebx] value [bl] modify exact [];
extern unsigned char high_bh(unsigned);
#pragma aux high_bh = "" parm [ebx] value [bh] modify exact [];

/* Join the prescribed low and high byte lanes of the output word. */
extern unsigned short join_dx(unsigned char, unsigned char);
#pragma aux join_dx = "" parm [dl] [dh] value [dx] modify exact [];
extern unsigned short join_bx(unsigned char, unsigned char);
#pragma aux join_bx = "" parm [bl] [bh] value [bx] modify exact [];

extern unsigned char random_low(void);
#pragma aux random_low "random_value_" value [al] modify exact [eax];
extern unsigned short in_ax(unsigned short);
#pragma aux in_ax = "" parm [ax] value [ax] modify exact [];

unsigned encounter_byte_context(void)
{
    unsigned raw = random_value();
    unsigned staged = in_edx(raw);
    unsigned char low = low_dl(staged);
    unsigned char high = high_dh(staged) ^ high_ah(raw);
    unsigned short repeat = join_dx(low, high);
    unsigned short x, y;

    raw = random_value();
    staged = in_ebx(raw);
    low = low_bl(staged);
    high = high_bh(staged) ^ high_ah(raw);
    x = join_bx(low, high);

    y = in_ax(random_low());
    repeat = join_dx((unsigned char)repeat & 15U, repeat >> 8);
    y = in_ax(y & 1U);
    x = join_bx((unsigned char)x & 1U, x >> 8);
    return repeat + (x << 4) + (y << 5);
}
