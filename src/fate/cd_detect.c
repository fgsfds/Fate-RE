#pragma pack(push, 1)
typedef struct {
    unsigned long edi, esi, ebp, reserved;
    unsigned long ebx, edx, ecx, eax;
    unsigned short flags, es, ds, fs, gs, ip, cs, sp, ss;
} RealModeRegisters;
#pragma pack(pop)
extern RealModeRegisters cd_registers;
extern short cd_drive_letter;
extern void *memset(void *, int, unsigned);
#pragma aux memset modify exact [eax edx ebx];
extern int simulate_real_mode_interrupt(int, RealModeRegisters *);
#pragma aux simulate_real_mode_interrupt modify exact [eax edx];
int detect_cd_drives(void)
{
    memset(&cd_registers, 0, sizeof(cd_registers));
    cd_registers.eax = 0x1500;
    cd_registers.ebx = 0;
    simulate_real_mode_interrupt(0x2f, &cd_registers);
    if (cd_registers.ebx) {
        cd_drive_letter = (short)cd_registers.ecx + 'A';
        return cd_registers.ecx + 'A';
    }
    return 0;
}
