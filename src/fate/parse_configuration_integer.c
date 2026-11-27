#include "cfgabi.h"

extern int parse_hexadecimal(const char *);
#pragma aux parse_hexadecimal modify exact [eax];
extern int configuration_atoi(const char *);
#pragma aux configuration_atoi "atoi_" modify exact [eax];

/* These register allocation hints emit no instructions. */
extern unsigned char *keep_token_cursor(unsigned char *);
#pragma aux keep_token_cursor = "" parm [edx] value [edx] modify exact [];
extern unsigned char *keep_active_cursor(unsigned char *);
#pragma aux keep_active_cursor = "" parm [eax] value [eax] modify exact [];
extern void defer_cursor_register_copy(void);
#pragma aux defer_cursor_register_copy = "" modify exact [eax];
extern int keep_leading_character(int);
#pragma aux keep_leading_character = "" parm [edx] value [edx] modify exact [];
extern int keep_trailing_character(int);
#pragma aux keep_trailing_character = "" parm [ebx] value [ebx] modify exact [];
extern unsigned keep_count(unsigned);
#pragma aux keep_count = "" parm [edx] value [edx] modify exact [];
extern unsigned char keep_terminator(unsigned char);
#pragma aux keep_terminator = "" parm [bl] value [bl] modify exact [];
extern int keep_status(int);
#pragma aux keep_status = "" parm [ebx] value [ebx] modify exact [];
extern int *keep_out(int *);
#pragma aux keep_out = "" parm [edx] value [edx] modify exact [];

int parse_configuration_integer(Configuration *, int *);
#pragma aux (config_call) parse_configuration_integer;

int parse_configuration_integer(Configuration *config, int *value)
{
    unsigned char *cursor;
    unsigned char *next;
    unsigned count;
    char digits[32];
    int character;
    int parsed;
    int status;

    next = keep_token_cursor(config->key_cursor);
    if (next) {
        defer_cursor_register_copy();
        cursor = keep_active_cursor(next);
    } else {
        cursor = config->value_start;
    }

    if (!cursor) {
    empty:
        return keep_status(0);
    }

    while ((character = keep_leading_character(*cursor)) == ' ')
        ++cursor;
    if (character == '\r')
        goto empty;

    count = 0;
    for (;;) {
        union {
            unsigned full;
            unsigned char byte;
        } digit;

        digit.full = *cursor;
        if (digit.full == '\r' || digit.full == ',' || digit.full == ' ')
            break;
        count = keep_count(count + 1);
        ++cursor;
        digits[count - 1] = digit.byte;
    }
    digits[count] = keep_terminator(0);
    if (!count)
        goto empty;

    for (;;) {
        character = keep_trailing_character(*cursor);
        next = cursor + 1;
        if (character != ' ')
            break;
        cursor = next;
    }
    if (character == ',')
        config->key_cursor = next;
    else
        config->key_cursor = cursor;

    if ((unsigned)(unsigned char)digits[1] == 'x')
        parsed = parse_hexadecimal(digits + 2);
    else
        parsed = configuration_atoi(digits);
    value = keep_out(value);
    status = keep_status(1);
    *value = parsed;
    return status;
}
