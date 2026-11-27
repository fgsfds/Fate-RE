typedef void ExitProcedure(void);
#pragma aux ExitProcedure modify exact [eax];
typedef ExitProcedure *ExitCallback;
extern int exit_callback_count;
extern ExitCallback exit_callbacks[];

extern void run_exit_callbacks(void);
extern ExitCallback atexit_hook;
/* Keep the Watcom call and count registers used by the original routine. */
extern ExitCallback keep_exit_callback(ExitCallback);
#pragma aux keep_exit_callback = "" parm [ebx] value [ebx] modify exact [];
extern ExitCallback keep_exit_dispatcher(ExitCallback);
#pragma aux keep_exit_dispatcher = "" parm [edx] value [edx] modify exact [];
extern int keep_exit_count(int);
#pragma aux keep_exit_count = "" parm [ecx] value [ecx] modify exact [];
extern int keep_exit_status(int);
#pragma aux keep_exit_status = "" parm [eax] value [eax] modify exact [];

extern int keep_next_exit_count(int);
#pragma aux keep_next_exit_count = "" parm [edx] value [edx] modify exact [];

int register_exit_callback(ExitCallback callback)
{
    ExitCallback function = callback;
    ExitCallback dispatcher = keep_exit_dispatcher(run_exit_callbacks);
    int count = keep_exit_count(exit_callback_count);
    atexit_hook = dispatcher;
    if (count < 32) {
        int status = keep_exit_status(count);
        int next = keep_next_exit_count(count + 1);
        /* Publish the callback before incrementing the visible count. */
        ((ExitCallback volatile *)exit_callbacks)[count] = keep_exit_callback(function);
        exit_callback_count = next;
        /* The two copies of the prior count produce the original zero status. */
        return status ^ count;
    }
    return -1;
}
