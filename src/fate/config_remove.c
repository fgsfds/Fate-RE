#include "cfgabi.h"
int find_configuration_section(Configuration *, const char *);
#pragma aux (config_call) find_configuration_section;
void *move_configuration_bytes(void *, const void *, unsigned);
#pragma aux move_configuration_bytes "memmove_" parm [eax] [edx] [ebx] modify exact [eax edx ebx];

int remove_configuration_key(Configuration *, const char *);
#pragma aux (config_call) remove_configuration_key;
int remove_configuration_key(Configuration *config, const char *key)
{
    unsigned count = 0;
    int found = find_configuration_key(config, key);
    if (!found)
        return found;
    {
        unsigned char *start = config->key_start;
        for (;;) {
            int ch = start[count];
            ++count;
            if (ch == '\n')
                break;
        }
        move_configuration_bytes(start, start + count,
                                 config->buffer + config->length - (start + count));
        config->length -= count;
        config->flags |= 0x8000;
        return 1;
    }
}

int remove_configuration_section(Configuration *, const char *);
#pragma aux (config_call) remove_configuration_section;
int remove_configuration_section(Configuration *config, const char *name)
{
    int found = find_configuration_section(config, name);
    if (!found)
        return found;
    {
        unsigned char *end = config->buffer + config->length;
        unsigned char *start = config->section_start;
        unsigned count = 1;
        while ((int)start[count] != '[' && start + count < end)
            ++count;
        move_configuration_bytes(start, start + count, end - (start + count));
        config->length -= count;
        config->flags |= 0x8000;
        return 1;
    }
}
