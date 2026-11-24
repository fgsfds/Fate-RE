/* Standalone contexts allocate the same 20-byte frame type. Their
 * selected instructions instead execute in the already established
 * legacy frame. The seed context also supplies its allocation, release
 * and return at the outer routine boundaries. Other contexts omit those
 * wrappers; all private bytes and the shared return jump are guarded. */
typedef struct {
    int index;
    unsigned char *output_end;
    unsigned int amplitude, origin_x;
    unsigned char edge, padding[3];
} RippleIndexFrame;

typedef char RippleIndexFrameSizeIs20[sizeof(RippleIndexFrame) == 20 ? 1 : -1];

extern int ripple_pending_ebp(void);
#pragma aux ripple_pending_ebp = "" parm [] value [ebp] modify exact [];

int ripple_seed_and_read_ecx(int);
#pragma aux ripple_seed_and_read_ecx parm [eax] value [ecx] modify exact [ecx];
int ripple_seed_and_read_ecx(int index)
{
    volatile RippleIndexFrame frame;

    frame.index = index;
    return frame.index;
}

/* The incoming EBP is the fully initialized pending count. */
int ripple_commit_and_read_eax(void);
#pragma aux ripple_commit_and_read_eax parm [] value [eax] modify exact [eax];
int ripple_commit_and_read_eax(void)
{
    volatile RippleIndexFrame frame;

    frame.index = ripple_pending_ebp();
    return frame.index;
}

/* The standalone input initializes the index before its decrement.
 * Only the two latter operations are needed in the existing frame. */
int ripple_step_and_read_eax(int);
#pragma aux ripple_step_and_read_eax parm [eax] value [eax] modify exact [eax];
int ripple_step_and_read_eax(int index)
{
    volatile RippleIndexFrame frame;

    frame.index = index;
    --frame.index;
    return frame.index;
}
