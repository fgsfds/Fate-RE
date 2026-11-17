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
