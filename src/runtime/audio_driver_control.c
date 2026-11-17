/* Initialize the digital audio subsystem and query mapped driver interfaces. */

typedef struct {
    char reserved[0xd8];
    unsigned long data_offset;
    unsigned short data_selector;
    unsigned short reservedde;
    unsigned long code_offset;
    unsigned short code_selector;
} AudioDriverInterface;

extern AudioDriverInterface *audio_driver_slots[];

extern unsigned char audio_system_flags;
extern char audio_driver_path[];
extern int initialize_audio_backend(void);
#pragma aux initialize_audio_backend modify exact [eax];
extern int shutdown_audio_backend(void);
#pragma aux shutdown_audio_backend modify exact [eax];

extern char *detector_strcpy(char *, const char *);
#pragma aux detector_strcpy "strcpy_" parm [eax] [edx] modify exact [eax edx];

extern void copy_far_driver_interface(unsigned long, unsigned, unsigned long, unsigned, void *);
#pragma aux copy_far_driver_interface parm caller [] modify exact [eax];

/* In these unoptimized routines, listing GS suppresses Watcom's unused GS save. */

void audio_init_noop(void);
#pragma aux audio_init_noop modify exact [eax gs];
void audio_init_noop(void)
{
}

int audio_system_init(const char *, unsigned);
#pragma aux audio_system_init parm [eax] [edx] modify exact [eax edx gs];
int audio_system_init(const char *path, unsigned unused)
{
    int status = initialize_audio_backend();
    if (status != 0)
        return status;
    audio_system_flags |= 1;
    if (path)
        detector_strcpy(audio_driver_path, path);
    else
        *audio_driver_path = 0;
    return 0;
}

int audio_system_shutdown(void);
#pragma aux audio_system_shutdown modify exact [eax gs];
int audio_system_shutdown(void)
{
    int status = shutdown_audio_backend();
    if (status != 0)
        return 0;
    audio_system_flags &= ~1;
    return 0;
}

void audio_noop_61816(void);
#pragma aux audio_noop_61816 modify exact [eax gs];
void audio_noop_61816(void)
{
}

void audio_noop_6182b(void);
#pragma aux audio_noop_6182b modify exact [eax gs];
void audio_noop_6182b(void)
{
}

void audio_empty_range_stub_657ed(void);
#pragma aux audio_empty_range_stub_657ed modify exact [eax gs];
void audio_empty_range_stub_657ed(void)
{
}

void audio_empty_range_stub_65ee6(void);
#pragma aux audio_empty_range_stub_65ee6 modify exact [eax gs];
void audio_empty_range_stub_65ee6(void)
{
}

void audio_empty_range_stub_65efb(void);
#pragma aux audio_empty_range_stub_65efb modify exact [eax gs];
void audio_empty_range_stub_65efb(void)
{
}

void audio_empty_range_stub_661b8(void);
#pragma aux audio_empty_range_stub_661b8 modify exact [eax gs];
void audio_empty_range_stub_661b8(void)
{
}

void audio_empty_range_stub_661cd(void);
#pragma aux audio_empty_range_stub_661cd modify exact [eax gs];
void audio_empty_range_stub_661cd(void)
{
}

void audio_empty_range_stub_662cc(void);
#pragma aux audio_empty_range_stub_662cc modify exact [eax gs];
void audio_empty_range_stub_662cc(void)
{
}

void audio_empty_range_stub_662e1(void);
#pragma aux audio_empty_range_stub_662e1 modify exact [eax gs];
void audio_empty_range_stub_662e1(void)
{
}

int query_driver_interface(unsigned, void *);
#pragma aux query_driver_interface parm [eax] [edx] modify exact [eax edx gs];
int query_driver_interface(unsigned slot, void *output)
{
    AudioDriverInterface *driver = audio_driver_slots[slot];
    if (driver == 0)
        return 1;
    if (output != 0) {
        copy_far_driver_interface(driver->code_offset, driver->code_selector,
                                  driver->data_offset, driver->data_selector, output);
    } else {
        return 2;
    }
    return 0;
}

void audio_dispatch_noop(void);
#pragma aux audio_dispatch_noop modify exact [eax gs];
void audio_dispatch_noop(void)
{
}
