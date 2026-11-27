extern const unsigned long graphics_stack_floor;

unsigned long graphics_stack_limit(void)
{
    return graphics_stack_floor;
}

long labs(long value)
{
    if (value < 0)
        value = (long)(-(unsigned long)value);
    return value;
}

long min(long a, long b)
{
    if (a >= b)
        a = b;
    return a;
}

extern long lseek(int, long, int);
#pragma aux lseek modify exact [eax edx ebx];

long tell(int fd)
{
    return lseek(fd, 0, 1);
}
