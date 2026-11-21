extern void save_source(const void *);
#pragma aux save_source = parm [esi] modify exact [];
extern void save_count(unsigned);
#pragma aux save_count = parm [ecx] modify exact [];
extern const unsigned char *move_source(void);
#pragma aux move_source = value [esi] modify exact [];
extern unsigned move_count(void);
#pragma aux move_count = value [ecx] modify exact [];
extern void *move_destination(void);
#pragma aux move_destination = value [eax] modify exact [];
/* Before the overlap test, EDX holds the incoming source. It then holds its end. */
extern const unsigned char *source_or_end_in_edx(void);
#pragma aux source_or_end_in_edx = value [edx] modify exact [];
extern const unsigned char *pointer_in_edx(const unsigned char *);
#pragma aux pointer_in_edx = parm [edx] value [edx] modify exact [];
extern unsigned char *destination_in_edi(unsigned char *);
#pragma aux destination_in_edi = parm [edi] value [edi] modify exact [];
extern const unsigned char *source_in_esi(const unsigned char *);
#pragma aux source_in_esi = parm [esi] value [esi] modify exact [];

/* Establish the original flat ES mapping and restore the direction flag. */
extern void copy_backward(unsigned char *, const unsigned char *, unsigned);
#pragma aux copy_backward = 0x8c 0xda "push es" 0x8e 0xc2 "std" "dec esi" "dec edi" "shr ecx,1" 0x66 0xf3 0xa5 "adc ecx,ecx" "inc esi" "inc edi" 0x66 0xf3 0xa4 "pop es" "cld" parm [edi] [esi] [ecx] modify exact [edx esi edi ecx];
extern void copy_forward(void *, const void *, unsigned);
#pragma aux copy_forward = 0x8c 0xda "mov edi,eax" "push es" 0x8e 0xc2 "push ecx" "shr ecx,2" "rep movsd" "pop ecx" "and ecx,3" "rep movsb" "pop es" parm [eax] [esi] [ecx] modify exact [edx esi edi ecx];

void *memmove(void *, const void *, unsigned);
#pragma aux memmove modify exact [eax edx ebx];
void *memmove(void *destination, const void *source, unsigned count)
{
    const unsigned char *end, *from, *to;

    save_source(source);
    save_count(count);
    from = source_or_end_in_edx();
    to = move_destination();
    if (from == to)
        goto done;
    if ((unsigned long)from < (unsigned long)to) {
        end = pointer_in_edx(source_or_end_in_edx() + count);
        if ((unsigned long)end > (unsigned long)move_destination()) {
            unsigned char *last = destination_in_edi((unsigned char *)move_destination() + count);
            const unsigned char *last_source = source_in_esi(source_or_end_in_edx() - 1);
            --last;
            copy_backward(last, last_source, move_count());
            return move_destination();
        }
    }
    copy_forward(move_destination(), move_source(), move_count());
done:
    return move_destination();
}
