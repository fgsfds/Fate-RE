typedef union {
    unsigned short word[8];
    unsigned char byte[16];
} VesaRegisters;
extern unsigned char vesa_capabilities;
extern int dpmi_real_mode_interrupt(int, VesaRegisters *, VesaRegisters *);
#pragma aux dpmi_real_mode_interrupt modify exact [eax ebx edx];
int set_vesa_dac_width(int width)
{
    VesaRegisters registers;
    if (!(vesa_capabilities & 1))
        return 6;
    registers.word[0] = 0x4f08;
    registers.word[1] = width << 8;
    dpmi_real_mode_interrupt(0x10, &registers, &registers);
    return registers.byte[3];
}
