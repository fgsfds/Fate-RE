extern unsigned getpid(void);
#pragma aux getpid modify exact [eax];
extern int hex_digit(int);
#pragma aux hex_digit modify exact [eax];

/* Keep the destination and suffix in the original Watcom registers. */
extern void save_temp_name(char *);
#pragma aux save_temp_name = parm [ecx] modify exact [];
extern char *temp_name(void);
#pragma aux temp_name = value [ecx] modify exact [];
extern void save_temp_suffix(unsigned);
#pragma aux save_temp_suffix = parm [edi] modify exact [];
extern int temp_suffix(void);
#pragma aux temp_suffix = value [edi] modify exact [];
extern char *base_in_esi(char *);
#pragma aux base_in_esi = parm [esi] value [esi] modify exact [];
extern unsigned pid_in_ebx(unsigned);
#pragma aux pid_in_ebx = parm [ebx] value [ebx] modify exact [];
extern unsigned offset_in_edx(unsigned);
#pragma aux offset_in_edx = parm [edx] value [edx] modify exact [];
extern char *cursor_in_edx(char *);
#pragma aux cursor_in_edx = parm [edx] value [edx] modify exact [];
extern int digit_in_eax(int);
#pragma aux digit_in_eax = parm [eax] value [eax] modify exact [];
extern unsigned char digit_in_al(unsigned char);
#pragma aux digit_in_al = parm [al] value [al] modify exact [];

void __MkTmpFile(char *, unsigned);
#pragma aux __MkTmpFile modify exact [eax edx];
void __MkTmpFile(char *name, unsigned suffix)
{
    unsigned pid, cursor_offset;
    char *base, *cursor;
    unsigned char digit;
    int index;

    save_temp_name(name);
    save_temp_suffix(suffix);
    pid = getpid();
    cursor_offset = offset_in_edx(4);
    pid = pid_in_ebx(pid);
    base = base_in_esi(temp_name());
    /* Write t followed by four PID digits, two suffix digits, and .tmp. */
    temp_name()[0] = 't';
    cursor = cursor_in_edx(temp_name() + cursor_offset);
    do {
        index = digit_in_eax(pid);
        *cursor = digit_in_al(hex_digit(index & 0xf));
        cursor = cursor_in_edx(cursor - 1);
        pid = pid_in_ebx(pid >> 4);
    } while (cursor != base);

    index = digit_in_eax(temp_suffix());
    index = digit_in_eax(index >> 4);
    index = digit_in_eax(index & 0xf);
    temp_name()[5] = '_';
    temp_name()[6] = digit_in_al(hex_digit(index));
    index = digit_in_eax(temp_suffix());
    digit = digit_in_al(hex_digit(index & 0xf));
    ((volatile char *)temp_name())[8] = '.';
    ((volatile char *)temp_name())[9] = 't';
    ((volatile char *)temp_name())[10] = 'm';
    ((volatile char *)temp_name())[11] = 'p';
    ((volatile char *)temp_name())[12] = '\0';
    temp_name()[7] = digit;
}
