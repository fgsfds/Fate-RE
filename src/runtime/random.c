extern unsigned long random_seed;
unsigned long *initrandnext(void)
{
    return &random_seed;
}

extern unsigned long *get_random_seed(void);
#pragma aux get_random_seed "initrandnext_" modify exact [eax];

int rand(void)
{
    unsigned long *seed = get_random_seed();
    if (seed)
        return ((*seed = *seed * 0x41c64e6dUL + 0x3039) >> 16) & 0x7fff;
    return 0;
}

void srand(unsigned seed_value)
{
    unsigned long *seed = get_random_seed();
    if (seed)
        *seed = seed_value;
}
