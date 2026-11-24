#include "dpmiregs.h"

typedef union {
    BiosRegisters bios;
    unsigned short word[8];
    unsigned char byte[16];
} VesaRegisters;
extern int get_vesa_mode_info(BiosRegisters *, void *, unsigned);
#pragma aux get_vesa_mode_info modify exact [eax ebx edx];
int query_vesa_mode(unsigned short mode, unsigned short *info)
{
    VesaRegisters registers;
    int result;
    registers.bios.cx = mode;
    registers.bios.ax = 0x4f01;
    get_vesa_mode_info(&registers.bios, info, 256);
    result = (unsigned short)registers.bios.ax;
    if (result != 0x4f) {
        result = 0;
    } else {
        short flags = *info;
        result = (short)(flags & 1);
        if (result)
            result = 1;
    }
    return result;
}
