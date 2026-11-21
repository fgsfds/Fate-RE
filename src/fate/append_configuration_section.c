#include "cfgabi.h"
int find_configuration_section(Configuration *, const char *);
#pragma aux (config_call) find_configuration_section;
extern unsigned count_section_name(const char *);
#pragma aux count_section_name "strlen_" modify exact [eax];

extern unsigned char *keep_next(unsigned char *);
#pragma aux keep_next = "" parm [eax] value [eax] modify exact [];
extern unsigned char keep_section_character(unsigned char);
#pragma aux keep_section_character = "" parm [bl] value [bl] modify exact [];
/* Keep the terminating byte live in BL while updating the flags in BH. */
extern void preserve_section_end(unsigned char);
#pragma aux preserve_section_end = "" parm [bl] modify exact [];

int append_configuration_section(Configuration *, const char *);
#pragma aux (config_call) append_configuration_section;
int append_configuration_section(Configuration *config, const char *name)
{
    unsigned required;
    unsigned length;
    unsigned char flags, character;
    unsigned char *end;
    unsigned char *next;

    if (find_configuration_section(config, name))
        return 0;
    end = config->buffer + config->length;
    required = count_section_name(name) + 6;
    if (config->length + required > config->capacity)
        return 0;
    *end++ = '\r';
    *end++ = '\n';
    config->section_start = end;
    *end++ = '[';
    for (;;) {
        character = keep_section_character(*name);
        next = keep_next(end + 1);
        if (!character)
            break;
        ++name;
        *end = character;
        end = next;
    }
    *end = ']';
    end = next + 1;
    *next = '\r';
    *end++ = '\n';
    length = config->length;
    flags = ((unsigned char *)&config->flags)[1];
    config->section_insert = end;
    length += required;
    config->section_values = end;
    flags |= 0x80;
    config->length = length;
    ((unsigned char *)&config->flags)[1] = flags;
    preserve_section_end(character);
    return 1;
}
