#include "menurec.h"

#pragma pack(push, 1)
typedef struct {
    unsigned char reserved[7];
    int scancode;
} KeyBindingEntry;
#pragma pack(pop)

extern const char *key_scan_names[];
extern MenuRecord *key_entries[];
int validate_key_binding(int scan, int slot)
{
    int key = scan;
    int active_slot = slot;
    int binding;
    int status;
    if (scan == 1)
        return -1;
    if (!key_scan_names[scan][0])
        return -1;
    binding = 0;
    do {
        if (((const KeyBindingEntry *)key_entries[binding])->scancode == scan && binding != slot)
            return -2;
    } while (++binding < 25);
    status = 1;
    if (scan >= 2 && scan <= 11)
        status = -4;
    if (scan >= 59 && scan <= 68)
        status = -4;
    if (scan == 87 || scan == 88)
        status = -4;
    return status;
}
