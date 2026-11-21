extern void *memcpy(void *, const void *, unsigned);
#pragma intrinsic(memcpy);
/* Keep the same register setup for the Watcom string-copy intrinsic. */
extern const char *source_in_esi(const char *);
#pragma aux source_in_esi = parm [esi] value [esi] modify exact [];
extern const char *saved_start(void);
#pragma aux saved_start = "" value [esi] modify exact [];
extern char *target_in_edi(char *);
#pragma aux target_in_edi = parm [edi] value [edi] modify exact [];
extern unsigned size_in_ebx(unsigned);
#pragma aux size_in_ebx = parm [ebx] value [ebx] modify exact [];
extern char *end_in_eax(char *);
#pragma aux end_in_eax = parm [eax] value [eax] modify exact [];

char *copy_path_part(char **, char *, const char *, const char *);
#pragma aux copy_path_part modify exact [eax ebx ecx edx];
char *copy_path_part(char **part, char *destination, const char *start, const char *end)
{
    unsigned length;
    char *target;

    source_in_esi(start);
    if (!part)
        return destination;
    length = size_in_ebx(end - saved_start());
    *part = destination;
    /* Reserve a byte for the terminator in the DOS path component. */
    if (length >= 147)
        length = size_in_ebx(146);
    target = target_in_edi(destination);
    memcpy(target, saved_start(), length);
    target = end_in_eax(destination + length);
    *target = 0;
    return end_in_eax(target + 1);
}
