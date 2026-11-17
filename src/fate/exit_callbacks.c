typedef void ExitProcedure(void);
#pragma aux ExitProcedure modify exact [eax];
typedef ExitProcedure *ExitCallback;
extern int exit_callback_count;
extern ExitCallback exit_callbacks[];

void run_exit_callbacks(void)
{
    int count = exit_callback_count;
    unsigned offset;
    exit_callback_count = 32;
    offset = count * sizeof(ExitCallback);
    while (offset) {
        ExitCallback volatile callback;
        offset -= sizeof(ExitCallback);
        callback = *(ExitCallback *)((char *)exit_callbacks + offset);
        --count;
        callback();
    }
}
