/* Emit formatted characters through the DOS runtime's callback. */
typedef struct {
    void *destination;
    int width, length, precision_zeroes;
    unsigned count;
    unsigned char flags, type, pad;
    char prefix[5];
} FormatState;

typedef void FormatWriter(FormatState *, unsigned);
#pragma aux FormatWriter parm [eax] [edx] modify exact [eax ecx edx];
typedef FormatWriter *PutCharacter;
extern const char *parse_format_specifier(const char *, void *, FormatState *);
#pragma aux parse_format_specifier modify exact [eax ebx ecx edx];
extern void convert_format_value(void *, void *, FormatState *, void *);
#pragma aux convert_format_value modify exact [eax ebx ecx edx];

/* Keep the C output and argument operations in the original register ABI. */
extern int value_in_eax(int);
#pragma aux value_in_eax = "" parm [eax] value [eax] modify exact [];
extern int value_in_edx(int);
#pragma aux value_in_edx = "" parm [edx] value [edx] modify exact [];
extern int value_in_ecx(int);
#pragma aux value_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern FormatState *writer_state(FormatState *);
#pragma aux writer_state = "" parm [eax] value [eax] modify exact [edx];
extern unsigned char byte_in_cl(unsigned char);
#pragma aux byte_in_cl = "" parm [cl] value [cl] modify exact [];
extern unsigned char byte_in_bl(unsigned char);
#pragma aux byte_in_bl = "" parm [bl] value [bl] modify exact [];
extern unsigned char byte_in_al(unsigned char);
#pragma aux byte_in_al = "" parm [al] value [al] modify exact [];
extern unsigned char byte_in_dh(unsigned char);
#pragma aux byte_in_dh = "" parm [dh] value [dh] modify exact [];
extern const char *pattern_in_edi(void);
#pragma aux pattern_in_edi = "" value [edi] modify exact [];
extern const char *pattern_in_eax(const char *);
#pragma aux pattern_in_eax = "" parm [eax] value [eax] modify exact [];
extern unsigned value_cursor(void);
#pragma aux value_cursor = "" value [ebx] modify exact [];
extern void value_cursor_in_ebx(unsigned);
#pragma aux value_cursor_in_ebx = "" parm [ebx] modify exact [];
extern const unsigned char *prefix_in_ecx(const unsigned char *);
#pragma aux prefix_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern const unsigned char *prefix_position(void);
#pragma aux prefix_position = "" value [ecx] modify exact [];
extern void *args_in_esi(void);
#pragma aux args_in_esi = "" value [esi] modify exact [];
extern void *args_in_edx(void *);
#pragma aux args_in_edx = "" parm [edx] value [edx] modify exact [];
extern FormatState *state_in_ebx(FormatState *);
#pragma aux state_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern void *scratch_in_ecx(void *);
#pragma aux scratch_in_ecx = "" parm [ecx] value [ecx] modify exact [];

extern void load_far_value(void);
#pragma aux load_far_value = "mov dl,es:[ebx]" modify exact [edx];
extern void clear_writer_byte(void);
#pragma aux clear_writer_byte = "xor edx,edx" modify exact [edx];
extern unsigned writer_byte(void);
#pragma aux writer_byte = "" value [edx] modify exact [];
extern void put_writer_byte(unsigned char);
#pragma aux put_writer_byte = "" parm [dl] modify exact [];
extern void pattern_to_edi(const char *);
#pragma aux pattern_to_edi = "" parm [edi] modify exact [];

extern unsigned char **argument_list(void);
#pragma aux argument_list = "" value [esi] modify exact [];
extern unsigned count_argument_width(void);
#pragma aux count_argument_width = "" value [ebp] modify exact [];
extern unsigned char *count_cursor_eax(unsigned char *);
#pragma aux count_cursor_eax = "" parm [eax] value [eax] modify exact [];
extern unsigned char *count_cursor_ebx(unsigned char *);
#pragma aux count_cursor_ebx = "" parm [ebx] value [ebx] modify exact [];
extern unsigned char *count_cursor_ecx(unsigned char *);
#pragma aux count_cursor_ecx = "" parm [ecx] value [ecx] modify exact [];
extern unsigned char *count_cursor_edx(unsigned char *);
#pragma aux count_cursor_edx = "" parm [edx] value [edx] modify exact [];
extern void count_address_to_edx(unsigned *);
#pragma aux count_address_to_edx = "" parm [edx] modify exact [];

extern void read_far_count_eax(unsigned char *);
#pragma aux read_far_count_eax = "les edx,[eax-8]" parm [eax] modify exact [edx];
extern void read_far_count_ecx(unsigned char *);
#pragma aux read_far_count_ecx = "les edx,[ecx-8]" parm [ecx] modify exact [edx];
extern void read_far_count_edx(unsigned char *);
#pragma aux read_far_count_edx = "les edx,[edx-8]" parm [edx] modify exact [edx];
extern void select_value_segment(void);
#pragma aux select_value_segment = 0x8e 0xc2 modify exact [];
extern unsigned char byte_in_dl(unsigned char);
#pragma aux byte_in_dl = "" parm [dl] value [dl] modify exact [];
extern unsigned converted_address(void);
#pragma aux converted_address = "" value [eax] modify exact [];
extern void *buffer_in_eax(void *);
#pragma aux buffer_in_eax = "" parm [eax] value [eax] modify exact [];
extern void reserve_format_frame(void);
#pragma aux reserve_format_frame = "push esi" "push edi" "push es" "push ebp" "sub esp,4ch" modify exact [];
extern void *incoming_arguments(void);
#pragma aux incoming_arguments = "" value [ebx] modify exact [];
extern void arguments_to_esi(void *);
#pragma aux arguments_to_esi = "" parm [esi] modify exact [];
extern PutCharacter incoming_writer(void);
#pragma aux incoming_writer = "" value [ecx] modify exact [];
extern void *incoming_destination(void);
#pragma aux incoming_destination = "" value [eax] modify exact [];
extern const char *incoming_pattern(void);
#pragma aux incoming_pattern = "" value [edx] modify exact [];
extern void clear_flag_byte(void);
#pragma aux clear_flag_byte = "xor bl,bl" modify exact [ebx];
extern unsigned char flag_byte(void);
#pragma aux flag_byte = "" value [bl] modify exact [];
extern void set_count_argument_width(void);
#pragma aux set_count_argument_width = "mov ebp,4" modify exact [];
extern const char *next_specifier(void);
#pragma aux next_specifier = value [eax] modify exact [];

/* %n accepts near and far pointers with the original Watcom stack widths. */
extern unsigned *count_pointer(void);
#pragma aux count_pointer = value [edx] modify exact [];
extern void store_far_count(unsigned);
#pragma aux store_far_count = "mov es:[edx],eax" parm [eax] modify exact [];
extern void store_far_short_count(unsigned);
#pragma aux store_far_short_count = 0x66 0x26 0x89 0x02 parm [eax] modify exact [];

/* Output uses the converted value's selector and leaves the callback count in
 * the format state. The state and the temporary text share one stack frame.
 */

extern void restore_format_frame(void);
#pragma aux restore_format_frame = "add esp,4ch" "pop ebp" "pop es" "pop edi" "pop esi" modify exact [];

typedef struct {
    char before_state[0x24];
    void *destination;
    int width;
    int length, precision_zeroes;
    unsigned count;
    unsigned char flags, type, pad;
    char prefix[5];
    PutCharacter writer;
    char scratch;
} FormatFrameView;

/* The register-call entry reserves its own frame before using its stack fields.
 * This stack view starts four bytes above the adjusted ESP because Watcom
 * treats it as a caller-cleaned stack argument.
 */
int format_engine(void *, const char *, void *, PutCharacter, volatile FormatFrameView);
#pragma aux format_engine parm caller [eax] [edx] [ebx] [ecx] [] modify exact [eax ebx ecx edx esi edi];
int format_engine(void *destination, const char *pattern, void *args, PutCharacter writer,
                  volatile FormatFrameView frame)
{
    FormatState *state;
    void *buffer, *scratch, *arguments;
    const char *conversion;
    unsigned char ch, flags;
    unsigned count;

    reserve_format_frame();
    arguments_to_esi(incoming_arguments());
    frame.writer = incoming_writer();
    clear_flag_byte();
    frame.destination = incoming_destination();
    frame.scratch = flag_byte();
    frame.flags = flag_byte();
    value_cursor_in_ebx(0);
    pattern_to_edi(incoming_pattern());
    frame.count = value_cursor();
    set_count_argument_width();
    goto scan_format;

parse_conversion:
    state = state_in_ebx((FormatState *)&frame.destination);
    arguments = args_in_edx(args_in_esi());
    conversion = parse_format_specifier(next_specifier(), arguments, state);
    pattern_to_edi(conversion);
    ch = byte_in_al(*(const unsigned char *)conversion);
    pattern_to_edi(pattern_in_edi() + 1);
    frame.type = ch;
    if (!ch)
        goto done;
    if (ch != 'n')
        goto format_value;
    flags = byte_in_bl(frame.flags);
    if (!(flags & 0x20))
        goto check_short_count;
    if (!(flags & 0x80))
        goto check_near_long_count;
    {
        unsigned char *cursor = count_cursor_ecx(*argument_list());
        cursor = count_cursor_ecx(cursor + 8);
        *argument_list() = cursor;
        read_far_count_ecx(cursor);
    }
store_far_count:
    store_far_count((unsigned)value_in_eax(frame.count));
    goto scan_format;

check_near_long_count:
    if (!(flags & 0x40))
        goto store_near_long_count;
    {
        unsigned char *cursor = count_cursor_ebx(*argument_list());
        cursor = count_cursor_ebx(cursor + count_argument_width());
        *argument_list() = cursor;
        count_address_to_edx(*(unsigned **)(cursor - 4));
    }
store_count:
    count = (unsigned)value_in_eax(frame.count);
    *count_pointer() = count;
scan_format:
    ch = byte_in_cl(*pattern_in_edi());
    if (!ch)
        goto done;
    pattern_in_eax(pattern_in_edi() + 1);
    if (ch == '%')
        goto parse_conversion;
    pattern_to_edi(next_specifier());
    clear_writer_byte();
    state = writer_state((FormatState *)&frame.destination);
    put_writer_byte(ch);
    frame.writer(state, writer_byte());
    goto scan_format;

store_near_long_count:
    {
        unsigned char *cursor = count_cursor_edx(*argument_list());
        cursor = count_cursor_edx(cursor + count_argument_width());
        *argument_list() = cursor;
        count_address_to_edx(*(unsigned **)(cursor - 4));
    }
    goto store_count;

check_short_count:
    if (!(flags & 0x10))
        goto check_default_far_count;
    if (!(flags & 0x80))
        goto check_near_short_count;
    {
        unsigned char *cursor = count_cursor_eax(*argument_list());
        cursor = count_cursor_eax(cursor + 8);
        *argument_list() = cursor;
        read_far_count_eax(cursor);
    }
    store_far_short_count((unsigned)value_in_eax(frame.count));
    goto scan_format;

check_near_short_count:
    if (!(flags & 0x40))
        goto read_short_count_pointer;
    {
        unsigned char *cursor = count_cursor_ecx(*argument_list());
        cursor = count_cursor_ecx(cursor + count_argument_width());
        *argument_list() = cursor;
        count_address_to_edx(*(unsigned **)(cursor - 4));
    }
store_short_count:
    count = (unsigned)value_in_eax(frame.count);
    *(unsigned short *)count_pointer() = (unsigned short)count;
    goto scan_format;

read_short_count_pointer:
    {
        unsigned char *cursor = count_cursor_ebx(*argument_list());
        cursor = count_cursor_ebx(cursor + count_argument_width());
        *argument_list() = cursor;
        count_address_to_edx(*(unsigned **)(cursor - 4));
    }
    goto store_short_count;

check_default_far_count:
    if (flags & 0x80) {
        {
        unsigned char *cursor = count_cursor_edx(*argument_list());
        cursor = count_cursor_edx(cursor + 8);
        *argument_list() = cursor;
        read_far_count_edx(cursor);
    }
        goto store_far_count;
    }
    if (!(flags & 0x40))
        goto read_default_count_pointer;
    {
        unsigned char *cursor = count_cursor_eax(*argument_list());
        cursor = count_cursor_eax(cursor + count_argument_width());
        *argument_list() = cursor;
        count_address_to_edx(*(unsigned **)(cursor - 4));
    }
    goto store_count;

read_default_count_pointer:
    {
        unsigned char *cursor = count_cursor_ecx(*argument_list());
        cursor = count_cursor_ecx(cursor + count_argument_width());
        *argument_list() = cursor;
        count_address_to_edx(*(unsigned **)(cursor - 4));
    }
    goto store_count;

format_value:
    buffer = buffer_in_eax((void *)((char *)&frame - 4));
    state = state_in_ebx((FormatState *)&frame.destination);
    scratch = scratch_in_ecx((void *)&frame.scratch);
    arguments = args_in_edx(args_in_esi());
    convert_format_value(buffer, arguments, state, scratch);
    select_value_segment();
    flags = byte_in_dl(frame.flags);
    value_cursor_in_ebx(converted_address());
    if (!(flags & 8) && frame.pad == ' ') {
        for (;;) {
            int width = value_in_eax(frame.width - 1);
            frame.width = width;
            if (width < 0)
                break;
            clear_writer_byte();
            state = writer_state((FormatState *)&frame.destination);
            put_writer_byte(frame.pad);
            frame.writer(state, writer_byte());
        }
    }
    prefix_in_ecx((const unsigned char *)frame.prefix);
    while ((ch = byte_in_al(*prefix_position())) != 0) {
        clear_writer_byte();
        put_writer_byte(ch);
        state = writer_state((FormatState *)&frame.destination);
        prefix_in_ecx(prefix_position() + 1);
        frame.writer(state, writer_byte());
    }

    for (;;) {
        int remaining = value_in_eax(frame.precision_zeroes);
        frame.precision_zeroes = value_in_ecx(remaining - 1);
        if (!remaining)
            break;
        frame.writer(writer_state((FormatState *)&frame.destination), '0');
    }

    if (!(frame.flags & 8) && frame.pad != ' ') {
        for (;;) {
            int width = value_in_eax(frame.width - 1);
            frame.width = width;
            if (width < 0)
                break;
            clear_writer_byte();
            state = writer_state((FormatState *)&frame.destination);
            put_writer_byte(frame.pad);
            frame.writer(state, writer_byte());
        }
    }

    ch = byte_in_dh(frame.type);
    if (ch != 's' && ch != 'S')
        goto emit_value;
    if (!(frame.flags & 0x20))
        goto emit_string;
    for (;;) {
        int remaining = value_in_eax(frame.length);
        frame.length = value_in_ecx(remaining - 1);
        if (!remaining)
            break;
        clear_writer_byte();
        state = writer_state((FormatState *)&frame.destination);
        load_far_value();
        frame.writer(state, writer_byte());
        value_cursor_in_ebx(value_cursor() + 2);
    }
    goto check_trailing_spaces;

emit_string:
    for (;;) {
        int remaining = value_in_eax(frame.length);
        frame.length = value_in_edx(remaining - 1);
        if (!remaining)
            break;
        clear_writer_byte();
        state = writer_state((FormatState *)&frame.destination);
        load_far_value();
        frame.writer(state, writer_byte());
        value_cursor_in_ebx(value_cursor() + 1);
    }
    goto check_trailing_spaces;

emit_value:
    for (;;) {
        int remaining = value_in_eax(frame.length);
        frame.length = value_in_ecx(remaining - 1);
        if (!remaining)
            break;
        clear_writer_byte();
        state = writer_state((FormatState *)&frame.destination);
        load_far_value();
        frame.writer(state, writer_byte());
        value_cursor_in_ebx(value_cursor() + 1);
    }

check_trailing_spaces:
    if (frame.flags & 8 && frame.width > 0) {
        for (;;) {
            int remaining = value_in_eax(frame.width);
            frame.width = value_in_edx(remaining - 1);
            if (!remaining)
                break;
            frame.writer(writer_state((FormatState *)&frame.destination), ' ');
        }
    }
    goto scan_format;

done:
    count = (unsigned)value_in_eax(frame.count);
    restore_format_frame();
    return count;
}
