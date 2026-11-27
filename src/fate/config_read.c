#include "cfgabi.h"

extern int parse_configuration_integer(Configuration *configuration, int *value);
extern int copy_configuration_value(Configuration *configuration, char *value, unsigned capacity);
#pragma aux (config_call) parse_configuration_integer;
#pragma aux (config_call) copy_configuration_value;

extern int stricmp(const char *left, const char *right);
#pragma aux stricmp modify exact [eax ecx edx];
extern const char configuration_true[];

int read_configuration_boolean(Configuration *configuration, const char *key);
int read_configuration_string(Configuration *configuration, const char *key, char *value, unsigned capacity);
#pragma aux (config_call) read_configuration_boolean;
#pragma aux (config_call) read_configuration_string;

int read_configuration_boolean(Configuration *configuration, const char *key)
{
    char value[32];
    int found = find_configuration_key(configuration, key);
    if (!found)
        return found;
    found = copy_configuration_value(configuration, value, sizeof(value));
    if (!found)
        return found;
    if (stricmp(value, configuration_true) == 0)
        return 1;
    return 0;
}

int read_configuration_integer(Configuration *configuration, const char *key, int *value)
{
    int found = find_configuration_key(configuration, key);
    if (!found)
        return found;
    found = parse_configuration_integer(configuration, value);
    if (!found)
        return found;
    return 1;
}

int read_configuration_string(Configuration *configuration, const char *key, char *value, unsigned capacity)
{
    int found = find_configuration_key(configuration, key);
    if (!found)
        return found;
    found = copy_configuration_value(configuration, value, capacity);
    if (!found)
        return found;
    return 1;
}
