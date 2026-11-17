/* Watcom aborts marks each tail transfer as ending the current C frame. */
extern void runtime_init(void);
#pragma aux runtime_init aborts modify exact [eax];
extern void runtime_fini(void);
#pragma aux runtime_fini aborts modify exact [eax];
extern void write_console_and_exit(const char *, int);
#pragma aux write_console_and_exit aborts modify exact [eax edx];

void runtime_init_thunk(void)
{
    runtime_init();
}

void runtime_fini_thunk(void)
{
    runtime_fini();
}

void console_exit_thunk(const char *message, int status)
{
    write_console_and_exit(message, status);
}

extern void close_streams_from_index(int);
#pragma aux close_streams_from_index modify exact [eax];
extern void free_recycled_streams(void);
#pragma aux free_recycled_streams aborts modify exact [eax];

void shutdown_all_streams(void)
{
    close_streams_from_index(0);
    free_recycled_streams();
}
