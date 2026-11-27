/* Keep the cursor and comparison byte in the original Watcom registers. */
extern int character_in_ebx(int);
#pragma aux character_in_ebx = parm [ebx] value [ebx] modify exact [];
extern void retain_cursor_in_edx(const char *);
extern const char *cursor_from_edx(void);
#pragma aux cursor_from_edx = value [edx] modify exact [];
#pragma aux retain_cursor_in_edx = parm [edx] modify exact [eax];
extern void set_cursor_in_eax(const char *);
#pragma aux set_cursor_in_eax = parm [eax] modify exact [];
extern const char *cursor_from_eax(void);
#pragma aux cursor_from_eax = value [eax] modify exact [];
extern unsigned char character_in_cl(unsigned char);
#pragma aux character_in_cl = parm [cl] value [cl] modify exact [];
extern unsigned full_byte_in_edx(unsigned);
#pragma aux full_byte_in_edx = parm [edx] value [edx] modify exact [];
char *strchr(const char *text, int character)
{
    int wanted = character_in_ebx(character);
    set_cursor_in_eax(text);
    do {
        union { unsigned word; unsigned char byte[4]; } candidate;
        unsigned char value;
        candidate.word = full_byte_in_edx(0);
        candidate.byte[0] = *cursor_from_eax();
        if (full_byte_in_edx(candidate.word) == wanted)
            goto done;
        retain_cursor_in_edx(cursor_from_eax());
        value = character_in_cl(*cursor_from_edx());
        set_cursor_in_eax(cursor_from_eax() + 1);
        if (!value)
            break;
    } while (1);
    set_cursor_in_eax(0);
done:
    return (char *)cursor_from_eax();
}
