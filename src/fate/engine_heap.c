extern void *malloc(unsigned);
extern void free(void *);
#pragma aux malloc modify exact [eax];
#pragma aux free modify exact [eax];

void *engine_malloc(unsigned bytes)
{
    return malloc(bytes);
}

void engine_free(void *allocation)
{
    free(allocation);
}
