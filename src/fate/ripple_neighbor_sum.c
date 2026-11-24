/* The production build places the 38-byte body at four in-place stencil sites.
 * The compiler RET remains unlinked and is checked by the binder.
 * Seven-neighbor ripple stencil. The original deliberately omits (+1,+1).
 * All sample bytes are masked to 0..31 before this phase, so the sum is <=217. */
extern unsigned char ripple_total_al(unsigned char);
#pragma aux ripple_total_al = "" parm [al] value [al] modify exact [];
extern unsigned char ripple_partial_dl(unsigned char);
#pragma aux ripple_partial_dl = "" parm [dl] value [dl] modify exact [];
unsigned char ripple_neighbor_sum(const unsigned char *);
#pragma aux ripple_neighbor_sum parm [ebx] value [al] modify exact [eax edx];
unsigned char ripple_neighbor_sum(const unsigned char *center)
{
    unsigned char total = ripple_total_al(center[-133]);
    unsigned char partial = ripple_partial_dl(center[-1]);
    total = ripple_total_al(total + center[-132]);
    partial = ripple_partial_dl(partial + center[131]);
    total = ripple_total_al(total + center[-131]);
    partial = ripple_partial_dl(partial + center[132]);
    total = ripple_total_al(total + center[1]);
    return ripple_total_al(total + partial);
}
