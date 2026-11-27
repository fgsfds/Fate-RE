/* Watcom keeps both characters in the low and high bytes of BX. */
extern void left_in_bl(unsigned char);
#pragma aux left_in_bl = parm [bl] modify exact [];
extern void right_in_bh(unsigned char);
#pragma aux right_in_bh = parm [bh] modify exact [];
extern unsigned int clear_edx(void);
#pragma aux clear_edx = "xor edx,edx" value [edx] modify exact [];
extern unsigned int clear_eax(void);
#pragma aux clear_eax = "xor eax,eax" value [eax] modify exact [];

extern unsigned char folded_left(void);
#pragma aux folded_left = value [bl] modify exact [];
extern unsigned char folded_right(void);
#pragma aux folded_right = value [bh] modify exact [];
extern void load_left_after_clear(unsigned, unsigned, unsigned char);
#pragma aux load_left_after_clear = "mov dl,bl" parm [edx] [eax] [bl] modify exact [edx];
extern void load_right_after_left(unsigned, unsigned char);
#pragma aux load_right_after_left = "mov al,bh" parm [eax] [bh] modify exact [eax];

extern unsigned left_number(void);
#pragma aux left_number = value [edx] modify exact [];
extern unsigned right_number(void);
#pragma aux right_number = value [eax] modify exact [];
extern unsigned difference_in_edx(unsigned);
#pragma aux difference_in_edx = parm [edx] value [edx] modify exact [];

int stricmp(const char *left, const char *right)
{
    unsigned left_value, right_value;

    for (;;) {
        left_in_bl(*left);
        right_in_bh(*right);
        if (folded_left() >= 'A' && folded_left() <= 'Z')
            left_in_bl(folded_left() + ('a' - 'A'));
        if (folded_right() >= 'A' && folded_right() <= 'Z')
            right_in_bh(folded_right() + ('a' - 'A'));
        if (folded_left() != folded_right() || !folded_right())
            break;
        ++left;
        ++right;
    }
    left_value = clear_edx();
    right_value = clear_eax();
    load_left_after_clear(left_value, right_value, folded_left());
    load_right_after_left(right_value, folded_right());
    return difference_in_edx(left_number() - right_number());
}

/* The bounded comparison uses CX and one byte of stack scratch space. */
extern void left_in_cl(unsigned char);
#pragma aux left_in_cl = parm [cl] modify exact [];
extern unsigned char folded_left_cl(void);
#pragma aux folded_left_cl = value [cl] modify exact [];
extern unsigned char right_in_ch(unsigned char);
#pragma aux right_in_ch = parm [ch] value [ch] modify exact [];
extern void load_left_cl(unsigned, unsigned, unsigned char);
#pragma aux load_left_cl = "mov dl,cl" parm [edx] [eax] [cl] modify exact [edx];
extern void load_right_ch(unsigned, unsigned char);
#pragma aux load_right_ch = "mov al,ch" parm [eax] [ch] modify exact [eax];


int strnicmp(const char *left, const char *right, unsigned length)
{
    volatile unsigned char saved_right;
    unsigned char second;
    unsigned left_value, right_value;

check_length:
    if (!length)
        return 0;

    second = right_in_ch(*right);
    left_in_cl(*left);
    saved_right = second;
    if (folded_left_cl() >= 'A' && folded_left_cl() <= 'Z')
        left_in_cl(folded_left_cl() + ('a' - 'A'));
    second = right_in_ch(saved_right);
    if (second >= 'A' && second <= 'Z')
        saved_right = right_in_ch(second + ('a' - 'A'));
    second = right_in_ch(saved_right);
    if (folded_left_cl() != second) {
        left_value = clear_edx();
        right_value = clear_eax();
        load_left_cl(left_value, right_value, folded_left_cl());
        load_right_ch(right_value, second);
        return difference_in_edx(left_number() - right_number());
    }
    if (!second)
        return 0;
    ++left;
    ++right;
    --length;
    goto check_length;
}
