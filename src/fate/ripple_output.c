/* In-place output frame: +4 end pointer, EBP row0..127; tile has4096 packed words. */
#pragma pack(push,1)
typedef struct { unsigned long value; } RippleWord;
typedef struct { unsigned char left; RippleWord word[32]; unsigned char tail[3]; } RippleRow;
typedef struct { RippleRow row[130]; } RipplePlane;
#pragma pack(pop)
extern RipplePlane ripple_buffer;
extern unsigned int output_row_ebp(void);
#pragma aux output_row_ebp = "" value [ebp] modify exact [];
extern unsigned int output_edx(unsigned int);
#pragma aux output_edx = "" parm [edx] value [edx] modify exact [];
extern unsigned int output_eax(unsigned int);
#pragma aux output_eax = "" parm [eax] value [eax] modify exact [];
extern unsigned char *output_pointer_eax(unsigned char *);
#pragma aux output_pointer_eax = "" parm [eax] value [eax] modify exact [];
extern unsigned char *output_pointer_edx(unsigned char *);
#pragma aux output_pointer_edx = "" parm [edx] value [edx] modify exact [];
extern unsigned char *output_pointer_ecx(unsigned char *);
#pragma aux output_pointer_ecx = "" parm [ecx] value [ecx] modify exact [];
unsigned char *ripple_output_row(unsigned char *volatile);
#pragma aux ripple_output_row parm caller [] value [ecx] modify exact [eax edx ecx];
unsigned char *ripple_output_row(unsigned char *volatile end_slot)
{
    unsigned int next=output_edx(output_row_ebp()+1U);
    unsigned int offset=output_eax(next);
    unsigned char *start;
    offset=output_eax(offset<<5);
    offset=output_eax(offset+next);
    offset=output_eax(offset<<2);
    offset=output_eax(offset+1U);
    start=output_pointer_eax((unsigned char *)&ripple_buffer+offset);
    end_slot=output_pointer_edx(start+128);
    return output_pointer_ecx(start);
}

extern const unsigned char *store_cursor_ecx(const unsigned char *);
#pragma aux store_cursor_ecx = "" parm [ecx] value [ecx] modify exact [];
extern RippleWord *store_output_esi(RippleWord *);
#pragma aux store_output_esi = "" parm [esi] value [esi] modify exact [];
extern RippleWord *store_handoff(RippleWord *, const unsigned char *);
#pragma aux store_handoff = "" parm [esi] [ecx] value [esi] modify exact [];
RippleWord *ripple_store_output(unsigned long, RippleWord *, const unsigned char *);
#pragma aux ripple_store_output parm [eax] [esi] [ecx] value [esi] modify exact [esi ecx];
RippleWord *ripple_store_output(unsigned long value, RippleWord *output, const unsigned char *cursor)
{
    cursor=store_cursor_ecx(cursor+4);
    output->value=value;
    output=store_output_esi(output+1);
    return store_handoff(output,cursor);
}
