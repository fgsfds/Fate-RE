#include "cfgabi.h"

extern int config_open_file(const char *filename, int flags, ...);
#pragma aux config_open_file "open_" parm caller [] modify exact [eax edx];
extern int write(int descriptor, const void *data, unsigned count);
#pragma aux write modify exact [eax ebx edx];
extern int close(int descriptor);
#pragma aux close modify exact [eax];
extern void free(void *data);
#pragma aux free modify exact [eax];

int close_configuration(Configuration *config)
{
    if (config->flags & 0x8000) {
        int file = config_open_file(config->filename, 0x262, 0);
        if (file == -1) {
            free(config->buffer);
            return 0;
        }
        write(file, config->buffer, config->length);
        close(file);
    }
    free(config->buffer);
    return 1;
}
