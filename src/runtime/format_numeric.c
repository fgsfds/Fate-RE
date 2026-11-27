/* Format pointer components and signed 16.16 values for the printf engine. */
extern char *ltoa(long, char *, int);
#pragma aux ltoa modify exact [eax edx ebx];

/* Bind cursor updates and byte loads to the formatter registers. */
extern void cursor_to_ebx(char *);
#pragma aux cursor_to_ebx = "" parm [ebx] modify exact [];
extern void int_to_eax(int);
#pragma aux int_to_eax = "" parm [eax] modify exact [];
extern void cursor_to_edx(char *);
#pragma aux cursor_to_edx = "" parm [edx] modify exact [];
extern void cursor_to_ecx(char *);
#pragma aux cursor_to_ecx = "" parm [ecx] modify exact [];
extern char byte_in_al(char);
#pragma aux byte_in_al = "" parm [al] value [al] modify exact [];
extern char byte_in_ah(char);
#pragma aux byte_in_ah = "" parm [ah] value [ah] modify exact [];
extern char *fixed_following(void);
#pragma aux fixed_following = "" value [edx] modify exact [];

/* Watcom's formatter uses ECX, ESI, EDI and EBP for these two loops. */
extern void prepare_hex(char *, int);
#pragma aux prepare_hex = "push ebp" "sub esp,4" "mov ebp,edx" "mov [esp],ebx" "mov ebx,16" "mov edi,ebp" \
    parm [edx] [ebx] modify exact [ebx edi];
extern long hex_input(void);
#pragma aux hex_input = value [eax] modify exact [];
extern char *hex_buffer(void);
#pragma aux hex_buffer = value [edx] modify exact [];
extern int hex_radix(void);
#pragma aux hex_radix = value [ebx] modify exact [];
extern void position_hex_digits(void);
#pragma aux position_hex_digits = "push es" 0x8c 0xd8 0x8e 0xc0 "sub ecx,ecx" "dec ecx" \
    "xor eax,eax" "repne scasb" "not ecx" "dec ecx" "pop es" "mov eax,[esp]" "mov esi,ecx" \
    "mov edi,ebp" "dec eax" "lea edx,[ecx+ebp]" "lea ebx,[eax+ebp]" \
    modify exact [eax ebx ecx edx esi edi];
extern char *hex_begin(void);
#pragma aux hex_begin = value [edi] modify exact [];
extern char *hex_source(void);
#pragma aux hex_source = value [edx] modify exact [];
extern char *hex_target(void);
#pragma aux hex_target = value [ebx] modify exact [];
extern int current_hex_width(void);
#pragma aux current_hex_width = value [eax] modify exact [];
extern int remaining_hex(void);
#pragma aux remaining_hex = "" value [esi] modify exact [];
extern void remaining_in_esi(int);
#pragma aux remaining_in_esi = "" parm [esi] modify exact [];
extern char digit_in_cl(char);
#pragma aux digit_in_cl = "" parm [cl] value [cl] modify exact [];
extern char *hex_frame_base(void);
#pragma aux hex_frame_base = "" value [ebp] modify exact [];
extern char *hex_terminator(void);
#pragma aux hex_terminator = "add ebp,[esp]" value [ebp] modify exact [];
extern void pop_hex_frame(void);
#pragma aux pop_hex_frame = "add esp,4" "pop ebp" modify exact [];

void format_padded_hex(long, char *, int);
#pragma aux format_padded_hex modify exact [eax edx ebx];
void format_padded_hex(long number, char *out, int width)
{
    char digit;

    prepare_hex(out, width);
    ltoa(hex_input(), hex_buffer(), hex_radix());
    position_hex_digits();
    goto check_hex_source;
    do {
        cursor_to_edx(hex_source() - 1);
        remaining_in_esi(remaining_hex() - 1);
        digit = digit_in_cl(*hex_source());
        int_to_eax(current_hex_width() - 1);
        *hex_target() = digit;
        cursor_to_ebx(hex_target() - 1);
check_hex_source:;
    } while (hex_source() != hex_begin());

    cursor_to_edx(hex_frame_base() + current_hex_width());
    while (current_hex_width() >= 0) {
        int_to_eax(current_hex_width() - 1);
        *hex_source() = '0';
        cursor_to_edx(hex_source() - 1);
    }
    *hex_terminator() = '\0';
    pop_hex_frame();
}

typedef struct {
    char before_precision[8];
    int precision;
} FormatSpec;

extern long begin_fixed(char *, long, FormatSpec *);
#pragma aux begin_fixed = "mov ecx,eax" "mov esi,ebx" \
    parm [eax] [edx] [ebx] value [edx] modify exact [ecx esi];
extern void magnitude_to_edx(unsigned long);
#pragma aux magnitude_to_edx = "" parm [edx] modify exact [];
extern char *fixed_signed_start(void);
#pragma aux fixed_signed_start = value [eax] modify exact [];
extern unsigned long fixed_magnitude(void);
#pragma aux fixed_magnitude = value [edx] modify exact [];
extern FormatSpec *fixed_spec(void);
#pragma aux fixed_spec = value [esi] modify exact [];
extern void start_fixed_integer(void);
#pragma aux start_fixed_integer = "mov ebx,10" "xor eax,eax" "mov edx,ecx" \
    "mov ax,[esp+2]" modify exact [eax ebx edx];
extern long fixed_integer(void);
#pragma aux fixed_integer = value [eax] modify exact [];
extern char *fixed_integer_buffer(void);
#pragma aux fixed_integer_buffer = value [edx] modify exact [];
extern int fixed_radix(void);
#pragma aux fixed_radix = value [ebx] modify exact [];
extern char *fixed_start(void);
#pragma aux fixed_start = value [ebx] modify exact [];
extern char *fixed_output(void);
#pragma aux fixed_output = value [ecx] modify exact [];

extern int fixed_digits_written(void);
#pragma aux fixed_digits_written = value [eax] modify exact [];
/* Multiply the 16-bit fractional residue by ten and take its integer part. */
extern unsigned long product_in_edx(unsigned long);
#pragma aux product_in_edx = "" parm [edx] value [edx] modify exact [];
extern unsigned long fraction_in_edi(unsigned long);
#pragma aux fraction_in_edi = "" parm [edi] value [edi] modify exact [];
extern char fraction_in_dl(char);
#pragma aux fraction_in_dl = "" parm [dl] value [dl] modify exact [];
extern void cursor_to_eax(char *);
#pragma aux cursor_to_eax = "" parm [eax] modify exact [];
extern char *next_fixed_byte(void);
#pragma aux next_fixed_byte = value [eax] modify exact [];

void format_fixed_point(char *, long, FormatSpec *);
#pragma aux format_fixed_point modify exact [eax edx ebx];
void format_fixed_point(char *out, long number, FormatSpec *spec)
{
    volatile union {
        unsigned long bits;
        unsigned char bytes[4];
        unsigned short words[2];
    } magnitude;
    char digit;

    magnitude.bits = begin_fixed(out, number, spec);
    if ((long)fixed_magnitude() < 0) {
        magnitude_to_edx(0UL - fixed_magnitude());
        cursor_to_ecx(fixed_signed_start() + 1);
        *fixed_signed_start() = '-';
        magnitude.bits = fixed_magnitude();
    }
    if (fixed_spec()->precision == -1)
        fixed_spec()->precision = 4;

    start_fixed_integer();
    ltoa(fixed_integer(), fixed_integer_buffer(), fixed_radix());
    cursor_to_ebx(fixed_output());
    for (;;) {
        digit = byte_in_ah(*fixed_output());
        cursor_to_edx(fixed_output() + 1);
        if (!digit)
            break;
        cursor_to_ecx(fixed_following());
    }

    if (fixed_spec()->precision) {
        *fixed_output() = '.';
        int_to_eax(0);
        cursor_to_ecx(fixed_following());
        goto check_fraction_length;
        do {
            magnitude.words[1] = (unsigned short)product_in_edx(0);
            magnitude.bits = product_in_edx(fraction_in_edi(magnitude.bits) * 10);
            digit = fraction_in_dl((char)magnitude.bytes[2]);
            digit = fraction_in_dl(digit + '0');
            int_to_eax(fixed_digits_written() + 1);
            *fixed_output() = digit;
            cursor_to_ecx(fixed_output() + 1);
check_fraction_length:;
        } while (fixed_digits_written() < fixed_spec()->precision);
        *fixed_output() = '\0';
    }

    /* Round from the first discarded fractional bit and propagate any carry. */
    if (magnitude.bytes[1] & 0x80) {
        for (;;) {
            if (fixed_output() == fixed_start()) {
                cursor_to_ecx(fixed_start() + 1);
                *fixed_start() = '1';
                for (;;) {
                    digit = fraction_in_dl(*fixed_output());
                    cursor_to_eax(fixed_output() + 1);
                    if (digit != '0')
                        break;
                    cursor_to_ecx(next_fixed_byte());
                }
                if (digit == '.') {
                    *fixed_output() = '0';
                    cursor_to_ecx(next_fixed_byte() + 1);
                    *next_fixed_byte() = digit;
                    while (*fixed_output() == '0')
                        cursor_to_ecx(fixed_output() + 1);
                }
                *fixed_output() = '0';
                cursor_to_ecx(fixed_output() + 1);
                *fixed_output() = '\0';
                break;
            }
            cursor_to_ecx(fixed_output() - 1);
            if (*fixed_output() == '.')
                cursor_to_ecx(fixed_output() - 1);
            digit = byte_in_al(*fixed_output());
            if (digit != '9') {
                *fixed_output() = byte_in_ah(digit + 1);
                break;
            }
            *fixed_output() = '0';
        }
    }
}
