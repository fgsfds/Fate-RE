#pragma pack(push, 1)
typedef struct {
    unsigned long edi, esi, ebp, reserved;
    unsigned long ebx, edx, ecx, eax;
    unsigned short flags, es, ds, fs, gs, ip, cs, sp, ss;
} RealModeRegisters;
#pragma pack(pop)

extern RealModeRegisters cd_registers;
extern unsigned short cd_request_segment, cd_driver_offset;
extern short cd_drive_letter, last_cd_track;
extern int selected_cd_track;
extern unsigned char cd_track_start[][5], cd_lead_out[4];

extern void *memset(void *, int, unsigned);
#pragma aux memset modify exact [eax edx ebx gs];
extern int simulate_real_mode_interrupt(int, RealModeRegisters *);
#pragma aux simulate_real_mode_interrupt modify exact [eax edx gs];
extern void stop_cd_driver_playback(void);
#pragma aux stop_cd_driver_playback modify exact [eax];

/* Keep the CD frame calculations in their original Watcom registers. */
extern long hold_frame_count(long);
#pragma aux hold_frame_count = parm [eax] value [eax] modify exact [];

/* Keep the lead-out frame addition in its original registers. */
extern long leadout_lba(long minutes_and_seconds, unsigned frame);
#pragma aux leadout_lba = "add eax, ebx" parm [eax] [ebx] value [eax] modify exact [eax];

int play_cd_track(unsigned char track)
{
    unsigned char __far *packet;
    short last = last_cd_track;
    int index, status;
    long start, duration;

    /* Skip data tracks while looking for audio. */
    for (;;) {
        index = track;
        if ((int)(unsigned char)(cd_track_start[index][4] & 0x40) != 0x40)
            break;
        ++track;
        if ((short)track >= last)
            return 0;
    }

    stop_cd_driver_playback();
    packet = (unsigned char __far *)(void *)((unsigned long)cd_request_segment << 4);
    memset((void *)packet, 0, 0x16);
    packet[0] = 0x16;
    packet[1] = 0;
    packet[2] = 0x84;
    packet[0xd] = 0;

    /* Convert the start time from minutes, seconds, and frames to an LBA. */
    start = cd_track_start[index][2] * 4500L + cd_track_start[index][1] * 75L;
    start = hold_frame_count(cd_track_start[index][0] + start) - 150;
    packet[0xf] = (unsigned char)(start >> 8);
    packet[0x10] = (unsigned char)(start >> 16);
    packet[0xe] = (unsigned char)start;
    packet[0x11] = (unsigned char)(start >> 24);

    /* Play from the track start to the disc lead-out. */
    duration = cd_lead_out[2] * 4500L + cd_lead_out[1] * 75L;
    duration = leadout_lba(duration, cd_lead_out[0]) - 150;
    duration = hold_frame_count(duration - start);
    packet[0x13] = (unsigned char)(duration >> 8);
    packet[0x12] = (unsigned char)duration;
    packet[0x14] = (unsigned char)(duration >> 16);
    packet[0x15] = (unsigned char)(duration >> 24);

    memset(&cd_registers, 0, sizeof(cd_registers));
    cd_registers.es = cd_request_segment;
    cd_registers.ebx = cd_driver_offset;
    cd_registers.eax = 0x1510;
    cd_registers.ecx = (long)cd_drive_letter - 'A';
    simulate_real_mode_interrupt(0x2f, &cd_registers);
    status = (unsigned char)(packet[4] & 1);
    if (status) {
        status = 1;
        selected_cd_track = index;
    }
    return status;
}
