#include "dosio.h"

extern void report_game_error(const char *);
#pragma aux report_game_error modify exact [eax];
extern long dispatch_ticks(long);
#pragma aux dispatch_ticks modify exact [eax];
extern const char text_seek_error[], text_read_error[];
extern int text_archive_open, text_archive_handle, text_archive_index, text_archive_records;
extern unsigned char text_archive_record[], text_archive_message[];
extern unsigned char *active_text_message;
extern volatile long totalclock;
extern long text_message_timeout;

int select_item(int item)
{
    int status = 1;
    if (!text_archive_open)
        status = -1;
    if (item < 0)
        status = -1;
    if (item > text_archive_records)
        status = -1;
    if (status != -1 && item != text_archive_index) {
        text_archive_index = item;
        if (lseek(text_archive_handle, 46L * item, 0) == -1)
            report_game_error(text_seek_error);
        if (read(text_archive_handle, text_archive_record, 46) != 46)
            report_game_error(text_read_error);
        status = item;
    }
    if (status != -1) {
        active_text_message = text_archive_message;
        text_message_timeout = dispatch_ticks(3) + totalclock;
    }
    return status;
}

extern const char text_archive_filename[];
extern int open_archive_file(const char *, int, ...);
#pragma aux open_archive_file "open_" parm caller [] modify exact [eax];

int open_text_archive(void)
{
    int bytes, record_size = 46;
    text_archive_open = 0;
    text_archive_handle = open_archive_file(text_archive_filename, 0x200);
    if (text_archive_handle == -1)
        return -1;
    text_archive_open = 1;
    text_archive_records = 0;
    text_archive_index = -1;
    bytes = record_size;
    while (bytes == record_size) {
        bytes = read(text_archive_handle, text_archive_record, record_size);
        if (bytes == record_size)
            ++text_archive_records;
    }
    return 1;
}
