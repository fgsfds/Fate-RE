#pragma pack(push, 1)
typedef struct {
    unsigned long edi, esi, ebp, reserved;
    unsigned long ebx, edx, ecx, eax;
    unsigned short flags, es, ds, fs, gs, ip, cs, sp, ss;
} RealModeRegisters;
#pragma pack(pop)
extern RealModeRegisters cd_registers;
extern unsigned short cd_request_segment, cd_driver_offset;
extern short cd_drive_letter;
extern unsigned short active_cd_track, cd_playback_pending;
extern void *memset(void *, int, unsigned);
#pragma aux memset modify exact [eax edx ebx gs];
extern int simulate_real_mode_interrupt(int, RealModeRegisters *);
#pragma aux simulate_real_mode_interrupt modify exact [eax edx];

void stop_cd_driver_playback(void)
{
    unsigned char __far *packet = (unsigned char __far *)(void *)((unsigned long)cd_request_segment << 4);
    memset((void *)packet, 0, 0x16);
    packet[0] = 0x16;
    packet[1] = 0;
    packet[2] = 0x85;
    memset(&cd_registers, 0, sizeof(cd_registers));
    cd_registers.es = cd_request_segment;
    cd_registers.ebx = cd_driver_offset;
    cd_registers.eax = 0x1510;
    cd_registers.ecx = (long)cd_drive_letter - 'A';
    simulate_real_mode_interrupt(0x2f, &cd_registers);
    cd_playback_pending = active_cd_track = 0;
}

void resume_cd_driver_playback(void)
{
    unsigned char __far *packet = (unsigned char __far *)(void *)((unsigned long)cd_request_segment << 4);
    memset((void *)packet, 0, 0x16);
    packet[0] = 0x16;
    packet[1] = 0;
    packet[2] = 0x88;
    memset(&cd_registers, 0, sizeof(cd_registers));
    cd_registers.es = cd_request_segment;
    cd_registers.ebx = cd_driver_offset;
    cd_registers.eax = 0x1510;
    cd_registers.ecx = (long)cd_drive_letter - 'A';
    simulate_real_mode_interrupt(0x2f, &cd_registers);
}
