extern char *token_resume;
extern const unsigned char bit_masks[];
extern void build_delimiter_map(unsigned char *, const unsigned char *);
#pragma aux build_delimiter_map modify exact [eax edx];

/* The tokenizer keeps the start, cursor, and current byte in Watcom registers. */
extern char *token_in_ebx(char *);
#pragma aux token_in_ebx = parm [ebx] value [ebx] modify exact [];
extern unsigned char dl_from_byte(unsigned char);
#pragma aux dl_from_byte = parm [dl] value [dl] modify exact [];
extern unsigned char cl_from_byte(unsigned char);
#pragma aux cl_from_byte = parm [cl] value [cl] modify exact [];
extern unsigned edx_from_dl(unsigned char);
#pragma aux edx_from_dl = parm [dl] value [edx] modify exact [];
extern unsigned int_in_edx(unsigned);
#pragma aux int_in_edx = parm [edx] value [edx] modify exact [];
extern unsigned int_in_ecx(unsigned);
#pragma aux int_in_ecx = parm [ecx] value [ecx] modify exact [];
extern unsigned int_in_eax(unsigned);
#pragma aux int_in_eax = parm [eax] value [eax] modify exact [];

extern unsigned ch_in_eax(void);
#pragma aux ch_in_eax = value [eax] modify exact [];
extern unsigned ch_in_edx(void);
#pragma aux ch_in_edx = value [edx] modify exact [];
extern unsigned ecx_from_cl(unsigned char);
#pragma aux ecx_from_cl = parm [cl] value [ecx] modify exact [];
extern char *cursor_from_eax(void);
#pragma aux cursor_from_eax = value [eax] modify exact [];
extern void set_cursor_in_eax(char *);
#pragma aux set_cursor_in_eax = parm [eax] modify exact [edx];
extern void consume_eax(unsigned);
#pragma aux consume_eax = parm [eax] modify exact [];
extern void consume_edx(unsigned);
#pragma aux consume_edx = parm [edx] modify exact [];

char *strtok(char *text, const char *delimiters)
{
    unsigned char map[32];
    char *token = token_in_ebx(text);
    union { unsigned word; unsigned char byte[4]; } current;
    if (!text) {
        token = token_in_ebx(token_resume);
        if (!token)
            goto exit;
    }
    build_delimiter_map(map, delimiters);
    goto leading_check;
    do {
        unsigned slot = int_in_edx(ch_in_eax() >> 3);
        unsigned flags = int_in_ecx(map[slot]);
        unsigned found;
        unsigned bit;
        bit = int_in_edx(ch_in_eax());
        bit = int_in_edx(bit & 7);
        found = edx_from_dl(dl_from_byte(bit_masks[bit])) & 0xff;
        if (!(flags & found))
            break;
        token = token_in_ebx(token + 1);
leading_check:
        current.word = int_in_eax(0);
        current.byte[0] = *token;
        consume_eax(int_in_eax(current.word));
    } while (ch_in_eax());
    if (!ch_in_eax())
        goto exit;
    set_cursor_in_eax(token);
    goto token_check;
    do {
        unsigned slot = int_in_ecx(ch_in_edx() >> 3);
        unsigned found = ecx_from_cl(cl_from_byte(map[slot]));
        unsigned bit = int_in_edx(ch_in_edx() & 7);
        found = int_in_ecx(found & 0xff);
        if (!(found & (edx_from_dl(dl_from_byte(bit_masks[bit])) & 0xff)))
            goto advance;
        *cursor_from_eax() = 0;
        set_cursor_in_eax(cursor_from_eax() + 1);
        token_resume = cursor_from_eax();
        goto done;
advance:
        set_cursor_in_eax(cursor_from_eax() + 1);
token_check:
        current.word = int_in_edx(0);
        current.byte[0] = *cursor_from_eax();
        consume_edx(int_in_edx(current.word));
    } while (ch_in_edx());
    token_resume = (char *)ch_in_edx();
done:
    set_cursor_in_eax(token);
exit:
    return cursor_from_eax();
}
