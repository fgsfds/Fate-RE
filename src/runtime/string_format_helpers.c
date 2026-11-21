char *strncpy(char *dst, const char *src, unsigned size)
{
    char *result = dst;
    goto check_count;
    do {
        char ch = *src;
        if (!ch)
            break;
        ++src;
        --size;
        *dst++ = ch;
check_count:
        ;
    } while (size);
    while (size) {
        --size;
        *dst++ = 0;
    }
    return result;
}

extern void format_unsigned(unsigned long, char *, unsigned);
#pragma aux format_unsigned modify exact [eax edx ebx];
char *format_integer(long number, char *dst, unsigned radix)
{
    char *result = dst;
    if (radix == 10 && number < 0) {
        number = (long)(-(unsigned long)number);
        *dst++ = '-';
    }
    format_unsigned(number, dst, radix);
    return result;
}

/* Match the original low/high register bytes and zero-extended subtraction. */
extern unsigned char load_left_byte(unsigned char);
#pragma aux load_left_byte = parm [cl] value [cl] modify exact [];
extern unsigned char load_right_byte(unsigned char);
#pragma aux load_right_byte = parm [ch] value [ch] modify exact [];

extern int widen_left_byte(int);
#pragma aux widen_left_byte = parm [ebx] value [ebx] modify exact [];
extern int widen_right_byte(int);
#pragma aux widen_right_byte = parm [eax] value [eax] modify exact [];

int strncmp(const char *left, const char *right, unsigned count)
{
    for (;;) {
        unsigned char a, b;
        if (!count)
            return 0;
        a = load_left_byte(*left);
        b = load_right_byte(*right);
        if (a != b)
            return widen_left_byte(a) - widen_right_byte(b);
        /* The original reloads the terminator from the left string. */
        if (!*(const volatile char *)left)
            return 0;
        ++left;
        ++right;
        --count;
    }
}
