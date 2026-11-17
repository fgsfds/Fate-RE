#include "dosio.h"

#pragma pack(push, 1)
typedef union {
    unsigned char __far *pointer;
    struct {
        unsigned long offset;
        unsigned short selector;
    } parts;
} CdFarAddress;
#pragma pack(pop)
extern unsigned short dos_segment, dos_buffer_offset;
extern unsigned short cd_request_segment, cd_driver_offset;
extern unsigned short cd_header_segment, cd_header_offset;
extern void __far *cd_request_address;
extern CdFarAddress cd_header_address;
extern char cd_driver_name[];
extern short cd_probe_result, cd_device_handle;
extern short first_cd_track, last_cd_track;
extern int selected_cd_track;

extern void __far *allocate_dos_memory(short);
#pragma aux allocate_dos_memory modify exact [eax edx];
extern int detect_cd_drives(void);
#pragma aux detect_cd_drives modify exact [eax];
extern void prepare_cd_request_buffers(void);
#pragma aux prepare_cd_request_buffers modify exact [eax];
extern int request_cd_disk_info(int);
#pragma aux request_cd_disk_info modify exact [eax];
extern void read_cd_track_info(short);
#pragma aux read_cd_track_info modify exact [eax];
extern void read_cd_track_start(short, unsigned char);
#pragma aux read_cd_track_start modify exact [eax edx];
extern void __far *far_memmove(void __far *, const void __far *, unsigned);
#pragma aux far_memmove modify exact [eax ebx ecx edx];

int initialize_cd_audio(void)
{
    unsigned char __far *packet;
    int track;
    cd_probe_result = (short)detect_cd_drives();
    if (!cd_probe_result)
        return 0;
    if (!allocate_dos_memory(0x16))
        return 0;
    cd_request_segment = dos_segment;
    cd_driver_offset = dos_buffer_offset;
    prepare_cd_request_buffers();
    packet = cd_request_address;
    cd_header_segment = (packet[4] << 8) + packet[3];
    cd_header_offset = (packet[2] << 8) + packet[1];
    cd_header_address.pointer = (unsigned char __far *)(void *)((unsigned long)cd_header_segment << 4);
    far_memmove((void __far *)cd_driver_name, cd_header_address.pointer + 10, 8);
    if ((cd_device_handle = (short)dos_open(cd_driver_name, 2)) == -1)
        return 0;
    request_cd_disk_info(cd_device_handle);
    read_cd_track_info(cd_device_handle);
    for (track = first_cd_track; track <= last_cd_track; ++track)
        read_cd_track_start(cd_device_handle, (unsigned char)track);
    selected_cd_track = first_cd_track;
    return 1;
}
