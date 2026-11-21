typedef void ExitHook(void);
#pragma aux ExitHook modify exact [eax];
extern ExitHook *atexit_hook, *int23_exit_hook, *fpe_exit_hook;
extern void terminate_process(int status);
#pragma aux terminate_process "_exit_" modify exact [eax];

void exit_wrapper(int code);
#pragma aux exit_wrapper "exit_";
void exit_wrapper(int code)
{
    atexit_hook();
    int23_exit_hook();
    terminate_process(code);
}

/* Watcom emits the original tail jump for the non-returning startup exit. */
extern void startup_exit(int status);
#pragma aux startup_exit aborts modify exact [eax edx];
void exit_after_runtime_hooks(int code);
#pragma aux exit_after_runtime_hooks "_exit_";
void exit_after_runtime_hooks(int code)
{
    int23_exit_hook();
    fpe_exit_hook();
    startup_exit(code);
}
