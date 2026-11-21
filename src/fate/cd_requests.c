#pragma pack(push, 1)
typedef struct {
    unsigned long edi, esi, ebp, reserved;
    unsigned long ebx, edx, ecx, eax;
    unsigned short flags, es, ds, fs, gs, ip, cs, sp, ss;
} RealModeRegisters;
#pragma pack(pop)
extern RealModeRegisters cd_registers;
extern unsigned short cd_request_segment, cd_driver_offset;
extern short cd_probe_result;
extern unsigned short dos_segment, dos_buffer_offset, cd_buffers_segment, cd_buffer_offset;
extern void __far *cd_request_address;
extern void *memset(void *, int, unsigned);
#pragma aux memset modify exact [eax edx ebx];
extern int simulate_real_mode_interrupt(int, RealModeRegisters *);
#pragma aux simulate_real_mode_interrupt modify exact [eax edx];
extern void __far *allocate_dos_memory(short);
#pragma aux allocate_dos_memory modify exact [eax edx];

void prepare_cd_request_buffers(void)
{
    if (allocate_dos_memory(cd_probe_result * 5) != 0) {
        cd_buffers_segment = dos_segment;
        cd_buffer_offset = dos_buffer_offset;
        cd_request_address = (void __far *)(void *)((unsigned long)cd_buffers_segment << 4);
    }
    memset(&cd_registers, 0, sizeof(cd_registers));
    cd_registers.eax = 0x1501;
    cd_registers.ebx = cd_buffer_offset;
    cd_registers.es = cd_buffers_segment;
    simulate_real_mode_interrupt(0x2f, &cd_registers);
}

int send_cd_driver_request(short handle, short length, short command);
#pragma aux send_cd_driver_request modify exact [eax edx ebx gs];
int send_cd_driver_request(short handle, short length, short command)
{
    memset(&cd_registers, 0, sizeof(cd_registers));
    cd_registers.ebx = handle;
    cd_registers.ds = cd_request_segment;
    cd_registers.edx = cd_driver_offset;
    cd_registers.ecx = length;
    cd_registers.eax = command;
    return simulate_real_mode_interrupt(0x21, &cd_registers);
}

int request_cd_device_status(short handle)
{
    unsigned char __far *packet = (unsigned char __far *)(void *)((unsigned long)cd_request_segment << 4);
    packet[0] = 0;
    return send_cd_driver_request(handle, 1, 0x4403);
}

int request_cd_device_control(int handle)
{
    unsigned char __far *packet = (unsigned char __far *)(void *)((unsigned long)cd_request_segment << 4);
    packet[0] = 5;
    return send_cd_driver_request(handle, 1, 0x4403);
}

int request_cd_disk_info(int handle)
{
    unsigned char __far *packet = (unsigned char __far *)(void *)((unsigned long)cd_request_segment << 4);
    packet[0] = 2;
    return send_cd_driver_request(handle, 1, 0x4403);
}

extern unsigned char cd_track_start[][5];
void read_cd_track_start(short handle, unsigned char track)
{
    unsigned char __far *packet = (unsigned char __far *)(void *)((unsigned long)cd_request_segment << 4);
    packet[1] = track;
    packet[0] = 0x0b;
    send_cd_driver_request(handle, 8, 0x4402);
    cd_track_start[track][0] = packet[2];
    cd_track_start[track][1] = packet[3];
    cd_track_start[track][2] = packet[4];
    cd_track_start[track][3] = packet[5];
    cd_track_start[track][4] = packet[6];
}
