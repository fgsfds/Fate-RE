/* Scan the HMI detector file, load driver command tables and probe callbacks. */
typedef struct {
    unsigned char reserved[0x64];
    unsigned long driver_record;
    unsigned short tail;
} DriverCommands;

typedef struct {
    char reserved[0x5c];
    unsigned long driver_status;
    char reserved60[0xc];
    DriverCommands commands;
    char reservedd6[0x104 - 0xd6];
    unsigned long driver_record;
} DetectorCommands;

extern long detector_file;
extern unsigned long detector_entry_index, detector_entry_count, detector_entry_size, detector_entry_id;
extern unsigned char detector_entry_flags;
extern unsigned char detector_header[], detector_entry_header[];
extern void __far *detector_data_pointer;
extern unsigned long detector_data_offset, detector_code_offset;
extern unsigned short detector_data_selector, detector_code_selector;
extern DriverCommands *detector_active_commands;
extern long detector_active_offset;

extern long seek_detector_file(long, long, int);
#pragma aux seek_detector_file "lseek_" parm [eax] [edx] [ebx] modify exact [eax ebx edx];
extern int detector_read(int, void *, unsigned);
#pragma aux detector_read "read_" parm [eax] [edx] [ebx] modify exact [eax ebx edx];
extern int read_driver_image(int, void __far *, unsigned, unsigned *);
#pragma aux read_driver_image parm routine [eax] [ebx ecx] [edx] [] modify exact [eax ebx ecx edx];
extern void read_driver_command_table(unsigned long, unsigned, unsigned long, unsigned, void *);
#pragma aux read_driver_command_table parm caller [] modify exact [eax];

/* GS is listed to suppress Watcom's unused save in the unoptimized frame. */
int load_detector_command_table(unsigned, DetectorCommands *);
#pragma aux load_detector_command_table parm [eax] [edx] modify exact [eax edx gs];
int load_detector_command_table(unsigned id, DetectorCommands *output)
{
    unsigned long bytes;
    int found = 0;
    long entry_offset;
    unsigned image_state;

    if (!output)
        return 2;
    if (id < 0xe000 || id > 0xe200)
        return 6;
    detector_entry_index = 0;
    seek_detector_file(detector_file, 0, 0);
    detector_read(detector_file, detector_header, 0x2c);
    while (detector_entry_index <= detector_entry_count && !found) {
        entry_offset = seek_detector_file(detector_file, 0, 1);
        detector_read(detector_file, detector_entry_header, 0x30);
        bytes = detector_entry_size;
        if (detector_entry_id == id && (detector_entry_flags & 0x80)) {
            found = 1;
            read_driver_image(detector_file, detector_data_pointer, bytes, &image_state);
        } else {
            seek_detector_file(detector_file, bytes, 1);
        }
        ++detector_entry_index;
    }
    if (found) {
        read_driver_command_table(detector_code_offset, detector_code_selector,
                                  detector_data_offset, detector_data_selector, &output->commands);
        detector_active_commands = &output->commands;
        detector_active_offset = entry_offset;
        return 0;
    }
    return 7;
}

extern DriverCommands detector_commands;
extern unsigned char detector_command_flags;

extern void get_driver_tables(unsigned long, unsigned, unsigned long, unsigned);
#pragma aux get_driver_tables parm caller [] modify exact [eax];
extern char *copy_driver_record(unsigned);
#pragma aux copy_driver_record parm caller [] modify exact [eax];
extern char *get_detector_callback(const char *);
#pragma aux get_detector_callback "getenv_" parm [eax] modify exact [eax];
extern void set_driver_callback(unsigned, char *);
#pragma aux set_driver_callback parm caller [] modify exact [eax];
extern unsigned long driver_command_0(unsigned long, unsigned, unsigned long, unsigned);
#pragma aux driver_command_0 parm caller [] modify exact [eax];

#define LOAD_COMMANDS(out) \
    read_driver_command_table(detector_code_offset, detector_code_selector, \
                              detector_data_offset, detector_data_selector, out)

#define INSTALL_CALLBACKS(callback_index, callback) \
    if (detector_command_flags & 1) { \
        get_driver_tables(detector_code_offset, detector_code_selector, \
                          detector_data_offset, detector_data_selector); \
        callback_index = 0; \
        while (copy_driver_record(callback_index)) { \
            callback = get_detector_callback(copy_driver_record(callback_index)); \
            set_driver_callback(callback_index, callback); \
            ++callback_index; \
        } \
    }

#define SAVE_WORKING_INTERFACE(out, status) \
    LOAD_COMMANDS(&(out)->commands); \
    detector_active_commands = &(out)->commands; \
    (out)->driver_status = status; \
    (out)->driver_record = (out)->commands.driver_record

int find_working_audio_driver(DetectorCommands *);
#pragma aux find_working_audio_driver parm [eax] modify exact [eax gs];
int find_working_audio_driver(DetectorCommands *output)
{
    unsigned long bytes;
    int found = 0;
    unsigned long driver_status = 0;
    long entry_offset;
    unsigned image_state;
    unsigned callback_index = 0;
    char *callback = 0;

    if (!output)
        return 2;
    driver_status = 0;
    detector_entry_index = 0;
    seek_detector_file(detector_file, 0, 0);
    detector_read(detector_file, detector_header, 0x2c);

    while (detector_entry_index <= detector_entry_count && !found) {
        entry_offset = seek_detector_file(detector_file, 0, 1);
        detector_read(detector_file, detector_entry_header, 0x30);
        bytes = detector_entry_size;
        if (detector_entry_flags & 0x80) {
            read_driver_image(detector_file, detector_data_pointer, bytes, &image_state);
            LOAD_COMMANDS(&detector_commands);
            INSTALL_CALLBACKS(callback_index, callback)
            driver_status = driver_command_0(detector_code_offset, detector_code_selector,
                                            detector_data_offset, detector_data_selector);
            if (driver_status) {
                detector_active_offset = entry_offset;
                SAVE_WORKING_INTERFACE(output, driver_status);
                return 0;
            }
        } else {
            seek_detector_file(detector_file, bytes, 1);
        }
        ++detector_entry_index;
    }
    return 7;
}

int find_next_working_audio_driver(DetectorCommands *);
#pragma aux find_next_working_audio_driver parm [eax] modify exact [eax gs];
int find_next_working_audio_driver(DetectorCommands *output)
{
    unsigned long bytes;
    int found = 0;
    unsigned long driver_status = 0;
    long entry_offset;
    unsigned image_state;
    unsigned callback_index = 0;
    char *callback = 0;

    if (!output)
        return 2;
    driver_status = 0;

    while (detector_entry_index <= detector_entry_count && !found) {
        entry_offset = seek_detector_file(detector_file, 0, 1);
        detector_read(detector_file, detector_entry_header, 0x30);
        bytes = detector_entry_size;
        if (detector_entry_flags & 0x80) {
            read_driver_image(detector_file, detector_data_pointer, bytes, &image_state);
            LOAD_COMMANDS(&detector_commands);
            INSTALL_CALLBACKS(callback_index, callback)
            driver_status = driver_command_0(detector_code_offset, detector_code_selector,
                                            detector_data_offset, detector_data_selector);
            if (driver_status) {
                detector_active_offset = entry_offset;
                SAVE_WORKING_INTERFACE(output, driver_status);
                return 0;
            }
        } else {
            seek_detector_file(detector_file, bytes, 1);
        }
        ++detector_entry_index;
    }
    return 7;
}

int detect_audio_driver(unsigned, DetectorCommands *);
#pragma aux detect_audio_driver parm [eax] [edx] modify exact [eax edx gs];
int detect_audio_driver(unsigned id, DetectorCommands *output)
{
    int found = 0;
    unsigned long driver_status = 0;
    long entry_offset;
    unsigned image_state;
    unsigned long bytes;
    unsigned callback_index = 0;
    char *callback = 0;

    if (!output)
        return 2;
    if (id < 0xe000 || id > 0xe200)
        return 6;
    detector_entry_index = 0;
    seek_detector_file(detector_file, 0, 0);
    detector_read(detector_file, detector_header, 0x2c);
    while (detector_entry_index <= detector_entry_count && !found) {
        entry_offset = seek_detector_file(detector_file, 0, 1);
        detector_read(detector_file, detector_entry_header, 0x30);
        bytes = detector_entry_size;
        if (detector_entry_id == id && (detector_entry_flags & 0x80)) {
            found = 1;
            read_driver_image(detector_file, detector_data_pointer, bytes, &image_state);
        } else {
            seek_detector_file(detector_file, bytes, 1);
        }
        ++detector_entry_index;
    }
    if (found) {
        LOAD_COMMANDS(&detector_commands);
        INSTALL_CALLBACKS(callback_index, callback)
        driver_status = driver_command_0(detector_code_offset, detector_code_selector,
                                        detector_data_offset, detector_data_selector);
        if (driver_status) {
            SAVE_WORKING_INTERFACE(output, driver_status);
            detector_active_offset = entry_offset;
            return 0;
        }
        return 8;
    }
    return 7;
}
