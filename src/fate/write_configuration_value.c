#include "cfgabi.h"

extern unsigned configuration_strlen(const char *);
#pragma aux configuration_strlen "strlen_" modify exact [eax];
extern void *configuration_memmove(void *, const void *, unsigned);
#pragma aux configuration_memmove "memmove_" parm [eax] [edx] [ebx] modify exact [eax edx ebx];

/* These identities preserve Watcom's register allocation without emitting code. */
extern unsigned char *keep_configuration_start(unsigned char *);
#pragma aux keep_configuration_start = "" parm [esi] value [esi] modify exact [];
extern int keep_configuration_spacing(int);
#pragma aux keep_configuration_spacing = "" parm [esi] value [esi] modify exact [];
extern char keep_configuration_character(char);
#pragma aux keep_configuration_character = "" parm [ah] value [ah] modify exact [];
extern unsigned char keep_configuration_flags(unsigned char);
#pragma aux keep_configuration_flags = "" parm [dl] value [dl] modify exact [];

extern int keep_configuration_success(int);
#pragma aux keep_configuration_success = "" parm [eax] value [eax] modify exact [];
extern unsigned keep_configuration_tail_end(unsigned);
#pragma aux keep_configuration_tail_end = "" parm [ebx] value [ebx] modify exact [];
extern unsigned char *keep_configuration_buffer(unsigned char *);
#pragma aux keep_configuration_buffer = "" parm [eax] value [eax] modify exact [];
int write_configuration_value(Configuration *, const char *);

#pragma aux (config_call) write_configuration_value;

int write_configuration_value(Configuration *config, const char *value)
{
    unsigned char *cursor = config->value_start;

    if (cursor) {
        unsigned old_length = 0;
        unsigned new_length;
        unsigned char *start;

        while (keep_configuration_spacing((int)*cursor) == ' ')
            ++cursor;
        start = cursor;
        for (;;) {
            int ch = (int)*cursor;
            ++cursor;
            if (ch == '\r')
                break;
            ++old_length;
        }

        new_length = configuration_strlen(value);
        if (new_length < old_length) {
            unsigned tail;
            unsigned distance;
            unsigned char *source;

            tail = keep_configuration_tail_end((unsigned)(config->buffer + config->length));
            distance = old_length - new_length;
            tail -= (unsigned)start;
            source = start + distance;
            tail -= distance;
            configuration_memmove(start, source, tail);
            config->length -= distance;
        } else if (new_length > old_length) {
            unsigned distance = new_length - old_length;
            if (config->length + distance > config->capacity)
                return 0;
            {
                unsigned char *buffer = keep_configuration_buffer(config->buffer);
                unsigned tail = config->length;
                tail += (unsigned)buffer;
                tail -= (unsigned)start;
                tail += distance;
                configuration_memmove(start + distance, start, tail);
            }
            config->length += distance;
        }

        start = keep_configuration_start(start);
        for (;;) {
            char ch = keep_configuration_character(*value);
            if (!ch)
                break;
            ++value;
            *start = ch;
            ++start;
        }
        {
            unsigned char flags = keep_configuration_flags(((unsigned char *)&config->flags)[1]);
            int success;

            flags = keep_configuration_flags(flags | 0x80);
            success = keep_configuration_success(1);
            ((unsigned char *)&config->flags)[1] = flags;
            return success;
        }
    }
    return 0;
}
