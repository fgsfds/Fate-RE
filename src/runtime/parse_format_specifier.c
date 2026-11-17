/* Parse printf width, precision, and one DOS length modifier. */
typedef struct {
    unsigned reserved;
    int width, precision;
    unsigned reserved2[2];
    unsigned char flags, type, padding, extra;
} FormatSpec;

/* Bind the C expressions to the registers shared with the parser entry and exits. */
extern void position_in_eax(const char *);
#pragma aux position_in_eax = "" parm [eax] modify exact [];
extern unsigned char character_in_cl(unsigned char);
#pragma aux character_in_cl = "" parm [cl] value [cl] modify exact [];
extern void position_in_edx(const char *);
#pragma aux position_in_edx = "" parm [edx] modify exact [];
extern int integer_in_ecx(int);
#pragma aux integer_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern unsigned char flags_in_dl(unsigned char);
#pragma aux flags_in_dl = "" parm [dl] value [dl] modify exact [];
extern unsigned char flags_in_ch(unsigned char);
#pragma aux flags_in_ch = "" parm [ch] value [ch] modify exact [];
extern const char *modifier_end(void);
#pragma aux modifier_end = "" value [edx] modify exact [];

extern const char *parse_format_flags(const char *, FormatSpec *);
#pragma aux parse_format_flags parm [eax] [edx] modify exact [eax];
extern void arguments_to_esi(const int **);
#pragma aux arguments_to_esi = "" parm [esi] modify exact [];
extern void flags_in_edx(FormatSpec *);
#pragma aux flags_in_edx = "" parm [edx] modify exact [];
extern void preserve_extra_store(FormatSpec *);
#pragma aux preserve_extra_store = "" parm [ebx] modify exact [edx];
extern FormatSpec *for_flags(void);
#pragma aux for_flags = value [edx] modify exact [];
extern FormatSpec *fields(void);
#pragma aux fields = value [ebx] modify exact [];
extern const char *position(void);
#pragma aux position = value [eax] modify exact [];
extern unsigned char preserve_width_character(unsigned char);
#pragma aux preserve_width_character = "" parm [cl] value [cl] modify exact [edx];

extern unsigned char current_modifier(void);
#pragma aux current_modifier = value [cl] modify exact [];
extern const int **argument_cursor(void);
#pragma aux argument_cursor = "" value [esi] modify exact [];
extern const int *arguments_in_edx(const int *);
#pragma aux arguments_in_edx = "" parm [edx] value [edx] modify exact [];
extern int integer_in_edx(int);
#pragma aux integer_in_edx = "" parm [edx] value [edx] modify exact [];

/* Keep the zero-then-byte-load sequence used by the original parser. */
extern int decimal_byte(void);
#pragma aux decimal_byte = "xor edx,edx" "mov dl,[eax]" value [edx] modify exact [edx];

extern int width_in_edi(int);
#pragma aux width_in_edi = "" parm [edi] value [edi] modify exact [];
extern unsigned char flags_in_dh(unsigned char);
#pragma aux flags_in_dh = "" parm [dh] value [dh] modify exact [];
extern unsigned char from_dh(void);
#pragma aux from_dh = "" value [dh] modify exact [];

const char *parse_format_specifier(const char *, const int **, FormatSpec *);
#pragma aux parse_format_specifier modify exact [eax ebx edx];
const char *parse_format_specifier(const char *format, const int **args, FormatSpec *spec)
{
    unsigned char ch, flags;
    int value, prefix, digit;

    arguments_to_esi(args);
    fields()->extra = 0;
    preserve_extra_store(fields());
    flags_in_edx(fields());
    fields()->padding = ' ';
    parse_format_flags(position(), for_flags());

    fields()->width = 0;
    ch = character_in_cl(*position());
    ch = preserve_width_character(ch);
    position_in_edx(position());
    if (ch < '0' || ch > '9')
        goto check_star_width;

    do {
        prefix = integer_in_ecx((int)((unsigned)fields()->width * 10));
        digit = integer_in_edx(decimal_byte() - '0');
        value = integer_in_ecx((int)((unsigned)prefix + digit));
        position_in_eax(position() + 1);
        fields()->width = value;
        ch = character_in_cl(*position());
        if (ch < '0')
            goto check_precision;
    } while (ch <= '9');
    goto check_precision;

check_star_width:
    if (*position() == '*') {
        const int *arguments = arguments_in_edx(*argument_cursor());
        arguments = arguments_in_edx(arguments + 1);
        *argument_cursor() = arguments;
        value = integer_in_edx(arguments[-1]);
        fields()->width = value;
        if (value < 0) {
            int width = width_in_edi(value);
            flags_in_dh(fields()->flags);
            width = width_in_edi((int)(0U - (unsigned)width));
            flags = flags_in_dh(from_dh() | 8);
            fields()->width = width;
            fields()->flags = flags;
        }
        position_in_eax(position() + 1);
    }

check_precision:
    fields()->precision = -1;
    if (*position() != '.')
        goto modifiers;
    position_in_eax(position() + 1);
    fields()->precision = 0;
    if (*position() == '*') {
        const int *arguments = arguments_in_edx(*argument_cursor());
        arguments = arguments_in_edx(arguments + 1);
        *argument_cursor() = arguments;
        value = integer_in_edx(arguments[-1]);
        fields()->precision = value;
        if (value < 0)
            fields()->precision = -1;
        position_in_eax(position() + 1);
        goto modifiers;
    }

    for (;;) {
        ch = character_in_cl(*position());
        if (ch < '0' || ch > '9')
            break;
        prefix = integer_in_ecx((int)((unsigned)fields()->precision * 10));
        digit = integer_in_edx(decimal_byte() - '0');
        value = integer_in_ecx((int)((unsigned)prefix + digit));
        position_in_eax(position() + 1);
        fields()->precision = value;
    }

modifiers:
    ch = character_in_cl(*position());
    position_in_edx(position() + 1);
    if (ch < 'N')
        goto uppercase;
    if (ch <= 'N')
        goto near_pointer;
    if (ch < 'l')
        goto short_length;
    if (ch <= 'l' || ch == 'w')
        goto long_length;
    return position();

short_length:
    if (current_modifier() == 'h')
        goto set_short;
    return position();

uppercase:
    ch = current_modifier();
    if (ch < 'F')
        goto unchanged;
    if (ch <= 'F')
        goto far_pointer;
    if (ch == 'L')
        goto long_pointer;
    return position();

long_length:
    flags = flags_in_dl(fields()->flags | 0x20);
    position_in_eax(position() + 1);
    fields()->flags = flags;
    return position();

set_short:
    flags = character_in_cl(fields()->flags | 0x10);
    position_in_eax(modifier_end());
    fields()->flags = flags;
    return position();

long_pointer:
    *(volatile unsigned char *)&fields()->flags |= 0x40;
finish_pointer:
    position_in_eax(modifier_end());
    return position();

far_pointer:
    *(volatile unsigned char *)&fields()->flags |= 0x80;
    goto finish_pointer;

near_pointer:
    flags = flags_in_ch(fields()->flags | 0x40);
    position_in_eax(modifier_end());
    fields()->flags = flags;
unchanged:
    return position();
}
