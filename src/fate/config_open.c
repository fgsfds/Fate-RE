#include "cfgabi.h"
#include "dosio.h"

extern char *copy_filename(char *, const char *);
#pragma aux copy_filename "strcpy_" modify exact [eax];
extern void *allocate_config_buffer(unsigned);
#pragma aux allocate_config_buffer "malloc_" modify exact [eax];
extern void release_config_buffer(void *);
#pragma aux release_config_buffer "free_" modify exact [eax];

int open_configuration(Configuration *, const char *);
#pragma aux (config_call) open_configuration;
int open_configuration(Configuration *config, const char *filename)
{
    int descriptor;
    copy_filename(config->filename, filename);
    descriptor = dos_open(filename, 0x200);
    if (descriptor == -1)
        return 0;
    config->length = lseek(descriptor, 0, 2);
    config->capacity = config->length + 1024;
    lseek(descriptor, 0, 0);
    if (!(config->buffer = allocate_config_buffer(config->capacity))) {
        close(descriptor);
        return 0;
    }
    if (read(descriptor, config->buffer, config->length) != config->length) {
        close(descriptor);
        release_config_buffer(config->buffer);
        return 0;
    }
    close(descriptor);
    config->section_offset = 0;
    config->value_start = 0;
    config->key_cursor = 0;
    {
        unsigned char *buffer = config->buffer;
        config->key_start = 0;
        config->section_values = buffer;
    }
    config->section_insert = 0;
    config->flags &= ~0x8000;
    return 1;
}
