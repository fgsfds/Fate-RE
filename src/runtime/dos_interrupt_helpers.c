/* Shared default target for the three DOS runtime exit hooks. */
#pragma aux null_int23_exit "__null_int23_exit_";
void null_int23_exit(void)
{
}

extern void _disable(void);
#pragma intrinsic(_disable)
#pragma aux disable_interrupts "_disable_";
void disable_interrupts(void)
{
    _disable();
}

/* Re-enable interrupts: the original routine is a lone STI followed by RET. */
extern void _enable_body(void);
#pragma aux _enable_body = 0xfb modify exact [];

void enable_interrupts(void);
#pragma aux enable_interrupts "_enable_";
void enable_interrupts(void)
{
    _enable_body();
}
