extern unsigned short cd_request_segment;
extern int send_cd_driver_request(short, short, short);
#pragma aux send_cd_driver_request modify exact [eax edx ebx gs];

extern unsigned short first_cd_track, last_cd_track;
extern unsigned char cd_lead_out[4];
void read_cd_track_info(short handle)
{
    unsigned first, last;
    unsigned char __far *packet = (unsigned char __far *)(void *)((unsigned long)cd_request_segment << 4);
    packet[0] = 0x0a;
    send_cd_driver_request(handle, 8, 0x4402);
    first = packet[1];
    first_cd_track = first;
    last = packet[2];
    last_cd_track = last;
    cd_lead_out[0] = packet[3];
    cd_lead_out[1] = packet[4];
    cd_lead_out[2] = packet[5];
    cd_lead_out[3] = packet[6];
}
