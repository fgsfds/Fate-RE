#include "cfgabi.h"

int find_configuration_key(Configuration *config, const char *key)
{
    unsigned char *cursor = config->section_values;
    unsigned offset = config->section_offset;
    int found = 0;

    do {
        if (*cursor == (unsigned char)*key) {
            unsigned char *start = cursor;
            const char *name = key + 1;
            ++offset;
            ++cursor;
            while (*cursor == (unsigned char)*name && offset < config->length) {
                ++cursor;
                ++name;
                ++offset;
            }
            if (*name == 0) {
                while ((int)*cursor != '=' && (int)*cursor != '\r') {
                    ++cursor;
                    ++offset;
                }
                if ((int)*cursor == '=') {
                    ++cursor;
                    ++offset;
                    config->value_start = cursor;
                } else {
                    config->value_start = 0;
                }
                config->key_cursor = 0;
                found = 1;
                config->key_start = start;
            }
        }
        ++cursor;
        ++offset;
    } while (!found && offset < config->length && (int)*cursor != '[');
    return found;
}

/* These register allocation hints emit no instructions. */
extern int keep_success(int);
#pragma aux keep_success = "" parm [ebx] value [ebx] modify exact [];
extern int keep_leading(int);
#pragma aux keep_leading = "" parm [ebx] value [ebx] modify exact [];
extern int keep_initial(int);
#pragma aux keep_initial = "" parm [edx] value [edx] modify exact [];
extern unsigned char keep_character(unsigned char);
#pragma aux keep_character = "" parm [cl] value [cl] modify exact [];
extern unsigned char *keep_current_pointer(unsigned char *);
#pragma aux keep_current_pointer = "" parm [eax] value [eax] modify exact [];
extern unsigned char *keep_old_cursor(unsigned char *);
#pragma aux keep_old_cursor = "" parm [esi] value [esi] modify exact [];
extern char *keep_line(char *);
#pragma aux keep_line = "" parm [edi] value [edi] modify exact [];
extern unsigned keep_output_index(unsigned);
#pragma aux keep_output_index = "" parm [ebx] value [ebx] modify exact [];

int read_configuration_line(Configuration *, char *, unsigned);
#pragma aux (config_call) read_configuration_line;

int read_configuration_line(Configuration *config, char *line, volatile unsigned capacity)
{
    unsigned char *cursor = config->section_insert;
    unsigned char *end;
    unsigned count;
    int result;
    int first;

    line = keep_line(line);
    if (!cursor || (first = keep_initial(*cursor)) == '[' || first == '\r')
        result = keep_success(0);
    else {
        end = config->buffer + config->length;
        count = 0;
        while (keep_leading(*cursor) == ' ')
            ++cursor;
        while ((int)*cursor != '\r' && count < capacity - 1) {
            unsigned char *former = keep_old_cursor(cursor);
            unsigned index = keep_output_index(count);
            unsigned char character;

            cursor = keep_current_pointer(cursor + 1);
            character = keep_character(*former);
            ++count;
            line[index] = character;
        }

        cursor += 2;
        line[count] = '\0';
        if (cursor >= end)
            config->section_insert = 0;
        else
            config->section_insert = cursor;
        result = keep_success(1);
    }
    return result;
}

extern unsigned configuration_strlen(const char *);
#pragma aux configuration_strlen "strlen_" modify exact [eax];
extern void *configuration_memmove(void *, const void *, unsigned);
#pragma aux configuration_memmove "memmove_" parm [eax] [edx] [ebx] modify exact [eax edx ebx];
int write_configuration_value(Configuration *, const char *);
#pragma aux (config_call) write_configuration_value;

/* These hints preserve the original register assignments without emitting code. */
extern unsigned char keep_key_character(unsigned char);
#pragma aux keep_key_character = "" parm [ah] value [ah] modify exact [];
extern unsigned char keep_value_character(unsigned char);
#pragma aux keep_value_character = "" parm [dl] value [dl] modify exact [];
extern unsigned char keep_written_flag(unsigned char);
#pragma aux keep_written_flag = "" parm [dh] value [dh] modify exact [];
extern int keep_successful_result(int);
#pragma aux keep_successful_result = "" parm [eax] value [eax] modify exact [];
extern unsigned char *keep_next(unsigned char *);
#pragma aux keep_next = "" parm [edi] value [edi] modify exact [];
extern unsigned keep_required_eax(unsigned);
#pragma aux keep_required_eax = "" parm [eax] value [eax] modify exact [];
extern unsigned char *keep_insert(unsigned char *);
#pragma aux keep_insert = "" parm [ecx] value [ecx] modify exact [];

extern const char *keep_value_for_length(const char *);
#pragma aux keep_value_for_length = "" parm [eax] value [eax] modify exact [];
extern unsigned keep_required_with_value(unsigned, const char *);
#pragma aux keep_required_with_value = "" parm [ebx] [eax] value [ebx] modify exact [];
extern Configuration *keep_section_owner(Configuration *);
#pragma aux keep_section_owner = "" parm [ecx] value [ecx] modify exact [];
extern void postpone_end_config_load(void);
#pragma aux postpone_end_config_load = "" modify exact [ebx];
extern const char *keep_value_input(const char *);
#pragma aux keep_value_input = "" parm [esi] value [esi] modify exact [];
extern Configuration *keep_config_on_success(Configuration *);
#pragma aux keep_config_on_success = "" parm [ebx] value [ebx] modify exact [];
extern unsigned keep_config_length(unsigned);
#pragma aux keep_config_length = "" parm [ecx] value [ecx] modify exact [];
extern unsigned keep_config_count(unsigned);
#pragma aux keep_config_count = "" parm [edx] value [edx] modify exact [];
extern unsigned keep_config_tail(unsigned);
#pragma aux keep_config_tail = "" parm [ebx] value [ebx] modify exact [];
extern void defer_append_success(void);
#pragma aux defer_append_success = "" modify exact [eax];
int append_configuration_value(Configuration *, const char *, const char *, int);
#pragma aux (config_call) append_configuration_value;
int append_configuration_value(Configuration *config, const char *key, const char *value, int width)
{
    Configuration *owner;
    Configuration *copy_config;
    const char *number;
    volatile unsigned stored;
    unsigned required;
    unsigned length;
    int result;
    unsigned char *insert;
    unsigned char *next;
    unsigned char flags;

    value = keep_value_input(value);
    if (find_configuration_key(config, key)) {
        write_configuration_value(keep_config_on_success(config), value);
        return 1;
    }

    owner = keep_section_owner(config);
    number = keep_value_for_length(value);
    required = keep_required_with_value(width + 4, number);
    insert = keep_insert(owner->section_values);
    required += configuration_strlen(number);
    length = keep_required_eax(config->length);
    stored = required;
    length = length + required;
    copy_config = keep_config_on_success(config);
    if (length > copy_config->capacity)
        return 0;
    {
        unsigned beginning, tail, displacement;
        unsigned char *source;

        beginning = keep_required_eax((unsigned)copy_config->buffer);
        tail = keep_config_count(copy_config->length);
        tail = keep_config_tail(beginning + tail);
        displacement = stored;
        source = insert;
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
    insert = next + 1;
    *next = ' ';
    for (;;) {
        unsigned char character = keep_value_character(*value);
        next = keep_next(insert + 1);
        if (!character)
            break;
        ++value;
        *insert = character;
        insert = next;
    }

    *insert = '\r';
    postpone_end_config_load();
    config = keep_config_on_success(config);
    *next = '\n';
    required = keep_required_eax(stored);
    length = keep_config_length(config->length);
    flags = keep_written_flag(((unsigned char *)&config->flags)[1]);
    length = keep_config_length(length + required);
    flags = keep_written_flag(flags | 0x80);
    config->length = length;
    defer_append_success();
    result = keep_successful_result(1);
    ((unsigned char *)&config->flags)[1] = flags;
    return result;
}
