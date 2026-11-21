extern void __far *_fmemcpy(void __far *, const void __far *, unsigned);
#pragma intrinsic(_fmemcpy);
extern const void __far *source_in_esi(const void __far *);
#pragma aux source_in_esi = parm [cx esi] value [cx esi] modify exact [];
void __far *runtime_fmemcpy(void __far *, const void __far *, unsigned);
#pragma aux runtime_fmemcpy "_fmemcpy_" modify exact [eax edx ebx ecx];
void __far *runtime_fmemcpy(void __far *destination, const void __far *source, unsigned size)
{
    const void __far *origin = source_in_esi(source);
    return _fmemcpy(destination, origin, size);
}
