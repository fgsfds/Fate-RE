/* Two in-place ripple phases; their compiler RETs are guarded and unlinked.
 * The count invariant is 0..32. The row's destination belongs to the full
 * bordered plane, with at least 132 bytes available, and source has 32 words. */
extern int ripple_count;
int ripple_spawn_limit(void);
#pragma aux ripple_spawn_limit value [eax] modify exact [eax];
int ripple_spawn_limit(void)
{
    int remaining = 32 - ripple_count - 1;
    if (remaining >= 3)
        remaining = 3;
    return remaining;
}

#pragma pack(push,1)
typedef struct { unsigned long value; } RippleWord;
#pragma pack(pop)
extern unsigned char *row_next_ebx(unsigned char *);
#pragma aux row_next_ebx = "" parm [ebx] value [ebx] modify exact [];
extern int row_count_ecx(int);
#pragma aux row_count_ecx = "" parm [ecx] value [ecx] modify exact [];
extern unsigned long row_word_edi(unsigned long);
#pragma aux row_word_edi = "" parm [edi] value [edi] modify exact [];
unsigned char *ripple_mask_row(unsigned char *, const RippleWord *);
#pragma aux ripple_mask_row parm [eax] [esi] value [eax] modify exact [eax ebx ecx esi edi];
unsigned char *ripple_mask_row(unsigned char *destination, const RippleWord *source)
{
    int words = row_count_ecx(32);
    unsigned char *next;
    goto test_word;
    do {
        unsigned long masked = row_word_edi(source->value);
        words = row_count_ecx(words - 1);
        masked = row_word_edi(masked & 0x1f1f1f1fUL);
        ++source;
        ((RippleWord *)destination)->value = masked;
        destination = next;
    test_word:
        next = row_next_ebx(destination + 4);
    } while (words > 0);
    return next;
}
