extern unsigned char fill_pattern[8], default_fill_pattern[8];
extern unsigned char fill_pattern_enabled;
extern void *memcpy(void *destination, const void *source, unsigned count);
#pragma intrinsic(memcpy);
extern int memcmp(const void *first, const void *second, unsigned count);
#pragma intrinsic(memcmp);

/* Retain the original Watcom memcpy argument setup order. */
extern unsigned char *pattern_in_edi(unsigned char *pattern);
#pragma aux pattern_in_edi = "" parm [edi] value [edi] modify exact [];
extern const unsigned char *pattern_in_esi(const unsigned char *pattern);
#pragma aux pattern_in_esi = "" parm [esi] value [esi] modify exact [];

unsigned char *get_fill_pattern(unsigned char *pattern)
{
    if (pattern)
        memcpy(pattern, pattern_in_esi(fill_pattern), 8);
    if (!fill_pattern_enabled)
        return 0;
    return pattern;
}

void set_fill_pattern(const unsigned char *pattern)
{
    if (!pattern) {
        unsigned char *destination = pattern_in_edi(fill_pattern);
        const unsigned char *source = pattern_in_esi(default_fill_pattern);
        fill_pattern_enabled = 0;
        memcpy(destination, source, 8);
    } else {
        void *copy = memcpy(pattern_in_edi(fill_pattern), pattern, 8);
        if (memcmp(copy, default_fill_pattern, 8) == 0)
            fill_pattern_enabled = 0;
        else
            fill_pattern_enabled = 1;
    }
}
