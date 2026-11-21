/* Use the DOS exchange block to request a DPMI audio buffer. */
extern int allocate_exchange_block(unsigned, unsigned long *, unsigned long *);
#pragma aux allocate_exchange_block parm caller [] modify exact [eax];
extern int release_exchange_block(unsigned long, unsigned long);
#pragma aux release_exchange_block parm caller [] modify exact [eax];
extern int free_dpmi_buffer(unsigned long);
#pragma aux free_dpmi_buffer parm caller [] modify exact [eax];
extern void __far *copy_audio_exchange(void __far *, const void __far *, unsigned);
#pragma aux copy_audio_exchange "_fmemcpy_" parm routine [dx eax] [cx ebx] [] modify exact [eax ebx ecx edx];
extern unsigned char dpmi_audio_exchange[16];
/* The original register ABI supplies an additional input in EBX. */
extern unsigned long current_buffer_cookie(void);
#pragma aux current_buffer_cookie = "" value [ebx] modify exact [];
typedef void __far *AudioFarBuffer;

extern unsigned long *current_physical_output(void);
#pragma aux current_physical_output = "" value [ebx] modify exact [];
extern int query_dpmi_buffer(unsigned long);
#pragma aux query_dpmi_buffer parm caller [] modify exact [eax];
extern unsigned long map_dpmi_buffer(unsigned long);
#pragma aux map_dpmi_buffer parm caller [] modify exact [eax];
extern unsigned short dpmi_buffer_low_address;
extern unsigned long dpmi_buffer_address;

extern AudioFarBuffer *current_audio_buffer(void);
#pragma aux current_audio_buffer = "" value [eax] modify exact [];
extern unsigned long *current_auxiliary_output(void);
#pragma aux current_auxiliary_output = "" value [edx] modify exact [];
/* EAX, EDX and EBX carry the output pointers. The register accessors keep
 * their frame slots in the order used by the original ABI. */
int allocate_dpmi_audio_buffer(void);
#pragma aux allocate_dpmi_audio_buffer modify exact [eax ebx edx gs];
int allocate_dpmi_audio_buffer(void)
{
    unsigned long exchange_handle;
    /* Preserve the original unused slot in the unoptimized frame. */
    volatile unsigned long reserved;
    unsigned long exchange_segment;
    unsigned long * volatile physical_output;
    unsigned long physical;
    int query_status;
    unsigned long mapped;
    unsigned long __far *exchange;
    unsigned long *auxiliary;
    AudioFarBuffer *buffer;

    buffer = current_audio_buffer();
    auxiliary = current_auxiliary_output();
    physical_output = current_physical_output();
    physical = 0;
    query_status = 0;
    *buffer = 0;
    *auxiliary = 0;
    *physical_output = 0;
    exchange_handle = 0;
    if (allocate_exchange_block(0x20, &exchange_segment, &exchange_handle) != 0)
        return 0;

    exchange = (unsigned long __far *)((__segment)exchange_segment :> (void *)0);
    *exchange = 0x1000;
    query_status = query_dpmi_buffer(exchange_handle);
    copy_audio_exchange(dpmi_audio_exchange, exchange, 0x10);
    release_exchange_block(exchange_segment, exchange_handle);
    if (query_status == 0) {
        dpmi_buffer_low_address &= 0xf000;
        mapped = map_dpmi_buffer(dpmi_buffer_address);
        physical = dpmi_buffer_address;
        *buffer = (void __far *)((__segment)0 :> (void *)mapped);
        *physical_output = physical;
        return 0;
    }
    return 5;
}

void release_dpmi_audio_buffer(unsigned, unsigned long);
#pragma aux release_dpmi_audio_buffer parm [eax] [edx] modify exact [eax ebx edx gs];
void release_dpmi_audio_buffer(unsigned selector, unsigned long physical)
{
    volatile unsigned long cookie = current_buffer_cookie();
    unsigned long exchange_segment, exchange_handle;
    void __far *exchange;
    allocate_exchange_block(0x20, &exchange_segment, &exchange_handle);
    exchange = (void __far *)((__segment)exchange_segment :> (void *)0);
    copy_audio_exchange(exchange, dpmi_audio_exchange, 0x10);
    free_dpmi_buffer(exchange_handle);
    release_exchange_block(exchange_segment, exchange_handle);
}
