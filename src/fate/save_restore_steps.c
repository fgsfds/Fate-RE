#include "saveio.h"

/* Bind this unsigned-word view to DATA offset 0x1a234. */
extern unsigned save_restore_words[512];

typedef char SaveRestoreWidths[
    sizeof(unsigned) == 4 && sizeof(void *) == 4 && sizeof(int) == 4 ? 1 : -1
];

/* Watcom's flat pointer-to-unsigned conversion yields the original address
 * word. The relocation shift, addition, and subtraction wrap at 32 bits. */
#define SECTOR_ADDRESS ((unsigned)(save_data_image + 0x27c3a0))

/* The table read or loop initializer provides index 511. Empty getters
 * read the physical index; setters leave their operand there. The signed
 * decrement yields -1..510, so the store at index+1 stays in bounds. */
extern int reader_index(void);
#pragma aux reader_index = "" value [edi] modify exact [];
extern void reader_set_index(int);
#pragma aux reader_set_index = "" parm [edi] modify exact [edi];
extern unsigned reader_base(unsigned);
#pragma aux reader_base = "" parm [ebx] value [ebx] modify exact [edx];
extern unsigned reader_shift(unsigned);
#pragma aux reader_shift = "" parm [ebx] value [ebx] modify exact [edi];
extern unsigned reader_word(unsigned);
#pragma aux reader_word = "" parm [edx] value [edx] modify exact [];
extern unsigned reader_loaded(unsigned, unsigned);
#pragma aux reader_loaded = "" parm [ebx] [edx] value [ebx] modify exact [];
extern unsigned reader_stepped_word(unsigned, int);
#pragma aux reader_stepped_word = "" parm [edx] [edi] value [edx] modify exact [];

extern RuntimeStream *restore_table_stream(RuntimeStream *);
#pragma aux restore_table_stream = "" parm [ecx] value [ecx] modify exact [edi];
extern int restore_table_index(int);
#pragma aux restore_table_index = "" parm [edi] value [edi] modify exact [];


int save_restore_read_loop(RuntimeStream *);
#pragma aux save_restore_read_loop parm [esi] value [edi] modify exact [eax ebx ecx edx edi];
int save_restore_read_loop(RuntimeStream *stream)
{
    unsigned count=save_io_count(1);
    unsigned size=save_io_size(sizeof(save_restore_words));
    unsigned char *buffer=save_io_buffer((unsigned char *)&save_restore_words);
    RuntimeStream *input=restore_table_stream(stream);
    int last=restore_table_index(sizeof(save_restore_words)/sizeof(save_restore_words[0])-1);
    (void)save_io_read(buffer,size,count,input);
    reader_set_index(last);
    goto check;
update:
    {
        unsigned base = reader_base(SECTOR_ADDRESS);
        unsigned word = reader_word(save_restore_words[reader_index()]);
        unsigned shift = reader_shift(reader_loaded(base, word) << 2);

        reader_set_index(reader_index() - 1);
        save_restore_words[reader_index() + 1] =
            reader_word(reader_stepped_word(word, reader_index()) + shift);
    }
check:
    if (reader_index() >= 0)
        goto update;
    return reader_index();
}

extern int writer_index(void);
#pragma aux writer_index = "" value [eax] modify exact [];
extern void writer_set_index(int);
#pragma aux writer_set_index = "" parm [eax] modify exact [eax];
extern unsigned writer_base(unsigned);
#pragma aux writer_base = "" parm [edx] value [edx] modify exact [ebx];
extern unsigned writer_shift(unsigned);
#pragma aux writer_shift = "" parm [edx] value [edx] modify exact [eax];
extern unsigned writer_word(unsigned);
#pragma aux writer_word = "" parm [ebx] value [ebx] modify exact [];
extern unsigned writer_loaded(unsigned, unsigned);
#pragma aux writer_loaded = "" parm [edx] [ebx] value [edx] modify exact [];
extern unsigned writer_stepped_word(unsigned, int);
#pragma aux writer_stepped_word = "" parm [ebx] [eax] value [ebx] modify exact [];
extern unsigned writer_stepped_base(unsigned, int);
#pragma aux writer_stepped_base = "" parm [edx] [eax] value [edx] modify exact [];
extern unsigned writer_result(unsigned);
#pragma aux writer_result = "" parm [edx] value [edx] modify exact [];

int save_restore_offset_loop(void);
#pragma aux save_restore_offset_loop parm [] value [eax] modify exact [eax ebx edx];
int save_restore_offset_loop(void)
{
    writer_set_index(511);
    goto check;
update:
    {
        unsigned base = writer_base(SECTOR_ADDRESS);
        unsigned word = writer_word(save_restore_words[writer_index()]);
        unsigned shift = writer_shift(writer_loaded(base, word) << 2);

        writer_set_index(writer_index() - 1);
        save_restore_words[writer_index() + 1] =
            writer_word(writer_stepped_word(word, writer_index()) - shift);
    }
check:
    if (writer_index() >= 0)
        goto update;
    return writer_index();
}

int save_restore_address_loop(void);
#pragma aux save_restore_address_loop parm [] value [eax] modify exact [eax ebx edx];
int save_restore_address_loop(void)
{
    writer_set_index(511);
    goto check;
update:
    {
        unsigned base = writer_base(SECTOR_ADDRESS);
        unsigned word = writer_word(save_restore_words[writer_index()]);
        unsigned shift = writer_shift(writer_loaded(base, word) << 2);

        writer_set_index(writer_index() - 1);
        save_restore_words[writer_index() + 1] =
            writer_result(writer_stepped_base(shift, writer_index()) + word);
    }
check:
    if (writer_index() >= 0)
        goto update;
    return writer_index();
}
