/* The Watcom fill primitive advances EAX and consumes ECX. */
extern void preserve_fill_registers(void *);
#pragma aux preserve_fill_registers = "push eax" "push ecx" parm [eax] modify exact [];
extern void *restore_fill_registers(void);
#pragma aux restore_fill_registers = "pop ecx" "pop eax" value [eax] modify exact [ecx eax];
extern void *fill_destination(void);
#pragma aux fill_destination = value [eax] modify exact [];
extern unsigned low_byte_pattern(void);
#pragma aux low_byte_pattern = value [edx] modify exact [];
/* Replicate the low input byte into the entire 32-bit pattern. */
extern unsigned set_second_byte(unsigned);
#pragma aux set_second_byte = "mov dh,dl" parm [edx] value [edx] modify exact [];
extern unsigned set_first_byte(unsigned);
#pragma aux set_first_byte = "mov dl,dh" parm [edx] value [edx] modify exact [];
extern unsigned finish_pattern(unsigned);
#pragma aux finish_pattern = "mov dl,dh" parm [edx] value [edx] modify exact [ecx];
extern unsigned pattern_in_edx(unsigned);
#pragma aux pattern_in_edx = parm [edx] value [edx] modify exact [];
extern unsigned fill_count(void);
#pragma aux fill_count = value [ebx] modify exact [];
extern void fill_byte_pattern(void *, unsigned, unsigned);
#pragma aux fill_byte_pattern parm [eax] [edx] [ecx] modify exact [eax edx ecx];

void *memset(void *, int, unsigned);
#pragma aux memset modify exact [eax edx ecx];
void *memset(void *destination, int value, unsigned size)
{
    unsigned pattern;
    preserve_fill_registers(destination);
    pattern = set_second_byte(low_byte_pattern());
    pattern = pattern_in_edx(pattern << 8);
    pattern = set_first_byte(pattern);
    pattern = pattern_in_edx(pattern << 8);
    pattern = finish_pattern(pattern);
    fill_byte_pattern(fill_destination(), pattern, fill_count());
    return restore_fill_registers();
}
