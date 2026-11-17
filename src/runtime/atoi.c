extern const unsigned char character_types[];
/* Match the CRT character-table index and its eight-bit wraparound. */
extern unsigned char byte_in_dl(unsigned char);
#pragma aux byte_in_dl = parm [dl] value [dl] modify exact [];
extern unsigned byte_register(unsigned char);
#pragma aux byte_register = parm [dl] value [edx] modify exact [];
extern unsigned char sign_in_cl(unsigned char);
#pragma aux sign_in_cl = parm [cl] value [cl] modify exact [];
extern unsigned value_in_edx(unsigned);
#pragma aux value_in_edx = parm [edx] value [edx] modify exact [];
extern unsigned sum_in_ebx(unsigned);
#pragma aux sum_in_ebx = parm [ebx] value [ebx] modify exact [];
int atoi(const char *);
#pragma aux atoi modify exact [eax];
int atoi(const char *text)
{
    unsigned index;
    unsigned sum;
    unsigned char sign;
    union { unsigned whole; unsigned char byte[4]; } digit;
    for (;;) {
        index = byte_register(byte_in_dl((unsigned char)*text) + 1) & 0xff;
        if (!(character_types[index] & 2))
            break;
        ++text;
    }
    sign = *text;
    if (sign == '+' || sign == '-')
        ++text;
    sign = sign_in_cl(sign);
    sum = sum_in_ebx(0);
    for (;;) {
        index = byte_register(byte_in_dl((unsigned char)*text) + 1) & 0xff;
        if (!(character_types[index] & 0x20))
            break;
        sum = sum_in_ebx(sum * 10);
        digit.whole = value_in_edx(0);
        digit.byte[0] = *text;
        sum += value_in_edx(digit.whole);
        ++text;
        sum = sum_in_ebx(sum - '0');
    }
    if (sign_in_cl(sign) == '-')
        sum = sum_in_ebx(-sum);
    return sum;
}
