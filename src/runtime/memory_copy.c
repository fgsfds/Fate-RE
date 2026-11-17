extern void *memcpy(void *, const void *, unsigned);
#pragma intrinsic(memcpy);
/* Bind the destination and source before Watcom sets up the copy count. */
extern void *destination_in_edi(void *);
#pragma aux destination_in_edi = parm [edi] value [edi] modify exact [];
extern const void *source_in_esi(const void *);
#pragma aux source_in_esi = parm [esi] value [esi] modify exact [];
void *runtime_memcpy(void *, const void *, unsigned);
#pragma aux runtime_memcpy "memcpy_" modify exact [eax];
void *runtime_memcpy(void *destination, const void *source, unsigned size)
{
    void *target = destination_in_edi(destination);
    const void *origin = source_in_esi(source);
    return memcpy(target, origin, size);
}
