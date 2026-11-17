/* Discard the unused 32-bit argument with the Pascal callee-cleanup ABI. */
void __pascal discard_stack_check_argument(unsigned long unused)
{
    (void)unused;
}
