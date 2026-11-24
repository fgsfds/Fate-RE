#include "saveio.h"

extern short numsectors, numwalls;

typedef char SaveTransferWidths[
    sizeof(unsigned) == 4 && sizeof(short) == 2 ? 1 : -1
];

extern RuntimeStream *transfer_stream(RuntimeStream *);
#pragma aux transfer_stream = "" parm [ecx] value [ecx] modify exact [];

#ifdef SAVE_DYNAMIC_WALLS

extern unsigned char *wall_buffer(unsigned char *);
#pragma aux wall_buffer = "" parm [eax] value [eax] modify exact [edx ecx];
extern unsigned wall_rows(unsigned);
#pragma aux wall_rows = "" parm [edx] value [edx] modify exact [ecx];
extern unsigned wall_rows_after_stream(unsigned, RuntimeStream *);
#pragma aux wall_rows_after_stream = "" parm [edx] [ecx] value [edx] modify exact [];

#define TRANSFER(transfer)                                              \
    unsigned count = save_io_count(1);                                  \
    unsigned char *buffer = wall_buffer(save_data_image + 0x2310a0);    \
    unsigned rows = wall_rows((unsigned)(int)numwalls);                 \
    RuntimeStream *input = transfer_stream(stream);                     \
    unsigned size = wall_rows_after_stream(rows, input) << 5;           \
    return transfer(buffer, size, count, input)

unsigned save_read_walls(RuntimeStream *);
#pragma aux save_read_walls parm [esi] value [ebx] modify exact [eax ebx ecx edx];
unsigned save_read_walls(RuntimeStream *stream)
{
    TRANSFER(save_io_read);
}

unsigned save_write_walls(RuntimeStream *);
#pragma aux save_write_walls parm [edi] value [ebx] modify exact [eax ebx ecx edx];
unsigned save_write_walls(RuntimeStream *stream)
{
    TRANSFER(save_io_write);
}

#else

extern unsigned char *sector_buffer(unsigned char *);
#pragma aux sector_buffer = "" parm [eax] value [eax] modify exact [];
extern unsigned sector_rows(unsigned);
#pragma aux sector_rows = "" parm [edx] value [edx] modify exact [eax ebx ecx];
extern unsigned sector_copy(unsigned);
#pragma aux sector_copy = "" parm [eax] value [eax] modify exact [ebx ecx];
extern unsigned sector_count(unsigned);
#pragma aux sector_count = "" parm [ebx] value [ebx] modify exact [];
extern unsigned sector_before_scale(unsigned, unsigned);
#pragma aux sector_before_scale = "" parm [eax] [ebx] value [eax] modify exact [];
extern unsigned sector_four_rows(unsigned);
#pragma aux sector_four_rows = "" parm [eax] value [eax] modify exact [ecx];
extern unsigned sector_rows_after_stream(unsigned, RuntimeStream *);
#pragma aux sector_rows_after_stream = "" parm [eax] [ecx] value [eax] modify exact [];
extern unsigned sector_five_rows(unsigned);
#pragma aux sector_five_rows = "" parm [edx] value [edx] modify exact [eax];
extern unsigned sector_rows_after_buffer(unsigned, unsigned char *);
#pragma aux sector_rows_after_buffer = "" parm [edx] [eax] value [edx] modify exact [];

#define TRANSFER(transfer)                                              \
    unsigned rows = sector_rows((unsigned)(int)numsectors);             \
    unsigned copy = sector_copy(rows);                                  \
    unsigned count = sector_count(1);                                   \
    unsigned four = sector_four_rows(sector_before_scale(copy, count) << 2); \
    RuntimeStream *input = transfer_stream(stream);                     \
    unsigned five = sector_five_rows(rows + sector_rows_after_stream(four, input)); \
    unsigned char *buffer = sector_buffer(save_data_image + 0x27c3a0); \
    unsigned size = sector_rows_after_buffer(five, buffer) << 3;        \
    return transfer(buffer, size, count, input)

unsigned save_read_sectors(RuntimeStream *);
#pragma aux save_read_sectors parm [esi] value [ebx] modify exact [eax ebx ecx edx];
unsigned save_read_sectors(RuntimeStream *stream)
{
    TRANSFER(save_io_read);
}

unsigned save_write_sectors(RuntimeStream *);
#pragma aux save_write_sectors parm [edi] value [ebx] modify exact [eax ebx ecx edx];
unsigned save_write_sectors(RuntimeStream *stream)
{
    TRANSFER(save_io_write);
}

#endif
