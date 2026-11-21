/* Convert one printf argument into text and update the output specification. */
typedef struct {
    void *destination;
    int width, length, precision_zeroes;
    unsigned count;
    volatile unsigned char flags;
    unsigned char type, pad;
    char prefix[5];
} FormatState;

extern char *ltoa(long, char *, unsigned);
#pragma aux ltoa modify exact [eax ebx edx];
extern void format_signed_integer(long, char *, unsigned);
#pragma aux format_signed_integer modify exact [eax ebx edx];
extern void fixed_result_segments(void);
#pragma aux fixed_result_segments = 0x8c 0xd8 0x8c 0xda 0x8e 0xc0 modify exact [eax edx];
extern void load_pointer_offset(void);
#pragma aux load_pointer_offset = "mov ebp,[eax-4]" modify exact [];
extern void format_integer(long, char *, unsigned);
#pragma aux format_integer modify exact [eax ebx edx];
extern void format_unsigned(unsigned long, char *, unsigned);
#pragma aux format_unsigned modify exact [eax ebx edx];
extern void format_padded_hex(unsigned long, char *, int);
#pragma aux format_padded_hex modify exact [eax ebx edx];
extern void format_fixed_point(char *, long, FormatState *);
#pragma aux format_fixed_point modify exact [eax ebx edx];
extern void call_float_formatter(char *, void *, FormatState *);
#pragma aux call_float_formatter modify exact [eax ebx edx];
extern unsigned bounded_far_strlen(unsigned, unsigned, unsigned);
#pragma aux bounded_far_strlen modify exact [eax ebx edx];
extern unsigned bounded_far_wcslen(unsigned, unsigned, unsigned);
#pragma aux bounded_far_wcslen modify exact [eax ebx edx];
extern void uppercase_output(char *);
#pragma aux uppercase_output modify exact [eax];

/* Keep C argument traversal and formatting in the original register ABI. */
extern unsigned char in_ah(unsigned char);
#pragma aux in_ah = "" parm [ah] value [ah] modify exact [];
extern unsigned char in_al(unsigned char);
#pragma aux in_al = "" parm [al] value [al] modify exact [];
extern unsigned char in_dh(unsigned char);
#pragma aux in_dh = "" parm [dh] value [dh] modify exact [];
extern unsigned char in_dl(unsigned char);
#pragma aux in_dl = "" parm [dl] value [dl] modify exact [];
extern long in_eax(long);
#pragma aux in_eax = "" parm [eax] value [eax] modify exact [];
extern long in_ebx(long);
#pragma aux in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern void output_in_edi(char *);
#pragma aux output_in_edi = "" parm [edi] modify exact [];
extern long in_edx(long);
#pragma aux in_edx = "" parm [edx] value [edx] modify exact [];
extern long in_ecx(long);
#pragma aux in_ecx = "" parm [ecx] value [ecx] modify exact [];

extern unsigned char **argument_list(void);
#pragma aux argument_list = "" value [edx] modify exact [];
extern unsigned char *cursor_in_eax(unsigned char *);
#pragma aux cursor_in_eax = "" parm [eax] value [eax] modify exact [];
extern unsigned char *cursor_in_ebx(unsigned char *);
#pragma aux cursor_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern unsigned char *cursor_in_ecx(unsigned char *);
#pragma aux cursor_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern unsigned short word_in_dx(unsigned short);
#pragma aux word_in_dx = "" parm [dx] value [dx] modify exact [];
extern unsigned char in_bh(unsigned char);
#pragma aux in_bh = "" parm [bh] value [bh] modify exact [];
extern unsigned char in_bl(unsigned char);
#pragma aux in_bl = "" parm [bl] value [bl] modify exact [];
extern void offset_in_edi(long);
#pragma aux offset_in_edi = "" parm [edi] modify exact [];

extern void reserve_conversion_frame(void);
#pragma aux reserve_conversion_frame = "push esi" "push edi" "push es" "push ebp" "sub esp,8" modify exact [];
extern void state_in_esi(FormatState *);
#pragma aux state_in_esi = "" parm [esi] modify exact [];
extern const char *initial_null_text(void);
#pragma aux initial_null_text = "" value [ecx] modify exact [];
extern char *initial_buffer(void);
#pragma aux initial_buffer = "" value [eax] modify exact [];
extern FormatState *initial_state(void);
#pragma aux initial_state = "" value [ebx] modify exact [];
extern unsigned char initial_type(void);
#pragma aux initial_type = "mov al,[esi+15h]" value [al] modify exact [eax];
extern FormatState *state(void);
#pragma aux state = value [esi] modify exact [];
extern char *output(void);
#pragma aux output = value [edi] modify exact [];
extern unsigned char current_type(void);
#pragma aux current_type = value [al] modify exact [];
extern unsigned char old_flags_in_ah(void);
#pragma aux old_flags_in_ah = value [ah] modify exact [];
extern unsigned char old_flags_in_al(void);
#pragma aux old_flags_in_al = value [al] modify exact [];

extern void read_unsigned_int(void);
#pragma aux read_unsigned_int = "mov ebp,[edx]" "add ebp,4" "mov [edx],ebp" "mov ebp,[ebp-4]" modify exact [];
extern void load_long_argument(void);
#pragma aux load_long_argument = "mov ebp,[ebx-4]" modify exact [];
extern void load_short_argument(void);
#pragma aux load_short_argument = "movzx ebp,word ptr [eax-4]" modify exact [];
extern unsigned long argument_value(void);
#pragma aux argument_value = value [ebp] modify exact [];
extern long read_signed_long(void);
#pragma aux read_signed_long = "mov ebp,[edx]" "add ebp,4" "mov [edx],ebp" \
    "mov edx,edi" "mov eax,[ebp-4]" value [eax] modify exact [eax edx];

extern void *buffer_argument(void);
#pragma aux buffer_argument = value [eax] modify exact [];
extern long fixed_argument(void);
#pragma aux fixed_argument = value [edx] modify exact [];
extern void *remaining_arguments(void);
#pragma aux remaining_arguments = value [edx] modify exact [];
extern FormatState *converter_state(void);
#pragma aux converter_state = value [ebx] modify exact [];
extern char *integer_buffer(void);
#pragma aux integer_buffer = value [edx] modify exact [];
extern unsigned current_base(void);
#pragma aux current_base = value [ebx] modify exact [];
extern void clear_numeric_zero(void);
#pragma aux clear_numeric_zero = "mov byte ptr es:[ecx],0" modify exact [];
extern void result_selector_to_edx(void);
#pragma aux result_selector_to_edx = 0x8c 0xc2 modify exact [edx];
extern unsigned length_offset(void);
#pragma aux length_offset = value [eax] modify exact [];
extern unsigned length_selector(void);
#pragma aux length_selector = value [edx] modify exact [];
extern unsigned length_limit(void);
#pragma aux length_limit = value [ebx] modify exact [];

extern unsigned string_offset(void);
#pragma aux string_offset = value [ecx] modify exact [];
extern unsigned short string_segment(void);
#pragma aux string_segment = value [dx] modify exact [];
extern void use_far_segment(void);
#pragma aux use_far_segment = 0x8e 0xc2 modify exact [];
extern void use_data_segment(void);
#pragma aux use_data_segment = 0x8c 0xd8 modify exact [eax];
extern void use_far_null_string(void);
#pragma aux use_far_null_string = 0x8c 0xd8 "mov ecx,[esp]" modify exact [eax ecx];
extern void use_null_string_offset(void);
#pragma aux use_null_string_offset = "mov ecx,[esp]" modify exact [ecx];
extern void load_string_segment(void);
#pragma aux load_string_segment = 0x8e 0xc0 modify exact [];
extern unsigned char string_flags(void);
#pragma aux string_flags = value [bh] modify exact [];
extern unsigned read_wide_length_byte(void);
#pragma aux read_wide_length_byte = "xor eax,eax" 0x66 0x26 0x8b 0x01 "add ecx,2" value [eax] modify exact [eax ecx];
extern unsigned read_length_byte(void);
#pragma aux read_length_byte = "xor eax,eax" "mov al,es:[ecx]" "inc ecx" value [eax] modify exact [eax ecx];

extern unsigned long hex_number(void);
#pragma aux hex_number = value [eax] modify exact [];

extern char first_numeric_byte(void);
#pragma aux first_numeric_byte = "mov dl,es:[ecx]" value [dl] modify exact [edx];
extern void decrement_total(void);
#pragma aux decrement_total = "dec eax" modify exact [eax];
extern int total_length(void);
#pragma aux total_length = value [eax] modify exact [];
extern void set_prefix_segment(void);
#pragma aux set_prefix_segment = 0x8c 0xda modify exact [edx];
extern void load_length_in_ebp(void);
#pragma aux load_length_in_ebp = "mov ebp,[esi+8]" modify exact [];
extern void select_result_segment(void);
#pragma aux select_result_segment = 0x8c 0xc2 modify exact [edx];
extern void restore_conversion_frame(void);
#pragma aux restore_conversion_frame = "add esp,8" "pop ebp" "pop es" "pop edi" "pop esi" modify exact [esi edi];
extern void *return_offset(void);
#pragma aux return_offset = value [eax] modify exact [];

/* The entry reserves these slots itself. The caller-cleaned stack view lets
 * Watcom address the numeric flag directly at ESP+4 after that reservation.
 */
typedef struct {
    volatile unsigned numeric;
} ConversionFrameView;

void *convert_format_value(char *, void *, FormatState *, const char *, ConversionFrameView);
#pragma aux convert_format_value parm caller [eax] [edx] [ebx] [ecx] [] modify exact [eax ebx ecx edx esi edi];
void *convert_format_value(char *buffer, void *args, FormatState *spec, const char *null_text,
                           ConversionFrameView frame)
{
    unsigned char kind, flags;
    int wanted, actual;
    long number;
    char first;
    char *target;

    reserve_conversion_frame();
    output_in_edi(initial_buffer());
    state_in_esi(initial_state());
    ((const char *volatile *)&frame)[-1] = initial_null_text();
    in_ebx(1);
    use_data_segment();
    in_ecx((long)output());
    frame.numeric = current_base();
    load_string_segment();
    kind = initial_type();
    state()->precision_zeroes = 0;
    if (kind < 'i')
        goto uppercase_argument;
    if (kind <= 'i')
        goto numeric_precision;
    if (kind < 'u')
        goto octal_argument;
    if (kind <= 'u')
        goto unsigned_argument;
    if (kind == 'x')
        goto unsigned_argument;
    goto dispatch;

octal_argument:
    if (current_type() == 'o')
        goto unsigned_argument;
    goto dispatch;

uppercase_argument:
    kind = current_type();
    if (kind < 'X')
        goto dispatch;
    if (kind <= 'X')
        goto unsigned_argument;
    if (kind == 'd')
        goto numeric_precision;
    goto dispatch;

unsigned_argument:
    flags = in_ah(state()->flags);
    if (flags & 0x20) {
        unsigned char *cursor = cursor_in_ebx(*argument_list());
        cursor = cursor_in_ebx(cursor + 4);
        *argument_list() = cursor;
        load_long_argument();
    }
    else if (flags & 0x10) {
        unsigned char *cursor = cursor_in_eax(*argument_list());
        cursor = cursor_in_eax(cursor + 4);
        *argument_list() = cursor;
        load_short_argument();
    }
    else
        read_unsigned_int();
    state()->flags &= ~6;
numeric_precision:
    if (state()->length != -1)
        state()->pad = ' ';

dispatch:
    kind = in_al(state()->type);
    in_ebx(10);
    if (kind < 'e')
        goto uppercase_conversions;
    if (kind <= 'e')
        goto floating;
    if (kind < 'o')
        goto lower_float;
    if (kind <= 'o')
        goto octal;
    if (kind < 's')
        goto lower_pointer;
    if (kind <= 's')
        goto string;
    if (kind < 'u')
        goto unknown;
    if (kind <= 'u')
        goto unsigned_digits;
    if (kind == 'x')
        goto hexadecimal;
    goto unknown;

lower_pointer:
    if (current_type() == 'p')
        goto pointer;
    goto unknown;

lower_float:
    kind = current_type();
    if (kind < 'g')
        goto fixed_point;
    if (kind <= 'g')
        goto floating;
    if (kind == 'i')
        goto signed_digits;
    goto unknown;

uppercase_conversions:
    kind = current_type();
    if (kind < 'P')
        goto upper_float;
    if (kind <= 'P')
        goto pointer;
    if (kind < 'X')
        goto upper_string;
    if (kind <= 'X')
        goto hexadecimal;
    if (kind < 'c')
        goto unknown;
    if (kind <= 'c')
        goto character;
    goto signed_digits;

upper_string:
    if (current_type() == 'S')
        goto string;
    goto unknown;

upper_float:
    kind = current_type();
    if (kind < 'F')
        goto upper_exponent;
    if (kind <= 'F')
        goto fixed_point;
    if (kind == 'G')
        goto floating;
    goto unknown;

upper_exponent:
    if (current_type() == 'E')
        goto floating;
    goto unknown;

fixed_point:
    if (!(state()->flags & 0x10))
        goto floating;
    {
        unsigned char *cursor = cursor_in_ebx(*argument_list());
        cursor = cursor_in_ebx(cursor + 4);
        *argument_list() = cursor;
        in_eax((long)output());
        in_edx(*(long *)(cursor - 4));
        in_ebx((long)state());
    }
    format_fixed_point(buffer_argument(), fixed_argument(), converter_state());
    in_ebx(-1);
    fixed_result_segments();
    in_eax((long)output());
    in_ecx((long)output());
    goto measure_far_bytes;

floating:
    in_eax((long)output());
    in_ebx((long)state());
    call_float_formatter(buffer_argument(), remaining_arguments(), converter_state());
    in_ebx(-1);
    use_far_segment();
    in_ecx(length_offset());
    goto measure_far_bytes;

octal:
    flags = in_al(state()->flags);
    in_ebx(8);
    if (flags & 1) {
        *output() = '0';
        output_in_edi(output() + 1);
    }
    number = in_eax(argument_value());
    target = (char *)in_edx((long)output());
    format_integer(number, target, current_base());

check_zero_precision:
    if (!state()->length && *output() == '0')
        clear_numeric_zero();
measure_numeric:
    in_ebx(-1);
    result_selector_to_edx();
    in_eax(string_offset());
measure_far_bytes:
    bounded_far_strlen(length_offset(), length_selector(), length_limit());
    goto numeric_prefix;

signed_digits:
    flags = in_al(state()->flags);
    if (!(flags & 0x20))
        goto signed_short;
    read_signed_long();
write_integer_digits:
    format_signed_integer(length_offset(), integer_buffer(), current_base());
    goto check_zero_precision;
signed_short:
    if (old_flags_in_al() & 0x10) {
        unsigned char *cursor = cursor_in_eax(*argument_list());
        cursor = cursor_in_eax(cursor + 4);
        *argument_list() = cursor;
        in_edx((long)output());
        in_eax(*(short *)(cursor - 4));
        goto write_integer_digits;
    }
    number = read_signed_long();
    ltoa(number, integer_buffer(), current_base());
    goto check_zero_precision;

string:
    flags = in_ah(state()->flags);
    if (!(flags & 0x80))
        goto near_string;
    {
        unsigned char *cursor = cursor_in_ecx(*argument_list());
        cursor = cursor_in_ecx(cursor + 8);
        *argument_list() = cursor;
        word_in_dx(*(unsigned short *)(cursor - 4));
        in_ecx(*(unsigned long *)(cursor - 8));
    }
    if (string_offset() || string_segment()) {
        use_far_segment();
        goto prepare_string_length;
    }
null_string:
    use_far_null_string();
    goto set_string_segment;

near_string:
    if (!(old_flags_in_ah() & 0x40))
        goto default_string;
    {
        unsigned char *cursor = cursor_in_ebx(*argument_list());
        cursor = cursor_in_ebx(cursor + 4);
        *argument_list() = cursor;
        in_ecx(*(unsigned long *)(cursor - 4));
    }
    if (!string_offset())
        goto null_string;
select_near_segment:
    use_data_segment();
    goto set_string_segment;
default_string:
    {
        unsigned char *cursor = cursor_in_eax(*argument_list());
        cursor = cursor_in_eax(cursor + 4);
        *argument_list() = cursor;
        in_ecx(*(unsigned long *)(cursor - 4));
    }
    if (string_offset())
        goto select_near_segment;
    use_data_segment();
    use_null_string_offset();
set_string_segment:
    load_string_segment();

prepare_string_length:
    flags = in_bh(state()->flags);
    kind = in_al(state()->type);
    offset_in_edi(0);
    flags = in_bh(flags & 0xf9);
    frame.numeric = 0;
    state()->flags = flags;
    if (kind != 'S')
        goto terminated_string;
    if (string_flags() & 0x20) {
        read_wide_length_byte();
        goto numeric_prefix;
    }
    read_length_byte();
    goto numeric_prefix;
terminated_string:
    if (string_flags() & 0x20) {
        result_selector_to_edx();
        in_eax(string_offset());
        in_ebx(state()->length);
        bounded_far_wcslen(length_offset(), length_selector(), length_limit());
        goto numeric_prefix;
    }
    result_selector_to_edx();
    in_eax(string_offset());
    in_ebx(state()->length);
    goto measure_far_bytes;

hexadecimal:
    if ((state()->flags & 1) && argument_value()) {
        state()->prefix[0] = '0';
        kind = in_al(state()->type);
        state()->prefix[2] = 0;
        state()->prefix[1] = kind;
    }
    in_ebx(16);
unsigned_digits:
    number = in_eax(argument_value());
    target = (char *)in_edx((long)output());
    format_unsigned((unsigned long)number, target, current_base());
    if (state()->type != 'X')
        goto check_zero_precision;
    uppercase_output((char *)in_eax((long)output()));
    goto check_zero_precision;

pointer:
    if (!state()->width) {
        if (state()->flags & 0x80)
            state()->width = 13;
        else
            state()->width = 8;
    }
    state()->flags &= ~6;
    {
        unsigned char *cursor = cursor_in_eax(*argument_list());
        cursor = cursor_in_eax(cursor + 4);
        *argument_list() = cursor;
        flags = in_bl(state()->flags);
        load_pointer_offset();
    }
    if (flags & 0x80) {
        unsigned char *cursor = cursor_in_eax((unsigned char *)length_offset() + 4);
        *argument_list() = cursor;
        in_ebx(4);
        in_eax(*(long *)(cursor - 4));
        in_edx((long)output());
        in_eax(length_offset() & 0xffff);
        format_padded_hex(hex_number(), integer_buffer(), current_base());
        in_ebx(8);
        in_edx((long)(output() + 5));
        in_eax(argument_value());
        output()[4] = ':';
    } else {
        in_ebx(8);
        in_eax(argument_value());
        in_edx((long)output());
    }
    format_padded_hex(hex_number(), integer_buffer(), current_base());
    if (state()->type != 'P')
        goto measure_numeric;
    uppercase_output((char *)in_eax((long)output()));
    goto measure_numeric;

character:
    {
        unsigned char *cursor = cursor_in_ebx(*argument_list());
        cursor = cursor_in_ebx(cursor + 4);
        *argument_list() = cursor;
        first = in_al(cursor[-4]);
    }
    output()[1] = 0;
    output()[0] = first;
    state()->length = 1;
    in_eax(1);
    flags = in_dh(state()->flags);
    offset_in_edi(0);
    flags = in_dh(flags & 0xf9);
    frame.numeric = 0;
    state()->flags = flags;
    goto numeric_prefix;

unknown:
    state()->width = 0;
    first = in_al(state()->type);
    output()[1] = 0;
    output()[0] = first;
    state()->length = 1;
    flags = in_al(state()->flags);
    offset_in_edi(0);
    flags = in_al(flags & 0xf9);
    frame.numeric = 0;
    state()->flags = flags;
    in_eax(1);

numeric_prefix:
    if (!frame.numeric)
        goto special_padding;
    first = first_numeric_byte();
    if (first == '-') {
        in_ecx(string_offset() + 1);
        state()->prefix[1] = 0;
        decrement_total();
        state()->prefix[0] = first;
        goto numeric_digit_count;
    }
    flags = in_dh(state()->flags);
    if (flags & 2) {
        state()->prefix[0] = ' ';
    } else {
        if (!(flags & 4))
            goto numeric_digit_count;
        state()->prefix[0] = '+';
    }
    state()->prefix[1] = 0;

numeric_digit_count:
    wanted = in_edx(state()->length);
    actual = total_length();
    if (actual > wanted)
        state()->length = actual;
    else
        state()->precision_zeroes = in_edx(wanted - actual);

special_padding:
    if (state()->pad == '*') {
        flags = in_dl(state()->flags);
        state()->prefix[0] = 0;
        state()->flags = in_dl(flags & 0xf9);
    }

    wanted = in_ebx(state()->length);
    if (wanted == -1 || total_length() < wanted) {
        if (state()->type != 'c')
            state()->length = total_length();
    }

    in_ebx(-1);
    in_eax((long)state()->prefix);
    set_prefix_segment();
    bounded_far_strlen(length_offset(), length_selector(), length_limit());
    load_length_in_ebp();
    in_edx(state()->precision_zeroes);
    in_eax(total_length() + argument_value());
    wanted = in_ebx(state()->width);
    actual = in_eax(total_length() + length_selector());
    select_result_segment();
    wanted = in_ebx(wanted - actual);
    in_eax(string_offset());
    state()->width = wanted;
    restore_conversion_frame();
    return return_offset();
}
