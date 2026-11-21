#include "cfgabi.h"
extern const char configuration_true_output[], configuration_false_output[];
int write_configuration_value(Configuration *, const char *);
#pragma aux (config_call) write_configuration_value;

int write_configuration_boolean(Configuration *, const char *, int);
#pragma aux (config_call) write_configuration_boolean;
int write_configuration_boolean(Configuration *config, const char *key, int value)
{
    int found = find_configuration_key(config, key);
    if (!found)
        return found;

    if (value) {
        found = write_configuration_value(config, configuration_true_output);
        if (!found)
            return found;
    } else {
        found = write_configuration_value(config, configuration_false_output);
        if (!found)
            return found;
    }
    return 1;
}
