typedef struct RuntimeStream RuntimeStream;
typedef struct SaveStream SaveStream;
extern int read_finished_crushers(SaveStream *);
#pragma aux read_finished_crushers "read_crusher_state_" parm [eax] value [eax] modify exact [eax];
extern int write_finished_crushers(SaveStream *);
#pragma aux write_finished_crushers "write_crusher_state_" parm [eax] value [eax] modify exact [eax];
extern int close_finished_stream(RuntimeStream *);
#pragma aux close_finished_stream "fclose_" parm [eax] value [eax] modify exact [eax];

int finish_read_save_stream(RuntimeStream *);
#pragma aux finish_read_save_stream parm [esi] value [ebx] modify exact [eax ebx];
int finish_read_save_stream(RuntimeStream *stream)
{
    read_finished_crushers((SaveStream *)stream);
    return close_finished_stream(stream);
}

int finish_write_save_stream(RuntimeStream *);
#pragma aux finish_write_save_stream parm [esi] value [ebx] modify exact [eax ebx];
int finish_write_save_stream(RuntimeStream *stream)
{
    write_finished_crushers((SaveStream *)stream);
    return close_finished_stream(stream);
}
