#ifndef FATE_CONFIG_ABI_H
#define FATE_CONFIG_ABI_H

typedef struct Configuration {
    unsigned flags;
    char filename[128];
    unsigned char *buffer;
    unsigned length;
    unsigned capacity;
    unsigned char *section_values;
    unsigned section_offset;
    unsigned char *section_start;
    unsigned char *key_start;
    unsigned char *value_start;
    unsigned char *key_cursor;
    unsigned char *section_insert;
} Configuration;
typedef char ConfigurationAbiSize[sizeof(Configuration) == 0xac ? 1 : -1];

/* This module passes arguments on the stack and uses EBX as scratch. */
#pragma aux config_call parm caller [] modify exact [eax ebx ecx edx];

int read_configuration_integer(Configuration *configuration, const char *key, int *value);
int find_configuration_key(Configuration *configuration, const char *key);
int close_configuration(Configuration *configuration);
#pragma aux (config_call) read_configuration_integer;
#pragma aux (config_call) find_configuration_key;
#pragma aux (config_call) close_configuration;

#endif
