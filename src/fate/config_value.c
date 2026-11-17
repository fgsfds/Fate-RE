#include "cfgabi.h"

int copy_configuration_value(Configuration *, char *, unsigned);
#pragma aux (config_call) copy_configuration_value;
int copy_configuration_value(Configuration *config, char *output, unsigned size)
{
    const unsigned char *cursor;
    unsigned count;
    if (config->key_cursor)
        cursor = config->key_cursor;
    else
        cursor = config->value_start;
    if (!cursor)
        return 0;
    count = 0;
    while ((int)*cursor == ' ')
        ++cursor;
    while ((int)*cursor != '\r' && (int)*cursor != ',' && count < size - 1)
        output[count++] = *cursor++;
    output[count] = '\0';
    if (count == size - 1) {
        while ((int)*cursor != '\r' && (int)*cursor != ',')
            ++cursor;
    }
    if ((int)*cursor == ',')
        ++cursor;
    ((volatile Configuration *)config)->key_cursor = (unsigned char *)cursor;
    return 1;
}
