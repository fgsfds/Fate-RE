/* HMI detector state, mapped image, and parameter exchange. */

typedef struct {
    char reserved[0x5c];
    unsigned long ax, ch, cl, dx;
    char reserved6c[0xa8 - 0x6c];
    unsigned char flags;
    char reserveda9[0xb4 - 0xa9];
    short __far *windows_ids;
} DetectorSettings;

extern unsigned short detector_data_selector, detector_code_selector;
extern unsigned long detector_data_offset, detector_code_offset;
extern unsigned long detector_active_offset;
extern unsigned long detector_parameter_ax, detector_parameter_cl, detector_parameter_ch, detector_parameter_dx;
extern long seek_detector_file(long, long, int);
#pragma aux seek_detector_file "lseek_" parm [eax] [edx] [ebx] modify exact [eax ebx edx];
extern void read_driver_parameters(unsigned long, unsigned, unsigned long, unsigned);
#pragma aux read_driver_parameters parm caller [] modify exact [eax];
extern long detector_file;
extern unsigned long detector_values[];
extern unsigned char detector_flags;
extern unsigned long detector_linear_base, detector_memory_handle;

extern void windows_driver_interrupt(long);
#pragma aux windows_driver_interrupt parm caller [] modify exact [eax];
extern void windows_driver_interrupt_stop(long);
#pragma aux windows_driver_interrupt_stop parm caller [] modify exact [eax];
extern int driver_command_3(unsigned long, unsigned, unsigned long, unsigned long, unsigned long, unsigned long, unsigned);
#pragma aux driver_command_3 parm caller [] modify exact [eax];
extern void close_detector_file(long);
#pragma aux close_detector_file "close_" parm [eax] modify exact [eax];
extern int unlock_memory_region(unsigned long, unsigned);
#pragma aux unlock_memory_region parm caller [] modify exact [eax];
extern void release_driver_memory(unsigned long, unsigned, unsigned long);
#pragma aux release_driver_memory parm caller [] modify exact [eax];

extern char detector_path[], detector_filename[], detector_header[];
extern void __far *detector_data_pointer;
extern void __far *detector_code_pointer;

extern char *detector_strcpy(char *, const char *);
#pragma aux detector_strcpy "strcpy_" parm [eax] [edx] modify exact [eax edx];
extern char *detector_strcat(char *, const char *);
#pragma aux detector_strcat "strcat_" parm [eax] [edx] modify exact [eax edx];
extern int detector_open(const char *, int);
#pragma aux detector_open "open_" parm caller [] modify exact [eax];
extern int detector_read(int, void *, unsigned);
#pragma aux detector_read "read_" parm [eax] [edx] [ebx] modify exact [eax ebx edx];
extern void __far *allocate_driver_memory(unsigned, unsigned long *, unsigned long *);
#pragma aux allocate_driver_memory parm caller [] modify exact [eax edx];
extern void __far *get_driver_alias(unsigned long, unsigned);
#pragma aux get_driver_alias parm caller [] modify exact [eax edx];
extern int lock_memory_region(unsigned long, unsigned);
#pragma aux lock_memory_region parm caller [] modify exact [eax];

/* In these unoptimized routines, listing GS suppresses Watcom's unused GS save. */

void audio_detection_noop(void);
#pragma aux audio_detection_noop modify exact [eax gs];
void audio_detection_noop(void)
{
}

int open_audio_detector(const char *);
#pragma aux open_audio_detector parm [eax] modify exact [eax gs];
int open_audio_detector(const char *directory)
{
    /* Retain the original unused frame slots. */
    volatile long reserved_4, reserved_8;
    if (detector_flags & 1)
        return 3;
    if (directory) {
        detector_strcpy(detector_path, directory);
        detector_strcat(detector_path, detector_filename);
    } else {
        detector_strcpy(detector_path, detector_filename);
    }
    detector_file = detector_open(detector_path, 0x200);
    if (detector_file == -1)
        return 15;
    detector_read(detector_file, detector_header, 0x2c);
    detector_data_pointer = allocate_driver_memory(4096, &detector_memory_handle, &detector_linear_base);
    if (detector_data_pointer == 0)
        return 5;
    detector_code_pointer = get_driver_alias(detector_data_offset, detector_data_selector);
    if (lock_memory_region(detector_linear_base, 4096) != 0)
        return 5;
    seek_detector_file(detector_file, 0, 0);
    detector_flags |= 1;
    return 0;
}

int close_audio_detector(void);
#pragma aux close_audio_detector modify exact [eax gs];
int close_audio_detector(void)
{
    detector_flags &= ~1;
    close_detector_file(detector_file);
    if (unlock_memory_region(detector_linear_base, 4096) != 0)
        return 5;
    release_driver_memory(detector_data_offset, detector_data_selector, detector_memory_handle);
    release_driver_memory(detector_code_offset, detector_code_selector, detector_memory_handle);
    return 0;
}

int query_detected_audio_parameters(DetectorSettings *);
#pragma aux query_detected_audio_parameters parm [eax] modify exact [eax gs];
int query_detected_audio_parameters(DetectorSettings *settings)
{
    unsigned i;
    if (settings == 0)
        return 2;
    seek_detector_file(detector_file, detector_active_offset, 0);
    i = 0;
    while (settings->windows_ids[i] != (short)-1) {
        windows_driver_interrupt(settings->windows_ids[i]);
        ++i;
    }
    read_driver_parameters(detector_code_offset, detector_code_selector,
                           detector_data_offset, detector_data_selector);
    i = 0;
    while (settings->windows_ids[i] != (short)-1) {
        windows_driver_interrupt_stop(settings->windows_ids[i]);
        ++i;
    }
    settings->ax = detector_parameter_ax;
    settings->cl = detector_parameter_cl;
    settings->ch = detector_parameter_ch;
    settings->dx = detector_parameter_dx;
    if (!(settings->flags & 1)) {
        if (detector_parameter_ch > 1 && detector_parameter_ch < 16)
            return 0;
        return 17;
    }
    return 0;
}

int apply_detected_audio_parameters(DetectorSettings *);
#pragma aux apply_detected_audio_parameters parm [eax] modify exact [eax gs];
int apply_detected_audio_parameters(DetectorSettings *settings)
{
    unsigned long ax, ch, cl;
    /* Retain the original unused frame slots. */
    volatile long reserved_10, reserved_14;
    int status;
    if (settings == 0)
        return 2;
    ax = settings->ax;
    cl = settings->cl;
    ch = settings->ch;
    if (!(settings->flags & 1)) {
        if (ch < 2 || ch > 15)
            return 17;
    }
    windows_driver_interrupt(settings->cl);
    status = driver_command_3(detector_code_offset, detector_code_selector,
                              ax, ch, cl, detector_data_offset, detector_data_selector);
    windows_driver_interrupt_stop(settings->cl);
    return status;
}

void audio_detection_end(void);
#pragma aux audio_detection_end modify exact [eax gs];
void audio_detection_end(void)
{
}

void audio_detection_lookup_start(void);
#pragma aux audio_detection_lookup_start modify exact [eax gs];
void audio_detection_lookup_start(void)
{
}

unsigned long lookup_audio_detector_value(unsigned);
#pragma aux lookup_audio_detector_value parm [eax] modify exact [eax gs];
unsigned long lookup_audio_detector_value(unsigned index)
{
    return detector_values[index];
}

void audio_detection_lookup_end(void);
#pragma aux audio_detection_lookup_end modify exact [eax gs];
void audio_detection_lookup_end(void)
{
}
