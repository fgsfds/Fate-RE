typedef union { int value; unsigned char byte[4]; } DelimiterWord;
extern const unsigned char bit_masks[];
extern void *memset(void *, int, unsigned);
#pragma aux memset modify exact [eax edx];
extern unsigned char *bitmap_in_esi(unsigned char *);
#pragma aux bitmap_in_esi = parm [esi] value [esi] modify exact [ecx];
extern const unsigned char *text_in_ecx(const unsigned char *);
#pragma aux text_in_ecx = parm [ecx] value [ecx] modify exact [];
extern int word_in_eax(int);
#pragma aux word_in_eax = parm [eax] value [eax] modify exact [];
extern unsigned char byte_in_dl(unsigned char);
#pragma aux byte_in_dl = parm [dl] value [dl] modify exact [];
/* Preserve the eight-bit mask index and clear the high bits before lookup. */
extern int full_byte_in_edx(unsigned char);
#pragma aux full_byte_in_edx = parm [dl] value [edx] modify exact [];
extern unsigned char reading_from_dl(void);
#pragma aux reading_from_dl = value [dl] modify exact [];
extern unsigned char byte_in_dh(unsigned char);
#pragma aux byte_in_dh = parm [dh] value [dh] modify exact [];
extern void load_delimiter_in_dl(unsigned char);
#pragma aux load_delimiter_in_dl = parm [dl] modify exact [];
extern unsigned map_size_in_ebx(unsigned);
#pragma aux map_size_in_ebx = parm [ebx] value [ebx] modify exact [];
void build_delimiter_map(unsigned char *, const unsigned char *);
#pragma aux build_delimiter_map modify exact [eax edx];
void build_delimiter_map(unsigned char *map, const unsigned char *text)
{
    unsigned char *bitmap = bitmap_in_esi(map);
    const unsigned char *next = text_in_ecx(text);
    unsigned size = map_size_in_ebx(32);
    memset(map, 0, size);
    goto check;
    do {
        DelimiterWord offset;
        int index;
        unsigned char entry, mask;
        offset.value = word_in_eax(0);
        offset.byte[0] = reading_from_dl();
        index = word_in_eax(word_in_eax(offset.value) >> 3);
        mask = byte_in_dl(bit_masks[full_byte_in_edx(byte_in_dl(reading_from_dl() & 7)) & 0xff]);
        entry = byte_in_dh(bitmap[index]);
        entry = byte_in_dh(entry | mask);
        ++next;
        bitmap[index] = entry;
check:
        load_delimiter_in_dl(*next);
    } while (reading_from_dl());
}
