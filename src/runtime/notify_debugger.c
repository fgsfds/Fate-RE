extern const unsigned char debugger_present;

/* WVIDEO detects this trap by the signature immediately following the jump. */
extern void signal_wvideo(const char *, unsigned);
#pragma aux signal_wvideo = "push edx" "push eax" "int 3" "jmp short skip_signature" 0x57 0x56 0x49 0x44 0x45 0x4f "skip_signature:" parm [eax] [edx] modify exact [];
extern int status_in_eax(int);
#pragma aux status_in_eax = parm [eax] value [eax] modify exact [];
/* Discard the two arguments after setting the debugger result. */
extern void release_debugger_arguments(int);
#pragma aux release_debugger_arguments = "add esp,8" parm [eax] modify exact [];

int notify_debugger(const char *message, unsigned selector);
#pragma aux notify_debugger parm [eax] [edx] modify exact [eax edx];
int notify_debugger(const char *message, unsigned selector)
{
    int handled;

    if (debugger_present) {
        signal_wvideo(message, selector & 0xffff);
        handled = status_in_eax(1);
        release_debugger_arguments(handled);
        return handled;
    }
    return 0;
}
