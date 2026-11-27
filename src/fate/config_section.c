#include "cfgabi.h"

/* Keep the original byte widening and scan pointer registers in Watcom. */
extern unsigned section_byte(unsigned);
#pragma aux section_byte = parm [edx] value [edx] modify exact [];
extern unsigned header_byte(unsigned);
#pragma aux header_byte = parm [ecx] value [ecx] modify exact [];

extern unsigned char *following_byte(unsigned char *);
#pragma aux following_byte = parm [edx] value [edx] modify exact [];

extern void keep_scan_position(const unsigned char *);
#pragma aux keep_scan_position = parm [eax] modify exact [];

int find_configuration_section(Configuration *, const char *);
#pragma aux (config_call) find_configuration_section;
int find_configuration_section(Configuration *config, const char *name)
{
    unsigned char *cursor = config->buffer;
    int found = 0;
    unsigned offset = 0;
    do {
        if (section_byte(*cursor) == '[') {
            const char *key = name;
            unsigned char *header = cursor++;
            while (*cursor == (unsigned char)*key && offset < config->length) {
                ++key;
                ++cursor;
                ++offset;
            }
            if (header_byte(*cursor) == ']' && *key == '\0') {
                unsigned char *next;
                found = 1;
                for (;;) {
                    unsigned ch = header_byte(*cursor);
                    next = following_byte(cursor + 1);
                    if (ch == '\n')
                        break;
                    cursor = next;
                }
                config->section_insert = next;
                config->section_values = next;
                config->section_offset = offset;
                /* Keep the current pointer live until these fields are written. */
                keep_scan_position(cursor);
                cursor = next;
                config->section_start = header;
            }
        }
        ++cursor;
        ++offset;
    } while (!found && offset < config->length);
    return found;
}
