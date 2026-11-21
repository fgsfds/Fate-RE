#include "cfgabi.h"

extern unsigned configuration_strlen(const char *);
#pragma aux configuration_strlen "strlen_" modify exact [eax];
extern char *configuration_long_to_string(long, char *, int);
#pragma aux configuration_long_to_string "ltoa_" parm [eax] [edx] [ebx] modify exact [eax edx ebx];
extern void *configuration_memmove(void *, const void *, unsigned);
#pragma aux configuration_memmove "memmove_" parm [eax] [edx] [ebx] modify exact [eax edx ebx];

/* These identities preserve Watcom register allocation without emitting code. */
extern unsigned char keep_output_character(unsigned char);
#pragma aux keep_output_character = "" parm [dl] value [dl] modify exact [];
extern unsigned char keep_flag_byte(unsigned char);
#pragma aux keep_flag_byte = "" parm [dh] value [dh] modify exact [];
extern unsigned char keep_terminator(unsigned char);
#pragma aux keep_terminator = "" parm [ah] value [ah] modify exact [];
extern int keep_success(int);
#pragma aux keep_success = "" parm [eax] value [eax] modify exact [];
extern unsigned char *keep_base_buffer(unsigned char *);
#pragma aux keep_base_buffer = "" parm [edx] value [edx] modify exact [];
extern unsigned keep_buffer_length(unsigned);
#pragma aux keep_buffer_length = "" parm [ebx] value [ebx] modify exact [];
extern unsigned keep_cap(unsigned);
#pragma aux keep_cap = "" parm [ebx] value [ebx] modify exact [];

extern unsigned keep_value_length(unsigned);
#pragma aux keep_value_length = "" parm [esi] value [esi] modify exact [];
extern unsigned char *keep_cursor(unsigned char *);
#pragma aux keep_cursor = "" parm [edx] value [edx] modify exact [];
extern int keep_output_index(int);
#pragma aux keep_output_index = "" parm [esi] value [esi] modify exact [];
extern unsigned keep_grow_base(unsigned);
#pragma aux keep_grow_base = "" parm [eax] value [eax] modify exact [];
extern unsigned char *keep_walk_pointer(unsigned char *);
#pragma aux keep_walk_pointer = "" parm [eax] value [eax] modify exact [];
extern int keep_space_character(int);
#pragma aux keep_space_character = "" parm [ecx] value [ecx] modify exact [];
int replace_configuration_value(Configuration *, long);
#pragma aux (config_call) replace_configuration_value;

int replace_configuration_value(Configuration *config, long value)
{
    unsigned char formatted[32];
    unsigned char *cursor = keep_cursor(config->value_start);
    unsigned char *start;
    unsigned old_length;
    unsigned new_length;
    unsigned i;
    unsigned char flags;
    int success;

    if (!cursor) {
    failed:
        return 0;
    }

    cursor = keep_walk_pointer(keep_cursor(cursor));
    while (keep_space_character((int)*cursor) == ' ')
        ++cursor;
    start = cursor;
    old_length = 0;
    for (;;) {
        union {
            unsigned full;
            unsigned char byte;
        } character;

        character.full = *cursor;
        if (character.full == '\r')
            break;
        old_length = keep_output_index(old_length + 1);
        ++cursor;
        formatted[old_length - 1] = character.byte;
    }
    formatted[old_length] = keep_terminator(0);
    /* Keep the existing 0x prefix when replacing hexadecimal digits. */
    if ((int)formatted[1] == 'x')
        configuration_long_to_string(value, (char *)formatted + 2, 16);
    else
        configuration_long_to_string(value, (char *)formatted, 10);
    new_length = configuration_strlen((char *)formatted);

    old_length = keep_value_length(old_length);
    if (new_length < old_length) {
        unsigned length;
        unsigned char *buffer;
        unsigned char *source;

        buffer = keep_base_buffer(config->buffer);
        length = keep_buffer_length(config->length);
        length += (unsigned)buffer;
        old_length -= new_length;
        length -= (unsigned)start;
        source = start + old_length;
        length -= old_length;
        configuration_memmove(start, source, length);
        config->length -= old_length;
    } else if (new_length > old_length) {
        old_length = new_length - old_length;
        if (config->length + old_length > keep_cap(config->capacity))
            goto failed;
        configuration_memmove(start + old_length, start,
                              keep_grow_base((unsigned)(config->buffer + config->length - start)) + old_length);
        config->length += old_length;
    }

    i = 0;
    for (;;) {
        unsigned char character = keep_output_character(formatted[i]);
        if (!character)
            break;
        ++i;
        *start = character;
        ++start;
    }

    flags = keep_flag_byte(((unsigned char *)&config->flags)[1]);
    flags = keep_flag_byte(flags | 0x80);
    success = keep_success(1);
    ((unsigned char *)&config->flags)[1] = flags;
    return success;
}
