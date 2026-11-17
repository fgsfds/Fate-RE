typedef union {
    unsigned short word[8];
    unsigned char byte[16];
} VesaRegisters;
extern int get_vesa_mode_info(VesaRegisters *, void *, unsigned);
#pragma aux get_vesa_mode_info modify exact [eax ebx edx];
int query_vesa_mode(unsigned short mode, unsigned short *info)
{
    VesaRegisters registers;
    int result;
    registers.word[2] = mode;
    registers.word[0] = 0x4f01;
    get_vesa_mode_info(&registers, info, 256);
    result = (unsigned short)registers.word[0];
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
