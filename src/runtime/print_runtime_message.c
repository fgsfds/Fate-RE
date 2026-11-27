typedef char *ArgumentList;
extern int write_stream_format(void *, const char *, ArgumentList *);
#pragma aux write_stream_format modify exact [eax ebx edx];
extern char stdout_stream[];
int print_runtime_message(const char *format, ...);
#pragma aux print_runtime_message parm caller [] modify exact [eax];

/* Keep the Watcom variadic argument pointer in EBX while preparing the stream call. */
extern ArgumentList keep_arglist(ArgumentList);
#pragma aux keep_arglist = "" parm [ebx] value [ebx] modify exact [];
int print_runtime_message(const char *format, ...)
{
    ArgumentList args = keep_arglist((ArgumentList)(&format + 1));
    return write_stream_format(stdout_stream, format, &args);
}
