#include "cfgabi.h"

extern unsigned configuration_strlen(const char *);
#pragma aux configuration_strlen "strlen_" modify exact [eax];
extern char *configuration_long_to_string(long, char *, int);
#pragma aux configuration_long_to_string "ltoa_" parm [eax] [edx] [ebx] modify exact [eax edx ebx];
extern void *configuration_memmove(void *, const void *, unsigned);
#pragma aux configuration_memmove "memmove_" parm [eax] [edx] [ebx] modify exact [eax edx ebx];
int replace_configuration_value(Configuration *, long);
#pragma aux (config_call) replace_configuration_value;

/* These hints preserve the Watcom register assignments without emitting code. */
extern unsigned char keep_key_character(unsigned char);
#pragma aux keep_key_character = "" parm [dh] value [dh] modify exact [];
extern unsigned char keep_value_character(unsigned char);
#pragma aux keep_value_character = "" parm [bl] value [bl] modify exact [];
extern unsigned char keep_written_flag(unsigned char);
#pragma aux keep_written_flag = "" parm [bh] value [bh] modify exact [];
extern int keep_successful_result(int);
#pragma aux keep_successful_result = "" parm [eax] value [eax] modify exact [];
extern unsigned char *keep_next(unsigned char *);
#pragma aux keep_next = "" parm [esi] value [esi] modify exact [];
extern unsigned keep_required(unsigned);
#pragma aux keep_required = "" parm [edx] value [edx] modify exact [];
extern unsigned keep_index(unsigned);
#pragma aux keep_index = "" parm [eax] value [eax] modify exact [];
extern unsigned keep_required_eax(unsigned);
#pragma aux keep_required_eax = "" parm [eax] value [eax] modify exact [];
extern long keep_replacement_parameter(long);
#pragma aux keep_replacement_parameter = "" parm [ecx] value [ecx] modify exact [];
extern void reset_index_after_equals(void);
#pragma aux reset_index_after_equals = "" modify exact [eax];
extern void defer_success(void);
#pragma aux defer_success = "" modify exact [eax];
extern unsigned keep_move_base_with_source(unsigned, unsigned char *);
#pragma aux keep_move_base_with_source = "" parm [eax] [edx] value [eax] modify exact [];
extern const char *keep_digits_early(const char *);
#pragma aux keep_digits_early = "" parm [eax] value [eax] modify exact [];
extern unsigned keep_required_after_digits(unsigned, const char *);
#pragma aux keep_required_after_digits = "" parm [edx] [eax] value [edx] modify exact [];
extern unsigned keep_capacity(unsigned);
#pragma aux keep_capacity = "" parm [eax] value [eax] modify exact [];
extern unsigned keep_live_length(unsigned);
#pragma aux keep_live_length = "" parm [esi] value [esi] modify exact [];
extern unsigned keep_length(unsigned);
#pragma aux keep_length = "" parm [esi] value [esi] modify exact [];
extern unsigned char *keep_insert(unsigned char *);
#pragma aux keep_insert = "" parm [ecx] value [ecx] modify exact [];

int append_configuration_integer(Configuration *, const char *, long, int, int);
#pragma aux (config_call) append_configuration_integer;
int append_configuration_integer(Configuration *config, const char *key, long value, int width, int radix)
{
    char digits[32];
    const char *number;
    unsigned required;
    volatile unsigned stored;
    unsigned length;
    unsigned index;
    int result;
    unsigned char *insert, *next;
    unsigned char flags;

    if (find_configuration_key(config, key)) {
        replace_configuration_value(config, keep_replacement_parameter(value));
        return 1;
    }
    if (radix == 16) {
        digits[0] = '0';
        digits[1] = 'x';
        configuration_long_to_string(value, digits + 2, 16);
    } else {
        configuration_long_to_string(value, digits, 10);
    }

    number = keep_digits_early(digits);
    required = keep_required_after_digits(keep_required(width + 4), number);
    insert = keep_insert(config->section_values);
    required += configuration_strlen(number);
    length = keep_required_eax(config->length);
    stored = required;
    if (keep_capacity(length + required) > *(volatile unsigned *)&config->capacity)
        return 0;
    {
        unsigned tail, beginning, displacement;
        unsigned char *source;

        beginning = (unsigned)config->buffer;
        tail = config->length;
        source = insert;
        tail += keep_move_base_with_source(beginning, source);
        displacement = stored;
        tail -= (unsigned)insert;
        configuration_memmove(insert + displacement, source, tail);
    }

    for (;;) {
        unsigned char character = keep_key_character(*key);
        if (!character)
            break;
        ++key;
        --width;
        *insert = character;
        ++insert;
    }
    for (;;) {
        --width;
        if (width == -1) {
            next = keep_next(insert + 1);
            break;
        }
        *insert = ' ';
        insert = keep_next(insert + 1);
    }

    *insert = '=';
    reset_index_after_equals();
    index = keep_index(0);
    insert = keep_insert(insert);
    insert = next + 1;
    *next = ' ';
    for (;;) {
        unsigned char character = keep_value_character(digits[index]);
        next = keep_next(insert + 1);
        if (!character)
            break;
        index = keep_index(index + 1);
        *insert = character;
        insert = next;
    }

    *insert = '\r';
    *next = '\n';
    required = keep_required_eax(stored);
    length = keep_length(config->length);
    flags = keep_written_flag(((unsigned char *)&config->flags)[1]);
    length = keep_live_length(length + required);
    flags = keep_written_flag(flags | 0x80);
    config->length = length;
    defer_success();
    result = keep_successful_result(1);
    ((unsigned char *)&config->flags)[1] = flags;
    return result;
}
